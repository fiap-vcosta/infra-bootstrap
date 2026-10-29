# ADR 002: Camada Persistente (`infra-bootstrap`)

**Data:** 10 de Setembro de 2026  
**Atualizado:** 25 de Outubro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

A demo sobe e derruba Cloud SQL e GKE a cada janela (`tf-destroy` sem carve-outs). Alguns recursos, porém, são pré-requisito de todos os stacks, custam ~zero parados e **não podem morrer** no destroy da demo: bucket de state Terraform, rede (VPC/subnet/PSA), Workload Identity Federation, service accounts/roles, Artifact Registry e a managed zone pública do Cloud DNS (domínio da demo).

No início, parte disso vivia misturada aos stacks descartáveis. Isso gerava tensão: ou o destroy apagava o que a próxima demo precisava, ou surgiam carve-outs (`prevent_destroy`, `-target`) que mentiam o state.

O problema a ser resolvido é: **Onde moram os recursos estáveis da GCP, quem os aplica, e como o CI se autentica sem se auto-promover?**

## 2. Decisão

- **Repo dedicado** [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap): camada **persistente** — APIs habilitadas, bucket de state, WIF (pool/provider), SA `github-actions` e roles, VPC/subnet/PSA, Artifact Registry, cinco service accounts de runtime e Cloud DNS managed zone do domínio da demo.
- **Runtime:** account id igual ao repositório. `roles/cloudsql.client` em `ordem-servico-service`, `estoque-service` e `administrativo-service`. `roles/datastore.user` no projeto em `orcamento-service` e `autenticacao-service`. Output `runtime_service_account_emails` (chave = account id). A SA única `tech-challenge-api` e o output `api_runtime_service_account_email` saem.
- **CI sobre Pub/Sub e Firestore:** custom roles só de administração (tópico, subscription, IAM desses recursos, database, índice e operação). Sem `publish`, `consume` ou `datastore.entities.*`. Publisher e subscriber das SAs de runtime não moram aqui.
- **Apply/destroy:** **local**, com ADC de humano com **owner**. **Sem** workflow de `tf-apply` / `tf-destroy` neste repo. CI só `fmt` / `validate`.
- **Consumo:** `infra-db` e `infra-k8s` leem rede (e outputs relacionados) via `terraform_remote_state`; não recriam a VPC aqui. Records DNS da janela (`api`/`auth`) ficam no `infra-k8s`.
- **WIF do CI:** binding `roles/iam.workloadIdentityUser` **por repositório** (`ci_repositories`), não por org inteira.
- **Fora deste repo:** Cloud SQL, cluster GKE, manifests da API, serviço `auth`, records DNS transitórios. Binding KSA → SA de runtime mora no `infra-k8s` (o pool `svc.id.goog` só existe com cluster vivo).

## 3. Justificativa

* **Ciclo de demo limpo:** `tf-destroy` em `infra-db` / `infra-k8s` apaga o state inteiro daqueles repos sem apagar state GCS, rede nem registry.
* **IAM não pode ser aplicado pela SA de CI:** este stack **concede** roles à `github-actions`. Se o CI o aplicasse, a SA precisaria de permissão de IAM sobre si mesma e poderia se auto-promover — risco inaceitável.
* **Custo idle ~zero:** VPC parada, bucket em bytes, AR abaixo do free tier típico da demo; Cloud DNS zone ~centavos/mês — nameservers no registrador mudam **uma vez**, sem editar Hostinger a cada demo.
* **WIF por repo:** um repositório novo na org não ganha acesso à GCP só por existir; inclusão exige mudança explícita em `ci_repositories` + apply local.
* **Uma SA de runtime por serviço:** `cloudsql.client` só onde há PostgreSQL e `datastore.user` só onde há Firestore. Uma SA compartilhada ampliaria o blast radius de cada processo.

## 4. Alternativas Consideradas

* **Tudo num único Terraform (db + k8s + rede + WIF):** um `destroy` da demo apagaria state/rede/WIF ou exigiria carve-outs — rejeitado.
* **Rede/WIF dentro de `infra-db` ou `infra-k8s` com `prevent_destroy`:** state incoerente e “órfãos protegidos”; rejeitado pela política de destroy sem carve-outs.
* **Apply do bootstrap via CI com SA privilegiada:** conveniente; rejeitado pelo risco de auto-promoção de IAM.
* **WIF por org (`attribute.repository` amplo):** mais simples; rejeitado — blast radius se um repo comprometido ou mal configurado nascesse na org.
* **Bucket de state / AR gerenciados só na console:** possível; pior para reprodutibilidade e onboarding.
* **Uma única SA de runtime para todos os serviços:** menos outputs; rejeitado — o processo de estoque não precisa ler Firestore, e o de orçamento não precisa de `cloudsql.client`.

## 5. Consequências

### Positivas
* Demo-up/down previsível: bootstrap uma vez; db → k8s → deploy; destroy inverso sem tocar no bootstrap.
* Least-privilege da SA de CI versionado e revisável em PR (apply ainda humano).
* Imagem no Artifact Registry pode sobreviver entre demos (`build-push` independente do cluster).

### Negativas / Riscos (Mitigações)
* **Apply local exige disciplina** (owner + leitura cuidadosa do plan).
  * *Mitigação:* README e AGENTS; CI não aplica; plan linha a linha antes de apply.
* **Contrato rígido com outros repos** (CIDRs, nomes de outputs, e-mails das SAs de runtime).
  * *Mitigação:* documentar no README; mudança que quebra consumidores exige confirmação explícita.
* **O `infra-k8s` ainda lê `api_runtime_service_account_email`.**
  * *Mitigação:* o output novo está documentado; o `plan` daquele stack falha até passar a ler `runtime_service_account_emails`. A correção é lá.
* **`roles/datastore.user` é no projeto**, não no database nomeado.
  * *Mitigação:* o database ainda não existe neste stack. Apertar o grant para o database fica no Terraform do serviço, quando ele criar o banco.
* **Binding de Workload Identity não vive aqui.**
  * *Mitigação:* documentado; implementado no `infra-k8s` após o cluster existir. A role `serviceAccountIamPolicyWriter` do CI vale em cada SA de runtime para esse binding.
