# ADR 001: GCP, Região e Budget

**Data:** 10 de Setembro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

O Tech Challenge precisa hospedar a API, o banco, o cluster e (depois) a Function de auth cliente em nuvem, com conta pessoal, maximizando free tier e limitando gasto. A camada persistente deste repo (`infra-bootstrap`) habilita APIs, guarda o state Terraform, a rede, o WIF e o Artifact Registry — recursos que os stacks descartáveis (`infra-db`, `infra-k8s`) consomem.

O problema a ser resolvido é: **Qual provedor, em qual região, e com qual freio de custo operamos a demo?**

## 2. Decisão

- **Nuvem:** Google Cloud Platform (GCP), projeto `vcosta-fiap-tech-challenge`.
- **Região:** `us-central1` (Iowa). Plano B de quota: `us-east1`.
- **Teto de gasto:** Budget `tech-challenge` de **R$ 50/mês**, limiares de alerta em 25% / 50% / 75% / 100%. O Budget **alerta**; não desliga recursos. O freio operacional é derrubar os stacks caros ao fim da demo.

## 3. Justificativa

* **Um único lugar para o stack:** Cloud SQL, GKE Autopilot, Cloud Functions (2nd gen), API Gateway e Artifact Registry cabem em `us-central1`. API Gateway não está em todas as regiões (ex.: `us-west1` fica de fora).
* **Free tier e preço:** Always Free de Storage e Compute alinhados a `us-central1` / `us-east1`; Functions 2nd gen herda pricing Tier 1 de Cloud Run em `us-central1`. `southamerica-east1` é Tier 2 (mais cara) e pior para o critério de custo desta fase.
* **Latência irrelevante** para a demo acadêmica; prioridade é caber no Budget e no free tier.
* **Budget + processo up/down:** alerta cedo; stacks `infra-db` / `infra-k8s` só na janela da demo. Este bootstrap permanece (custo idle ~zero).

## 4. Alternativas Consideradas

* **AWS / Azure:** viáveis tecnicamente; descartadas para manter um único ecossistema alinhado ao enunciado (GKE / Cloud SQL / Functions / API Gateway) e ao material do curso.
* **`southamerica-east1` (São Paulo):** melhor latência local; descartada por Tier 2 e custo mais alto sem benefício para a demo.
* **`us-west1`:** free tier em parte dos produtos, mas **sem** API Gateway na região.
* **Sem Budget / só disciplina manual:** arriscado em conta pessoal; alertas baratos e suficientes como rede de segurança.

## 5. Consequências

### Positivas
* Terraform, org vars e workflows usam a mesma região literais/`GCP_REGION`.
* Gateway, Function e SQL podem coexistir na mesma região sem gambiarra multi-region.
* Alertas de Billing reduzem chance de surpresa no cartão.

### Negativas / Riscos (Mitigações)
* **Budget não desliga recursos:** um cluster esquecido overnight ainda sangra.
  * *Mitigação:* processo demo-down obrigatório (`tf-destroy` k8s → db); política de não deixar nada ligado overnight sem necessidade.
* **Quota em `us-central1`:** Autopilot ou SQL podem falhar na hora do apply.
  * *Mitigação:* plano B `us-east1` (mesma família de preço / Gateway); trocar região exige alinhar todos os stacks e org vars.
* **Projeto e billing fora do Terraform:** criados na console.
  * *Mitigação:* documentados no README deste repo e nos stacks vizinhos; este ADR fixa os valores canônicos.
