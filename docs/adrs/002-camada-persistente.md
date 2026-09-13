# ADR 002: Camada Persistente (`infra-bootstrap`)

**Data:** 10 de Setembro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

A demo sobe e derruba Cloud SQL e GKE a cada janela (`tf-destroy` sem carve-outs). Alguns recursos, porém, são pré-requisito de todos os stacks, custam ~zero parados e **não podem morrer** no destroy da demo: bucket de state Terraform, rede (VPC/subnet/PSA), Workload Identity Federation, service accounts/roles, Artifact Registry e a managed zone pública do Cloud DNS (domínio da demo).

No início, parte disso vivia misturada aos stacks descartáveis. Isso gerava tensão: ou o destroy apagava o que a próxima demo precisava, ou surgiam carve-outs (`prevent_destroy`, `-target`) que mentiam o state.

O problema a ser resolvido é: **Onde moram os recursos estáveis da GCP, quem os aplica, e como o CI se autentica sem se auto-promover?**

## 2. Decisão

- **Repo dedicado** [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap): camada **persistente** — APIs habilitadas, bucket de state, WIF (pool/provider), SA `github-actions` e roles, VPC/subnet/PSA, Artifact Registry, SA de runtime da API (`cloudsql.client`), Cloud DNS managed zone do domínio da demo.
- **Apply/destroy:** **local**, com ADC de humano com **owner**. **Sem** workflow de `tf-apply` / `tf-destroy` neste repo. CI só `fmt` / `validate`.
- **Consumo:** `infra-db` e `infra-k8s` leem rede (e outputs relacionados) via `terraform_remote_state`; não recriam a VPC aqui. Records DNS da janela (`api`/`auth`) ficam no `infra-k8s`.
- **WIF do CI:** binding `roles/iam.workloadIdentityUser` **por repositório** (`ci_repositories`), não por org inteira.
- **Fora deste repo:** Cloud SQL, cluster GKE, manifests da API, serviço `auth`, records DNS transitórios. Binding KSA → SA de runtime mora no `infra-k8s` (o pool `svc.id.goog` só existe com cluster vivo).

## 3. Justificativa

* **Ciclo de demo limpo:** `tf-destroy` em `infra-db` / `infra-k8s` apaga o state inteiro daqueles repos sem apagar state GCS, rede nem registry.
* **IAM não pode ser aplicado pela SA de CI:** este stack **concede** roles à `github-actions`. Se o CI o aplicasse, a SA precisaria de permissão de IAM sobre si mesma e poderia se auto-promover — risco inaceitável.
* **Custo idle ~zero:** VPC parada, bucket em bytes, AR abaixo do free tier típico da demo; Cloud DNS zone ~centavos/mês — nameservers no registrador mudam **uma vez**, sem editar Hostinger a cada demo.
* **WIF por repo:** um repositório novo na org não ganha acesso à GCP só por existir; inclusão exige mudança explícita em `ci_repositories` + apply local.

## 4. Alternativas Consideradas

* **Tudo num único Terraform (db + k8s + rede + WIF):** um `destroy` da demo apagaria state/rede/WIF ou exigiria carve-outs — rejeitado.
* **Rede/WIF dentro de `infra-db` ou `infra-k8s` com `prevent_destroy`:** state incoerente e “órfãos protegidos”; rejeitado pela política de destroy sem carve-outs.
* **Apply do bootstrap via CI com SA privilegiada:** conveniente; rejeitado pelo risco de auto-promoção de IAM.
* **WIF por org (`attribute.repository` amplo):** mais simples; rejeitado — blast radius se um repo comprometido ou mal configurado nascesse na org.
* **Bucket de state / AR gerenciados só na console:** possível; pior para reprodutibilidade e onboarding.

## 5. Consequências

### Positivas
* Demo-up/down previsível: bootstrap uma vez; db → k8s → deploy; destroy inverso sem tocar no bootstrap.
* Least-privilege da SA de CI versionado e revisável em PR (apply ainda humano).
* Imagem no Artifact Registry pode sobreviver entre demos (`build-push` independente do cluster).

### Negativas / Riscos (Mitigações)
* **Apply local exige disciplina** (owner + leitura cuidadosa do plan).
  * *Mitigação:* README e AGENTS; CI não aplica; plan linha a linha antes de apply.
* **Contrato rígido com outros repos** (CIDRs, nomes de outputs, e-mail da SA de runtime).
  * *Mitigação:* documentar no README; mudança que quebra consumidores exige confirmação explícita.
* **Binding de Workload Identity da API não vive aqui.**
  * *Mitigação:* documentado; implementado no `infra-k8s` após o cluster existir.
