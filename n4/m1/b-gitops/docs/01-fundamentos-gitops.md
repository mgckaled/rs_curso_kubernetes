<!-- markdownlint-disable -->

# Fundamentos de GitOps - Aulas 1 e 2

Documentacao conceitual que abrange os fundamentos de GitOps e sua aplicacao no contexto do Kubernetes. Este material cobre os conceitos apresentados nas duas primeiras aulas do modulo, desde a definicao de GitOps ate a reconciliacao continua em clusters Kubernetes.

---

## Indice

1. [O que e GitOps](#o-que-e-gitops)
2. [Git como Fonte Unica da Verdade](#git-como-fonte-unica-da-verdade)
3. [Declarativo vs Imperativo](#declarativo-vs-imperativo)
4. [Infraestrutura como Codigo (IaC)](#infraestrutura-como-codigo-iac)
5. [Rastreabilidade, Governanca e Auditoria](#rastreabilidade-governanca-e-auditoria)
6. [Beneficios do Modelo GitOps](#beneficios-do-modelo-gitops)
7. [GitOps no Kubernetes](#gitops-no-kubernetes)
8. [Estado Desejado vs Estado Real](#estado-desejado-vs-estado-real)
9. [Drift de Configuracao](#drift-de-configuracao)
10. [Reconciliacao Continua](#reconciliacao-continua)
11. [Pull-based vs Push-based Delivery](#pull-based-vs-push-based-delivery)
12. [YAML como Codigo Versionado](#yaml-como-codigo-versionado)
13. [Por que kubectl apply Manual nao e GitOps](#por-que-kubectl-apply-manual-nao-e-gitops)
14. [Kubernetes ja e Declarativo - GitOps Complementa](#kubernetes-ja-e-declarativo---gitops-complementa)
15. [Resumo Geral](#resumo-geral)

---

## O que e GitOps

GitOps e um modelo operacional que utiliza o **Git como fonte unica da verdade** para toda a infraestrutura e configuracao de aplicacoes. Em vez de realizar alteracoes diretamente em servidores, clusters ou consoles de cloud, todas as mudancas sao feitas atraves de commits em um repositorio Git.

A ideia central e simples: **se nao esta no Git, nao deveria existir no ambiente**.

### Principios fundamentais do GitOps

- **Declarativo:** O estado desejado do sistema e descrito de forma declarativa (arquivos YAML, HCL, JSON, etc.)
- **Versionado:** Toda configuracao e armazenada em um sistema de controle de versao (Git)
- **Automatizado:** Alteracoes aprovadas sao aplicadas automaticamente ao ambiente
- **Reconciliavel:** Agentes continuamente comparam o estado real com o estado desejado e corrigem divergencias

### Visao geral do fluxo GitOps

```
┌───────────────────────────────────────────────────────────────────┐
│                        Fluxo GitOps                               │
│                                                                   │
│   Desenvolvedor         Repositorio Git         Ambiente          │
│                                                                   │
│   ┌──────────┐       ┌────────────────┐     ┌──────────────┐    │
│   │  Edita   │──────>│   Commit /     │────>│  Ferramenta  │    │
│   │  YAML    │       │   Pull Request │     │  GitOps      │    │
│   └──────────┘       └────────────────┘     │  (Argo CD)   │    │
│                              │               └──────┬───────┘    │
│                              │                      │            │
│                              │                      ▼            │
│                       ┌──────────────┐     ┌──────────────┐     │
│                       │  Historico    │     │  Cluster     │     │
│                       │  Completo    │     │  Kubernetes  │     │
│                       └──────────────┘     └──────────────┘     │
└───────────────────────────────────────────────────────────────────┘
```

---

## Git como Fonte Unica da Verdade

O conceito de **fonte unica da verdade** (Single Source of Truth) significa que o repositorio Git e a referencia absoluta para o estado de todo o sistema. Qualquer configuracao, recurso ou politica que exista no ambiente **deve estar representado no Git**.

### O que o Git define

| Aspecto | Descricao |
|---------|-----------|
| **O que existe** | Quais recursos estao provisionados (deployments, services, infra) |
| **Como existe** | Configuracoes detalhadas de cada recurso (replicas, limites, portas) |
| **Quando mudou** | Historico completo de alteracoes via commits |
| **Quem mudou** | Autor do commit e aprovadores do Pull Request |
| **Por que mudou** | Mensagem de commit e descricao do PR |

### Regra de ouro

- Alteracoes feitas **fora do Git** sao consideradas invalidas
- Alteracoes manuais no cluster ou na cloud **serao sobrescritas**
- O ambiente deve **sempre convergir** para o estado definido no Git

### Exemplo pratico

Suponha que alguem acesse o cluster e execute manualmente:

```bash
# Alteracao manual - NAO e GitOps
kubectl scale deployment minha-app --replicas=10
```

Se o Git define `replicas: 3`, a ferramenta GitOps ira detectar a divergencia e **reverter para 3 replicas**, ignorando a mudanca manual.

---

## Declarativo vs Imperativo

Entender a diferenca entre abordagem declarativa e imperativa e essencial para compreender o GitOps.

### Abordagem imperativa

Voce diz ao sistema **como fazer**, passo a passo:

```bash
# Criacao imperativa de recursos
kubectl create namespace producao
kubectl create deployment nginx --image=nginx:1.25 -n producao
kubectl scale deployment nginx --replicas=3 -n producao
kubectl expose deployment nginx --port=80 --type=ClusterIP -n producao
```

### Abordagem declarativa

Voce diz ao sistema **o que voce quer**, e ele se encarrega de chegar la:

```yaml
# Configuracao declarativa - deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: producao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
```

### Tabela comparativa

| Aspecto | Imperativo | Declarativo |
|---------|-----------|-------------|
| **Descricao** | Define os passos (como fazer) | Define o resultado (o que fazer) |
| **Rastreabilidade** | Nenhuma ou limitada | Completa via Git |
| **Reprodutibilidade** | Dificil replicar exatamente | Basta aplicar o mesmo arquivo |
| **Rollback** | Manual e propenso a erros | Simples: reverter commit no Git |
| **Auditoria** | Inexistente | Completa pelo historico de commits |
| **Automacao** | Complexa (scripts frageis) | Nativa (GitOps, CI/CD) |
| **Colaboracao** | Quase impossivel | Pull Requests, code review |
| **Estado do sistema** | Desconhecido (quem fez o que?) | Definido no repositorio |
| **Exemplo no K8s** | `kubectl create`, `kubectl scale` | `kubectl apply -f manifest.yaml` |
| **Exemplo na cloud** | Console AWS, CLI ad-hoc | Terraform, CloudFormation |

### Por que declarativo e melhor para operacoes

No modelo imperativo, se um comando falha no meio da execucao, o sistema fica em um **estado parcial e inconsistente**. No modelo declarativo, voce define o estado final desejado e o sistema se encarrega de convergir, independentemente do estado atual.

---

## Infraestrutura como Codigo (IaC)

GitOps tem forte paralelo com **Infraestrutura como Codigo (Infrastructure as Code - IaC)**, pratica ja consolidada em ambientes de cloud.

### O problema: criacao manual de infraestrutura

```
┌─────────────────────────────────────────────────────────┐
│              SEM IaC (Abordagem Manual)                  │
│                                                          │
│   Operador ──> Console AWS ──> Cria VPC manualmente     │
│                         ├──> Cria EC2 manualmente        │
│                         ├──> Cria RDS manualmente        │
│                         └──> Cria S3 manualmente         │
│                                                          │
│   Problemas:                                             │
│   - Sem historico de mudancas                            │
│   - Impossivel reproduzir ambiente                      │
│   - Ninguem sabe o que foi alterado                     │
│   - Custos descontrolados                               │
│   - Ambientes divergentes (dev != prod)                 │
└─────────────────────────────────────────────────────────┘
```

### A solucao: IaC com Git

```
┌─────────────────────────────────────────────────────────┐
│              COM IaC (Abordagem GitOps)                  │
│                                                          │
│   Operador ──> Edita arquivo .tf ──> Commit no Git      │
│                                        │                 │
│                                        ▼                 │
│                               Pull Request / Review      │
│                                        │                 │
│                                        ▼                 │
│                               Pipeline aplica no         │
│                               ambiente automaticamente   │
│                                                          │
│   Beneficios:                                            │
│   - Historico completo no Git                            │
│   - Ambiente reproduzivel                               │
│   - Code review obrigatorio                             │
│   - Custos controlados                                  │
│   - Ambientes consistentes                              │
└─────────────────────────────────────────────────────────┘
```

### Ferramentas de IaC populares

| Ferramenta | Provedor | Linguagem | Tipo |
|-----------|----------|-----------|------|
| **Terraform** | Multi-cloud | HCL | Declarativo |
| **CloudFormation** | AWS | YAML/JSON | Declarativo |
| **Pulumi** | Multi-cloud | TypeScript, Python, Go | Declarativo |
| **Ansible** | Multi-plataforma | YAML | Procedural/Declarativo |

### Paralelo IaC e GitOps no Kubernetes

| Aspecto | IaC (Cloud) | GitOps (Kubernetes) |
|---------|-------------|---------------------|
| **Ferramenta** | Terraform, CloudFormation | Argo CD, Flux |
| **Linguagem** | HCL, YAML | YAML (manifests K8s) |
| **Repositorio** | Git | Git |
| **Estado desejado** | Arquivos .tf | Arquivos .yaml |
| **Aplicacao** | `terraform apply` (pipeline) | Reconciliacao automatica |
| **Alvo** | VMs, redes, bancos de dados | Pods, Services, Deployments |

A logica e a mesma: **o Git define o que deve existir**, e uma ferramenta automatizada garante que o ambiente real reflita essa definicao.

---

## Rastreabilidade, Governanca e Auditoria

GitOps resolve tres problemas criticos em operacoes de infraestrutura e Kubernetes.

### Rastreabilidade

Cada mudanca no sistema corresponde a um commit no Git. Isso significa que e possivel responder com precisao:

- **O que mudou?** (diff do commit)
- **Quando mudou?** (timestamp do commit)
- **Quem mudou?** (autor do commit)
- **Por que mudou?** (mensagem do commit / descricao do PR)

### Governanca

Com GitOps, toda alteracao passa por um fluxo controlado:

```
Desenvolvedor propoe mudanca (branch)
        │
        ▼
Pull Request criado
        │
        ▼
Code Review por pares
        │
        ▼
Aprovacao obrigatoria
        │
        ▼
Merge na branch principal
        │
        ▼
Ferramenta GitOps aplica automaticamente
```

Ninguem altera o ambiente diretamente. Toda mudanca e revisada e aprovada antes de ser aplicada.

### Auditoria

O historico do Git funciona como um **log de auditoria completo e imutavel**. Em cenarios regulatorios ou de compliance, e possivel demonstrar exatamente quem autorizou cada mudanca e quando ela foi aplicada.

---

## Beneficios do Modelo GitOps

### Pull Requests como mecanismo de controle

Pull Requests (PRs) sao a porta de entrada para qualquer mudanca no ambiente:

- **Revisao tecnica:** colegas verificam se a mudanca e correta
- **Testes automaticos:** pipelines validam a configuracao antes do merge
- **Aprovacao formal:** gatekeepers autorizam a mudanca
- **Documentacao:** o PR registra o contexto e a motivacao

### Controle de custos

No modelo manual, recursos podem ser criados sem controle:

- Alguem cria uma instancia EC2 "temporaria" que nunca e removida
- Alguem escala um deployment para 20 replicas e esquece de reverter
- Recursos orfaos acumulam custos silenciosamente

Com GitOps, **tudo que existe deve estar no Git**. Se um recurso nao esta no repositorio, a ferramenta GitOps ira remove-lo. Isso impede a proliferacao de recursos nao autorizados.

### Padronizacao

GitOps garante que todos os ambientes sigam o mesmo padrao:

| Sem GitOps | Com GitOps |
|-----------|-----------|
| Cada operador configura de um jeito | Um unico repositorio define o padrao |
| Ambientes divergem com o tempo | Ambientes sao identicos (mesmo Git) |
| "Funciona na minha maquina" | Funciona em qualquer lugar (reprodutivel) |
| Configuracoes se perdem | Tudo esta versionado e recuperavel |

---

## GitOps no Kubernetes

### Por que Kubernetes e ideal para GitOps

O Kubernetes ja opera com um modelo declarativo por natureza. Voce descreve o estado desejado em arquivos YAML e o Kubernetes trabalha continuamente para manter esse estado. GitOps estende esse modelo para o **ciclo de vida operacional completo**.

### Git como repositorio duplo

No contexto GitOps com Kubernetes, o Git assume dois papeis:

```
┌──────────────────────────────────────────────────────────┐
│                   Repositorio Git                         │
│                                                           │
│   ┌──────────────────────┐  ┌──────────────────────────┐│
│   │  Repositorio de      │  │  Repositorio de           ││
│   │  Codigo da Aplicacao │  │  Configuracao (Manifests) ││
│   │                      │  │                           ││
│   │  - src/              │  │  - deployments/           ││
│   │  - Dockerfile        │  │  - services/              ││
│   │  - tests/            │  │  - configmaps/            ││
│   │  - package.json      │  │  - ingress/               ││
│   └──────────────────────┘  └──────────────────────────┘│
│                                                           │
│   Podem ser o mesmo repositorio ou repositorios separados │
└──────────────────────────────────────────────────────────┘
```

---

## Estado Desejado vs Estado Real

Este e um dos conceitos mais importantes do GitOps no Kubernetes.

### Estado desejado

O **estado desejado** e o que esta definido nos arquivos YAML armazenados no Git. Ele representa como o cluster **deveria estar**.

Exemplo: o Git define que a aplicacao deve ter 3 replicas rodando a imagem `v2.0`:

```yaml
# Estado desejado (definido no Git)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minha-app
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: app
          image: minha-app:v2.0
```

### Estado real

O **estado real** e o que efetivamente esta rodando no cluster Kubernetes naquele momento. Pode ser consultado com:

```bash
kubectl get deployment minha-app -o yaml
```

### Quando divergem

Se alguem executa manualmente `kubectl scale deployment minha-app --replicas=5`, o estado real passa a ser 5 replicas, enquanto o estado desejado no Git continua sendo 3. Essa diferenca e chamada de **drift**.

```
┌──────────────────────┐          ┌──────────────────────┐
│   Estado Desejado    │          │    Estado Real        │
│   (Git)              │          │    (Cluster)          │
│                      │          │                       │
│   replicas: 3        │  =/=    │   replicas: 5         │
│   image: v2.0        │          │   image: v2.0         │
│                      │          │                       │
└──────────────────────┘          └──────────────────────┘
         │                                  │
         │            DRIFT                 │
         │   (divergencia detectada)        │
         └──────────────────────────────────┘
```

---

## Drift de Configuracao

**Drift** (ou dissonancia) e a divergencia entre o estado desejado (Git) e o estado real (cluster). E o principal problema que o GitOps busca resolver.

### Causas comuns de drift

| Causa | Exemplo |
|-------|---------|
| Alteracao manual | `kubectl edit deployment` diretamente no cluster |
| Escalas manuais | `kubectl scale --replicas=10` sem atualizar o Git |
| Hotfixes de emergencia | Mudar imagem do container sem commit |
| Configuracoes de debug | Adicionar variaveis de ambiente temporarias |
| Atualizacoes de seguranca | Patches aplicados diretamente no cluster |

### Consequencias do drift

- **Inconsistencia:** cluster nao corresponde ao que esta documentado
- **Irreproducibilidade:** impossivel recriar o ambiente a partir do Git
- **Risco de rollback:** reverter para o Git pode quebrar algo que depende da alteracao manual
- **Perda de controle:** ninguem sabe exatamente o que esta rodando

### Como GitOps trata o drift

No modelo GitOps, o drift e **automaticamente detectado e corrigido**:

```
1. Ferramenta GitOps monitora o repositorio Git
2. Compara estado do Git com estado do cluster
3. Detecta divergencia (drift)
4. Aplica correcao automatica (reconciliacao)
5. Cluster volta a refletir o Git
```

A regra e clara: **o Git sempre vence**. Qualquer alteracao que nao esteja no Git sera revertida.

---

## Reconciliacao Continua

Reconciliacao e o processo pelo qual a ferramenta GitOps **continuamente compara e corrige** o estado do cluster para que corresponda ao que esta definido no Git.

### Fluxo de reconciliacao

```
┌───────────────────────────────────────────────────────────────┐
│                  Ciclo de Reconciliacao                        │
│                                                               │
│    ┌─────────┐    Observa     ┌─────────────┐               │
│    │  Git    │◄──────────────│  Ferramenta  │               │
│    │  (YAML) │                │  GitOps      │               │
│    └─────────┘                │  (Argo CD)   │               │
│         │                     └──────┬───────┘               │
│         │                            │                        │
│         │    Compara                 │  Compara               │
│         │                            │                        │
│         │                     ┌──────▼───────┐               │
│         └────────────────────>│   Cluster    │               │
│                               │  Kubernetes  │               │
│              Aplica correcao  │              │               │
│              se houver drift  └──────────────┘               │
│                                                               │
│    Intervalo tipico: a cada 3 minutos (configuravel)         │
└───────────────────────────────────────────────────────────────┘
```

### Etapas da reconciliacao

1. **Observacao:** a ferramenta GitOps faz polling no repositorio Git (ou recebe webhook de mudanca)
2. **Comparacao:** compara o estado definido no Git com o estado atual do cluster
3. **Deteccao:** identifica diferencas (drift) entre os dois estados
4. **Correcao:** aplica as mudancas necessarias para que o cluster volte ao estado desejado
5. **Verificacao:** confirma que o estado real agora corresponde ao desejado

### Reconciliacao nao e apenas deploy

E importante entender que reconciliacao **nao acontece apenas quando ha novos commits**. Ela tambem atua quando:

- Alguem deleta um recurso manualmente no cluster
- Alguem altera configuracoes diretamente
- Um recurso falha e precisa ser recriado
- O cluster e reconstruido do zero

---

## Pull-based vs Push-based Delivery

Existem dois modelos para aplicar mudancas em um cluster Kubernetes. GitOps favorece o modelo **pull-based**.

### Push-based (tradicional)

No modelo push-based, uma pipeline de CI/CD **envia (push)** as mudancas para o cluster:

```
┌──────────┐     ┌──────────┐     ┌──────────────┐
│  Git     │────>│  CI/CD   │────>│  Cluster     │
│  (commit)│     │  Pipeline│     │  Kubernetes  │
└──────────┘     └──────────┘     └──────────────┘
                      │
                      │  kubectl apply (push)
                      │  ou helm upgrade
                      ▼
               O pipeline tem
               credenciais do cluster
```

### Pull-based (GitOps)

No modelo pull-based, um agente **dentro do cluster puxa (pull)** as mudancas do Git:

```
┌──────────┐                      ┌──────────────────┐
│  Git     │◄─────────────────────│  Cluster         │
│  (commit)│     Observa (pull)   │  Kubernetes      │
└──────────┘                      │                  │
                                  │  ┌────────────┐  │
                                  │  │ Agente     │  │
                                  │  │ GitOps     │  │
                                  │  │ (Argo CD)  │  │
                                  │  └────────────┘  │
                                  └──────────────────┘
```

### Tabela comparativa

| Aspecto | Push-based | Pull-based (GitOps) |
|---------|-----------|---------------------|
| **Direcao** | Pipeline envia para o cluster | Cluster puxa do Git |
| **Credenciais** | Pipeline precisa de acesso ao cluster | Agente ja esta dentro do cluster |
| **Seguranca** | Credenciais expostas no CI/CD | Credenciais confinadas ao cluster |
| **Reconciliacao** | Acontece apenas no deploy | Continua (a cada poucos minutos) |
| **Drift** | Nao detecta drift pos-deploy | Detecta e corrige automaticamente |
| **Complexidade** | Pipeline precisa gerenciar kubeconfig | Agente gerencia internamente |
| **Exemplo** | GitHub Actions + kubectl apply | Argo CD, Flux CD |

### Por que pull-based e preferido

- **Seguranca:** o cluster nao precisa expor credenciais para sistemas externos
- **Resiliencia:** se o CI/CD falhar, o agente dentro do cluster continua reconciliando
- **Consistencia:** drift e detectado e corrigido continuamente, nao apenas durante deploys

---

## YAML como Codigo Versionado

No GitOps, os arquivos YAML do Kubernetes sao tratados com o mesmo rigor que codigo-fonte de aplicacoes.

### O que isso significa na pratica

| Pratica de codigo | Aplicacao em YAML GitOps |
|-------------------|--------------------------|
| Versionamento | YAMLs armazenados no Git com historico completo |
| Code review | Pull Requests para qualquer mudanca de configuracao |
| Testes | Validacao automatica (linting, schema validation) |
| Branches | Feature branches para mudancas em configuracao |
| Tags/Releases | Versoes de configuracao marcadas com tags |
| Rollback | `git revert` para voltar a configuracao anterior |

### Exemplo de estrutura de repositorio GitOps

```
gitops-repo/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── production/
│       └── kustomization.yaml
└── README.md
```

### Beneficio: rollback simplificado

Em caso de problema, basta reverter o commit no Git:

```bash
# Identificar o commit problematico
git log --oneline

# Reverter para o estado anterior
git revert abc1234

# A ferramenta GitOps aplica automaticamente a reversao no cluster
```

---

## Por que kubectl apply Manual nao e GitOps

Muitas equipes acreditam que usar `kubectl apply -f` ja e GitOps, mas isso **nao e verdade**.

### O que acontece com kubectl apply manual

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Git     │────>│  Operador    │────>│  Cluster     │
│  (YAML)  │     │  (humano)    │     │  Kubernetes  │
└──────────┘     │              │     └──────────────┘
                 │ kubectl apply│
                 │ (manual)     │
                 └──────────────┘
```

### Problemas dessa abordagem

| Problema | Descricao |
|----------|-----------|
| **Depende de acao humana** | Alguem precisa lembrar de executar o comando |
| **Sem reconciliacao** | Se alguem alterar o cluster manualmente, ninguem percebe |
| **Sem deteccao de drift** | Nao ha verificacao continua do estado |
| **Falha humana** | Operador pode aplicar YAML errado ou da branch errada |
| **Sem automacao** | Nao ha garantia de que o cluster reflete o Git |
| **Falta de controle** | Operador pode aplicar mudancas sem passar por PR |

### Diferenca entre kubectl apply e GitOps real

| Aspecto | kubectl apply (manual) | GitOps real |
|---------|----------------------|-------------|
| **Quem aplica** | Humano | Ferramenta automatizada |
| **Quando aplica** | Quando alguem lembra | Continuamente |
| **Detecta drift** | Nao | Sim |
| **Corrige drift** | Nao | Sim (automaticamente) |
| **Garantia de estado** | Nenhuma | Git sempre reflete o cluster |
| **Dependencia humana** | Total | Minima |

### O que falta para ser GitOps

Para que o fluxo seja considerado GitOps de verdade, e necessario:

1. Uma **ferramenta dentro do cluster** (ex: Argo CD, Flux) que observe o Git
2. **Reconciliacao automatica** e continua
3. **Deteccao e correcao de drift** sem intervencao humana
4. Git como **unica forma** de alterar o estado do cluster

---

## Kubernetes ja e Declarativo - GitOps Complementa

Um ponto fundamental e entender que Kubernetes **ja opera de forma declarativa**. GitOps nao substitui isso, mas **complementa e estende** esse modelo.

### O que Kubernetes ja faz sozinho

O Kubernetes possui controladores internos que garantem reconciliacao:

- Se um pod morre, o ReplicaSet cria outro
- Se um node falha, os pods sao reagendados em outro node
- Se a configuracao de um Deployment muda, o rollout e executado

### O que Kubernetes nao faz sozinho

- Nao garante que o cluster corresponde ao que esta no Git
- Nao impede alteracoes manuais via `kubectl`
- Nao detecta drift entre o repositorio e o cluster
- Nao reconcilia automaticamente com uma fonte externa

### Como GitOps complementa

```
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│   Kubernetes nativo:                                         │
│   - Reconcilia estado INTERNO (pods, replicas, scheduling)  │
│   - Garante que o cluster mantem o que foi aplicado         │
│                                                              │
│   GitOps adiciona:                                           │
│   - Reconcilia estado EXTERNO (Git vs Cluster)              │
│   - Garante que o cluster reflete o repositorio             │
│   - Detecta e corrige drift                                 │
│   - Adiciona governanca, auditoria e rastreabilidade        │
│                                                              │
│   Juntos:                                                    │
│   - Sistema completo de gerenciamento de estado             │
│   - Interno (K8s) + Externo (GitOps)                        │
│   - Maximo controle e previsibilidade                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Tabela resumo: Kubernetes vs Kubernetes + GitOps

| Capacidade | Kubernetes Nativo | Kubernetes + GitOps |
|-----------|------------------|---------------------|
| Reconciliacao interna de pods | Sim | Sim |
| Reconciliacao com repositorio Git | Nao | Sim |
| Deteccao de drift externo | Nao | Sim |
| Rollback via Git | Nao | Sim |
| Auditoria completa de mudancas | Parcial (events) | Completa (Git history) |
| Prevencao de alteracoes manuais | Nao | Sim (sobrescreve) |
| Governanca via Pull Requests | Nao | Sim |

---

## Resumo Geral

### Conceitos-chave da Aula 1

| Conceito | Definicao |
|----------|-----------|
| **GitOps** | Modelo operacional com Git como fonte unica da verdade |
| **Fonte da verdade** | Repositorio Git define todo o estado do sistema |
| **Declarativo** | Descrever o que voce quer, nao como chegar la |
| **IaC** | Infraestrutura definida em codigo versionado (Terraform, etc.) |
| **Governanca** | Controle de mudancas via PRs, revisao e aprovacao |
| **Rastreabilidade** | Historico completo de quem mudou o que e quando |

### Conceitos-chave da Aula 2

| Conceito | Definicao |
|----------|-----------|
| **Estado desejado** | Configuracao definida nos YAMLs armazenados no Git |
| **Estado real** | O que efetivamente esta rodando no cluster |
| **Drift** | Divergencia entre estado desejado e estado real |
| **Reconciliacao** | Processo continuo de convergencia do cluster para o Git |
| **Pull-based** | Cluster puxa mudancas do Git (modelo preferido) |
| **Push-based** | Pipeline envia mudancas para o cluster (modelo tradicional) |

### Regras centrais do GitOps

1. **Git e a unica fonte da verdade** - toda configuracao vive no repositorio
2. **Mudancas so via Git** - nunca alterar o cluster diretamente
3. **Reconciliacao continua** - o cluster sempre converge para o Git
4. **Pull-based e preferido** - agente dentro do cluster puxa do Git
5. **YAML e codigo** - tratar configuracoes com o mesmo rigor de codigo-fonte
6. **Drift e automaticamente corrigido** - alteracoes manuais sao sobrescritas

---

## Proximos Passos

Com os fundamentos teoricos cobertos nestas duas aulas, as proximas aulas introduzirao ferramentas praticas para implementar GitOps no Kubernetes, com destaque para o **Argo CD** como agente de reconciliacao continua.
