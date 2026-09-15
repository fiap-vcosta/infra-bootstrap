# infra-bootstrap

Terraform da camada **persistente** da infraestrutura GCP do Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)). São os recursos gratuitos (ou de centavos) que os outros stacks consomem e que **não** entram no ciclo de subir/derrubar a demo.

## Escopo

- Habilitação das APIs usadas pelos stacks (`disable_on_destroy = false`)
- Bucket GCS do backend de state (`vcosta-fiap-tech-challenge-tfstate`)
- Workload Identity Federation: pool/provider `github` + service account `github-actions` e suas roles
- VPC `tech-challenge-vpc`, subnet regional com ranges secundários do cluster e range/peering do Private Service Access
- Artifact Registry Docker `tech-challenge` (imagem sobrevive entre demos; cleanup: DELETE versões com mais de 1 dia + KEEP as 2 mais recentes por pacote — `KEEP` sozinho não apaga nada)
- Service account de runtime da API (`tech-challenge-api`) com `roles/cloudsql.client`
- Cloud DNS managed zone pública `tech-challenge` para `vcosta-fiap.online` (records da demo ficam no `infra-k8s`)
- Outputs rígidos: `network_id`, `subnet_id`, `pods_range_name`, `services_range_name`, `api_runtime_service_account_email`, `dns_managed_zone_name`, `dns_name`, `dns_name_servers`
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`

Root module: [`terraform/`](terraform/). Cloud SQL fica em [`infra-db`](https://github.com/fiap-vcosta/infra-db); cluster e manifests em [`infra-k8s`](https://github.com/fiap-vcosta/infra-k8s).

## Plano de endereçamento

| Range | CIDR | Uso |
|-------|------|-----|
| Primário da subnet | `10.10.0.0/24` | Nós do cluster |
| Secundário `pods` | `10.60.0.0/16` | Pods do cluster |
| Secundário `services` | `10.61.0.0/20` | Services do cluster |
| Private Service Access | `10.100.0.0/16` | IP privado do Cloud SQL |

O range do PSA é **fixo** de propósito: com alocação automática a GCP escolhe um `/16` RFC1918 qualquer, que pode colidir com os ranges do cluster.

## State

| Item | Valor |
|------|--------|
| Bucket | `vcosta-fiap-tech-challenge-tfstate` |
| Prefix deste repo | `infra-bootstrap` |
| Outros prefixes | `infra-db`, `infra-k8s` |

O bucket é gerenciado por este stack e guarda o próprio state. Como este stack **não** tem rotina de destroy, não há risco de ele apagar o state embaixo de si.

## Apply é local, nunca por CI

Este stack concede IAM. Se a service account de CI o aplicasse, ela precisaria de IAM admin sobre si mesma e poderia se auto-promover. Por isso:

- **CI:** só `fmt` + `validate` ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) — não fala com a GCP
- **Apply/destroy:** local, com ADC de um humano com owner

```bash
gcloud auth application-default login
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Todo `plan` deste stack merece leitura linha a linha: os recursos aqui sustentam o OIDC do CI e o acesso ao state, então `destroy` ou `replace` inesperado significa parar e corrigir o código antes de aplicar.

## Quem pode assumir a service account de CI

O binding de `roles/iam.workloadIdentityUser` é **por repositório** (`attribute.repository`), não por org: um repo novo na org não ganha acesso à GCP só por existir. Para habilitar um repo, incluir o nome em `ci_repositories` ([`terraform/variables.tf`](terraform/variables.tf)) e aplicar localmente.

Repos habilitados: `api`, `auth`, `infra-db`, `infra-k8s`. Este repo não entra na lista — o CI dele não fala com a GCP.

## Roles da service account de CI

Least-privilege, sem `roles/editor`, definidas em [`terraform/iam.tf`](terraform/iam.tf) / [`terraform/variables.tf`](terraform/variables.tf):

- `roles/viewer`
- `roles/cloudsql.admin`
- `roles/compute.networkAdmin`
- `roles/container.admin`
- `roles/artifactregistry.writer`
- `roles/secretmanager.admin`
- `roles/cloudfunctions.developer` — deploy da Function `auth` (2nd gen)
- `roles/run.admin` — serviço Cloud Run por baixo da Function gen2
- `roles/apigateway.admin` / `roles/servicemanagement.admin` — API Gateway no `infra-k8s`
- `roles/dns.admin` — records DNS da demo no `infra-k8s`
- `roles/storage.objectAdmin` no bucket de state
- `roles/iam.serviceAccountUser` na service account padrão de compute (cluster e runtime padrão da Function)
- Role customizada `serviceAccountIamPolicyWriter` (só `get`/`setIamPolicy`) na service account de runtime da API, para o `infra-k8s` criar o binding de Workload Identity
- Role customizada `gatewayEntryLb` (NEG serverless + `sslCertificates`) para o HTTPS LB da entrada no apex → API Gateway (`infra-k8s`)

APIs extras habilitadas para Function `auth`, API Gateway e DNS: `cloudfunctions`, `run`, `cloudbuild`, `apigateway`, `servicecontrol`, `servicemanagement`, `dns`.

`roles/servicenetworking.networksAdmin` sai da lista: o peering do PSA passou a ser aplicado localmente. Se o binding ainda existir de antes, remova-o depois do primeiro apply:

```bash
gcloud projects remove-iam-policy-binding vcosta-fiap-tech-challenge \
  --member="serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com" \
  --role="roles/servicenetworking.networksAdmin"
```

## Contrato com os outros repos

Alterar qualquer um destes valores quebra os stacks vizinhos:

| Valor | Consumido por |
|-------|---------------|
| Outputs de rede (`network_id`, `subnet_id`, ranges secundários) | `infra-db` (IP privado do SQL) e `infra-k8s` (cluster), via `terraform_remote_state` |
| Output `api_runtime_service_account_email` | `infra-k8s`: anotação da service account Kubernetes e binding de Workload Identity |
| Outputs DNS (`dns_managed_zone_name`, `dns_name`, `dns_name_servers`) | `infra-k8s` (records `api`/`auth`); nameservers vão uma vez no registrador (Hostinger) |
| `us-central1-docker.pkg.dev/vcosta-fiap-tech-challenge/tech-challenge` | workflows de build/push e deploy da `api` (org var `GCP_AR_REPOSITORY`) |

## Domínio e nameservers

A zona Cloud DNS é **persistente** (~US$ 0,20/mês). Depois do `apply` local:

```bash
cd terraform
terraform output -json dns_name_servers
```

No registrador (Hostinger), troque os nameservers do domínio `vcosta-fiap.online` pelos quatro NS Google dessa saída. Records `api` / `auth` **não** moram aqui — o `infra-k8s` os cria e apaga a cada ciclo de demo.

O caminho da imagem não é output porque quem o consome não roda Terraform: o workflow da `api` o monta a partir de literais e org vars.

## Workload Identity da API mora no `infra-k8s`

O pool `vcosta-fiap-tech-challenge.svc.id.goog` só existe **enquanto houver um cluster com Workload Identity no projeto**. Conceder `roles/iam.workloadIdentityUser` à KSA da API daqui falharia com `Identity Pool does not exist` sempre que a demo estivesse derrubada.

Por isso este stack só cria a service account de runtime e sua `roles/cloudsql.client`; o binding KSA → service account é criado pelo `infra-k8s`, depois do cluster, e morre junto com ele.

## Decisões (ADRs)

Ver [`docs/README.md`](docs/README.md). Em especial: [GCP, região e custo](docs/adrs/001-gcp-regiao-custo.md) e [camada persistente](docs/adrs/002-camada-persistente.md).

## Repos da org

| Repo | Papel | Diagrama / doc-chave |
|------|--------|----------------------|
| [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap) | Rede, WIF, AR, zona DNS | Persistente (este repo) |
| [`infra-db`](https://github.com/fiap-vcosta/infra-db) | Cloud SQL | ADRs de banco |
| [`infra-k8s`](https://github.com/fiap-vcosta/infra-k8s) | GKE + Gateway + Cloud Run auth | [Componentes](https://github.com/fiap-vcosta/infra-k8s#componentes-nuvem) |
| [`api`](https://github.com/fiap-vcosta/api) | App + manifests + Requestly | [ER](https://github.com/fiap-vcosta/api/blob/main/docs/08_modelo-de-dados.md) |
| [`auth`](https://github.com/fiap-vcosta/auth) | Imagem documento → JWT | Sequência no README |

## Agentes

Ver [AGENTS.md](AGENTS.md).
