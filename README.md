# infra-bootstrap

Terraform da camada **persistente** da infraestrutura GCP do Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)). São os recursos gratuitos (ou de centavos) que os outros stacks consomem e que **não** entram no ciclo de subir/derrubar a demo.

## Escopo

- Habilitação das APIs usadas pelos stacks (`disable_on_destroy = false`)
- Bucket GCS do backend de state (`vcosta-fiap-tech-challenge-tfstate`)
- Workload Identity Federation: pool/provider `github` + service account `github-actions` e suas roles
- VPC `tech-challenge-vpc`, subnet regional com ranges secundários do cluster e range/peering do Private Service Access
- Artifact Registry Docker `tech-challenge` (imagem sobrevive entre demos; cleanup: DELETE versões com mais de 1 dia + KEEP as 2 mais recentes por pacote — `KEEP` sozinho não apaga nada)
- Cinco service accounts de runtime, account id igual ao repositório. `roles/cloudsql.client` em `ordem-servico-service`, `estoque-service` e `administrativo-service`. `roles/datastore.user` no projeto em `orcamento-service` e `autenticacao-service` (o database nomeado nasce no Terraform de cada serviço, então o grant ainda não é por database)
- Cloud DNS managed zone pública `tech-challenge` para `vcosta-fiap.online` (records da demo ficam no `infra-k8s`)
- Outputs rígidos: `network_id`, `subnet_id`, `pods_range_name`, `services_range_name`, `runtime_service_account_emails`, `dns_managed_zone_name`, `dns_name`, `dns_name_servers`
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

Repos habilitados: `administrativo-service`, `autenticacao-service`, `e2e`, `estoque-service`, `infra-db`, `infra-events`, `infra-k8s`, `orcamento-service`, `ordem-servico-service`. Este repo não entra na lista — o CI dele não fala com a GCP. `building-blocks` também não: o pacote não fala com a GCP.

## Roles da service account de CI

Least-privilege, sem `roles/editor`, definidas em [`terraform/iam.tf`](terraform/iam.tf) / [`terraform/variables.tf`](terraform/variables.tf):

- `roles/viewer`
- `roles/cloudsql.admin`
- `roles/compute.networkAdmin`
- `roles/container.admin`
- `roles/artifactregistry.writer`
- `roles/secretmanager.admin`
- `roles/apigateway.admin` / `roles/servicemanagement.admin` — API Gateway no `infra-k8s`
- `roles/dns.admin` — records DNS da demo no `infra-k8s`
- `roles/storage.objectAdmin` no bucket de state
- `roles/iam.serviceAccountUser` na service account padrão de compute (nós do cluster)
- Role customizada `serviceAccountIamPolicyWriter` (só `get`/`setIamPolicy`) em cada service account de runtime, para o `infra-k8s` criar o binding de Workload Identity
- Role customizada `gatewayEntryLb` (NEG serverless + `sslCertificates`) para o HTTPS LB da entrada no apex → API Gateway (`infra-k8s`)
- Role customizada `ciPubSubAdmin`: tópicos e subscriptions (`get`/`list`/`create`/`delete`/`update`, `getIamPolicy`/`setIamPolicy`, `topics.attachSubscription`). Sem `publish` e sem `consume`
- Role customizada `ciFirestoreDatabaseAdmin`: databases (`create`/`delete`/`get`/`getMetadata`/`list`/`update`), índices, locations e operations. Sem `datastore.entities.*`

APIs extras habilitadas para API Gateway e DNS: `apigateway`, `servicecontrol`, `servicemanagement`, `dns`. Mensageria e documento: `pubsub`, `firestore`.

`cloudfunctions`, `run` e `cloudbuild` saem da lista junto com `roles/cloudfunctions.developer` e `roles/run.admin`. O recurso de API usa `disable_on_destroy = false`, então o apply só deixa de rastreá-las. Para desligá-las no projeto, depois do apply:

```bash
gcloud services disable cloudfunctions.googleapis.com \
  --project=vcosta-fiap-tech-challenge
gcloud services disable run.googleapis.com cloudbuild.googleapis.com \
  --project=vcosta-fiap-tech-challenge
```

`cloudfunctions` sai primeiro: ela depende das outras duas. Se o disable acusar recurso ainda usando a API, pare e não use `--force`.

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
| Output `runtime_service_account_emails` | `infra-k8s`: anotação da service account Kubernetes e binding de Workload Identity. Chave = account id. O output `api_runtime_service_account_email` não existe mais; o `plan` do `infra-k8s` falha até esse stack passar a ler o mapa |
| Outputs DNS (`dns_managed_zone_name`, `dns_name`, `dns_name_servers`) | `infra-k8s` (records `api`/`auth`); nameservers vão uma vez no registrador (Hostinger) |
| `us-central1-docker.pkg.dev/vcosta-fiap-tech-challenge/tech-challenge` | workflows de build/push e deploy (org var `GCP_AR_REPOSITORY` = `tech-challenge`). O repositório não muda; cada imagem é um pacote dentro dele |

## Domínio e nameservers

A zona Cloud DNS é **persistente** (~US$ 0,20/mês). Depois do `apply` local:

```bash
cd terraform
terraform output -json dns_name_servers
```

No registrador (Hostinger), troque os nameservers do domínio `vcosta-fiap.online` pelos quatro NS Google dessa saída. Records `api` / `auth` **não** moram aqui — o `infra-k8s` os cria e apaga a cada ciclo de demo.

O caminho da imagem não é output porque quem o consome não roda Terraform: o workflow o monta a partir de literais e da org var `GCP_AR_REPOSITORY` (`tech-challenge`). Os e-mails de runtime saem do output `runtime_service_account_emails`. Não há org var para esses e-mails, nem para id de tópico ou nome da instância SQL.

## Workload Identity de runtime mora no `infra-k8s`

O pool `vcosta-fiap-tech-challenge.svc.id.goog` só existe **enquanto houver um cluster com Workload Identity no projeto**. Conceder `roles/iam.workloadIdentityUser` à KSA daqui falharia com `Identity Pool does not exist` sempre que a demo estivesse derrubada.

Por isso este stack só cria as service accounts de runtime, `roles/cloudsql.client` nas de PostgreSQL e `roles/datastore.user` nas de Firestore. O binding KSA → service account é criado pelo `infra-k8s`, depois do cluster, e morre junto com ele. Publisher e subscriber de Pub/Sub não são concedidos aqui.

## Decisões (ADRs)

Ver [`docs/README.md`](docs/README.md). Em especial: [GCP, região e custo](docs/adrs/001-gcp-regiao-custo.md) e [camada persistente](docs/adrs/002-camada-persistente.md).

## Repos da org

| Repo | Papel | Diagrama / doc-chave |
|------|--------|----------------------|
| [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap) | Rede, WIF, AR, zona DNS | Persistente (este repo) |
| [`infra-db`](https://github.com/fiap-vcosta/infra-db) | Cloud SQL | ADRs de banco |
| [`infra-events`](https://github.com/fiap-vcosta/infra-events) | Tópicos Pub/Sub | README |
| [`infra-k8s`](https://github.com/fiap-vcosta/infra-k8s) | GKE + API Gateway | [Componentes](https://github.com/fiap-vcosta/infra-k8s#componentes-nuvem) |
| [`ordem-servico-service`](https://github.com/fiap-vcosta/ordem-servico-service) | Ordens de serviço | README |
| [`estoque-service`](https://github.com/fiap-vcosta/estoque-service) | Estoque | README |
| [`orcamento-service`](https://github.com/fiap-vcosta/orcamento-service) | Orçamento | README |
| [`administrativo-service`](https://github.com/fiap-vcosta/administrativo-service) | Cadastros | README |
| [`autenticacao-service`](https://github.com/fiap-vcosta/autenticacao-service) | Login e JWT | README |
| [`building-blocks`](https://github.com/fiap-vcosta/building-blocks) | Pacote compartilhado | README |
| [`e2e`](https://github.com/fiap-vcosta/e2e) | Compose, BDD e contratos | README |

## Agentes

Ver [AGENTS.md](AGENTS.md).
