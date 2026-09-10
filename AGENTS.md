# Tech Challenge — Guia para agentes (`infra-bootstrap`)

Terraform da camada **persistente** do projeto na GCP: habilitação de APIs, bucket de state, Workload Identity Federation, service accounts, rede (VPC/subnet/PSA) e Artifact Registry. Org [fiap-vcosta](https://github.com/fiap-vcosta). Cloud SQL fica em `infra-db`; cluster e manifests em `infra-k8s`; Function em `auth`.

## Antes de mudar código

1. Ler ADRs em [`docs/adrs/`](docs/adrs/) e as decisões de custo/demo já tomadas
2. Espelhar módulos/pastas vizinhas (`infra-db`, `infra-k8s`); não inventar layout paralelo
3. Não rodar `apply`/`destroy` sem confirmação explícita do usuário
4. **Git:** nunca commit/push direto em `main` — branch → PR → merge (ver [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc))

## Responsabilidade

| Peça | Papel |
|------|--------|
| Terraform | APIs, bucket de state, WIF, SAs e roles, VPC/subnet/PSA, Artifact Registry |
| Apply | **Local, por humano com owner** — nunca por CI |
| Ciclo de vida | Recursos gratuitos e estáveis; **não** entram no `tf-destroy` da demo |
| Fora de escopo | Cloud SQL, cluster GKE, manifests, código da API e da Function |

## Regras canônicas (resumo)

- Este stack concede IAM: se o CI o aplicasse, a SA de CI poderia se auto-promover
- Nada aqui morre no ciclo de demo; os outros stacks referenciam estes recursos
- Workload Identity do CI é por repositório (`ci_repositories`), não por org
- Binding KSA → SA de runtime não cabe aqui: o pool `svc.id.goog` só existe com cluster vivo (mora no `infra-k8s`)
- CI só `fmt`/`validate`; sem workflow de apply nem de destroy
- Sem secrets no Git

## Comandos

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
# init/plan/apply reais: só local, com ADC de owner e confirmação humana
```
