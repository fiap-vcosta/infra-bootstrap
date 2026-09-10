# ADR 001: GCP, Região e Custo

**Data:** 10 de Setembro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

O Tech Challenge precisa hospedar a API, o banco, o cluster e a Function de auth cliente em nuvem, com conta pessoal, maximizando free tier e mantendo os custos baixos. A camada persistente deste repo (`infra-bootstrap`) habilita APIs, guarda o state Terraform, a rede, o WIF e o Artifact Registry — recursos que os stacks descartáveis (`infra-db`, `infra-k8s`) consomem.

O problema a ser resolvido é: **Qual provedor e em qual região operamos a demo, com que postura de custo?**

## 2. Decisão

- **Nuvem:** Google Cloud Platform (GCP), projeto `vcosta-fiap-tech-challenge`.
- **Região:** `us-central1` (Iowa).
- **Custo:** usar o máximo do free tier possível e manter os gastos baixos; stacks caros (`infra-db`, `infra-k8s`) só na janela da demo. Este bootstrap permanece (custo idle ~zero).

## 3. Justificativa

* **Experiência com a plataforma:** o curso recomenda AWS; a escolha por GCP veio da familiaridade prévia com o ecossistema Google Cloud (GKE, Cloud SQL, Functions, Artifact Registry), reduzindo atrito na entrega.
* **`us-central1`:** é a região que melhor encaixa no free tier e no preço dos serviços usados pelo stack (SQL, Autopilot, Functions, Gateway, Artifact Registry) num único lugar.
* **Latência irrelevante** para a demo acadêmica; prioridade é free tier e custo baixo.
* **Processo up/down:** `infra-db` / `infra-k8s` sobem e descem com a demo; o freio operacional é o destroy ao fim da janela.

## 4. Alternativas Consideradas

* **AWS:** recomendação do curso; tecnicamente viável (ECS/EKS, RDS, Lambda, etc.). Descartada em favor da GCP pela experiência já acumulada na plataforma.
* **Azure:** viável; fora do caminho escolhido (GCP) e sem o mesmo ganho de familiaridade neste projeto.

## 5. Consequências

### Positivas
* Terraform, org vars e workflows usam a mesma região (`us-central1` / `GCP_REGION`).
* API, SQL, cluster, Function e Gateway convivem na mesma região sem desenho multi-region.
* Postura de custo explícita: free tier primeiro; nuvem cara só sob ação consciente na demo.

### Negativas / Riscos (Mitigações)
* **Stacks caros esquecidos ligados** ainda sangram.
  * *Mitigação:* processo demo-down obrigatório (`tf-destroy` k8s → db); política de não deixar nada ligado overnight sem necessidade.
* **Quota em `us-central1`:** Autopilot ou SQL podem falhar na hora do apply.
  * *Mitigação:* tratar na execução (aguardar quota / ajustar sizing); a região canônica permanece `us-central1`.
* **Projeto e billing fora do Terraform:** criados na console.
  * *Mitigação:* documentados no README deste repo e nos stacks vizinhos; este ADR fixa provedor e região.
