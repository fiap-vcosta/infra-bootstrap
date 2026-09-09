# infra-bootstrap

Terraform da camada **persistente** da infraestrutura GCP do Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)). São os recursos gratuitos (ou de centavos) que os outros stacks consomem e que **não** entram no ciclo de subir/derrubar a demo.

## Escopo

- Habilitação das APIs usadas pelos stacks (`disable_on_destroy = false`)
- Bucket GCS do backend de state (`vcosta-fiap-tech-challenge-tfstate`)
- Workload Identity Federation: pool/provider `github` + service account `github-actions` e suas roles
- VPC `techchallenge-vpc`, subnet regional com ranges secundários do cluster e range/peering do Private Service Access
- Artifact Registry Docker `techchallenge` (imagem sobrevive entre demos)
- Service account de runtime da API (`techchallenge-api`) com `roles/cloudsql.client` e Workload Identity para o cluster
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

No primeiro `plan`, confirmar que o resumo traz apenas `import` e `add`, com **0 to change, 0 to destroy**. Qualquer `destroy` ou `replace` indica divergência entre o código e o recurso real — parar e corrigir o código antes de aplicar, porque os recursos importados sustentam o OIDC do CI e o acesso ao state.

Os `import` blocks em [`terraform/imports.tf`](terraform/imports.tf) adotam o que foi criado à mão antes deste repo existir. Depois do primeiro apply bem-sucedido eles são inertes e podem ser removidos.

## Roles da service account de CI

Least-privilege, sem `roles/editor`, definidas em [`terraform/iam.tf`](terraform/iam.tf):

- `roles/viewer`
- `roles/cloudsql.admin`
- `roles/compute.networkAdmin`
- `roles/container.admin`
- `roles/artifactregistry.writer`
- `roles/secretmanager.admin`
- `roles/storage.objectAdmin` no bucket de state
- `roles/iam.serviceAccountUser` na service account padrão de compute (exigência de criação do cluster)

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
| VPC/subnet e nomes dos ranges secundários | `infra-db` (IP privado do SQL), `infra-k8s` (cluster) |
| URL do Artifact Registry | workflows de build/push e deploy da `api` |
| Namespace `techchallenge` e service account Kubernetes `api` | binding de Workload Identity da service account de runtime |

## Agentes

Ver [AGENTS.md](AGENTS.md).
