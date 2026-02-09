<!-- markdownlint-disable -->

# Nivel 4 - Modulo 1: GitOps e ArgoCD

Projeto didatico completo para aprender GitOps do zero ate Argo CD com organizacao realista de repositorios, governanca e multi-cluster. 100% local com Kind, custo zero.

## Objetivos de Aprendizado

Apos completar este projeto, voce sera capaz de:

- Entender GitOps conceitualmente (fonte da verdade, declarativo vs imperativo)
- Instalar e configurar Argo CD em cluster local
- Criar e gerenciar Applications (CRD principal do Argo CD)
- Operar no dia-a-dia: sync, drift detection, diff, rollback
- Integrar CI com GitOps (simulacao local + referencia GitHub Actions)
- Gerenciar multiplos clusters com ApplicationSet
- Aplicar governanca com Projects, RBAC e Sync Windows

## Arquitetura do Projeto

```plaintext
                    REPOSITORIO GIT (GitHub)
                    +-----------------------------------------+
                    |  n4/m1/b-gitops/                        |
                    |  +-- apps/demo-nginx/                   |
                    |  |   +-- configmap.yaml                 |
                    |  |   +-- deployment.yaml  <------------ | CI simula mudanca
                    |  |   +-- service.yaml                   | de versao via script
                    |  +-- manifests/                         |
                    +-----------------+-----------------------+
                                      |
                            observa (polling ~180s)
                                      |
                    +-----------------v-----------------------+
                    |     Kind Cluster (n4-m1-gitops)          |
                    |     Control Plane Only                    |
                    |                                          |
                    |  +------------------------------------+  |
                    |  |     Namespace: argocd               |  |
                    |  |                                     |  |
                    |  |  argocd-server (UI + API)           |  |
                    |  |  argocd-repo-server                 |  |
                    |  |  argocd-application-controller      |  |
                    |  |  argocd-redis                       |  |
                    |  |  argocd-applicationset-controller   |  |
                    |  +----------------+--------------------+  |
                    |                   | sync                  |
                    |  +----------------v--------------------+  |
                    |  |     Namespace: demo-app              |  |
                    |  |                                      |  |
                    |  |  Deployment: demo-nginx              |  |
                    |  |  Service: demo-nginx                 |  |
                    |  |  ConfigMap: demo-nginx               |  |
                    |  +--------------------------------------+  |
                    +--------------------------------------------+

         (Secao 8: opcional)
                    +--------------------------------------------+
                    |   Kind Cluster (n4-m1-staging)               |
                    |   Control Plane Only                         |
                    |                                              |
                    |  +--------------------------------------+   |
                    |  |     Namespace: demo-app               |   |
                    |  |     (gerenciado pelo Argo CD           |   |
                    |  |      do cluster principal)             |   |
                    |  +--------------------------------------+   |
                    +--------------------------------------------+
```

## Recursos Implementados

| Recurso | Status | Descricao |
|---------|--------|-----------|
| GitOps Conceitual | Documentacao | Fundamentos e teoria |
| Argo CD Instalacao | 100% funcional | Non-HA com resource limits |
| Application CRD | 100% funcional | Sync manual e automatico |
| AutoSync + Drift | 100% funcional | selfHeal e prune |
| Simulacao CI | 100% funcional | Script local de atualizacao |
| Multi-Cluster | Opcional | 2 clusters Kind ou namespaces |
| ApplicationSet | 100% funcional | Generator list multi-cluster |
| Credential Template | Referencia | Exemplo SSH reutilizavel |
| AppProject | 100% funcional | RBAC e Sync Windows |

## Requisitos

### Software

- **Docker Desktop**: 4.0+ com WSL2 habilitado
- **Kind**: v0.20.0+
- **kubectl**: v1.28.0+
- **Bash**: Git Bash no Windows ou terminal WSL
- **argocd CLI** (opcional): Para comandos via terminal

### Hardware

| Componente | Minimo | Recomendado |
|------------|--------|-------------|
| RAM disponivel | 2.0 GB | 2.5 GB |
| CPU | 2 cores | 4 cores |
| Disco | 5 GB | 10 GB |

### Estimativa de Consumo de RAM

| Fase | Componentes | RAM Estimada |
|------|-------------|-------------|
| Secoes 1-3 (conceitual) | Nenhum cluster | 0 MB |
| Secao 4 (instalacao) | Kind CP + Argo CD | ~1.4-2.0 GB |
| Secoes 5-7 (app + CI) | + nginx pod | ~1.5-2.0 GB |
| Secao 8 Opcao A (multi) | + cluster staging | ~2.1-2.4 GB |
| Secao 8 Opcao B (ns) | Sem cluster extra | ~1.5-2.0 GB |
| Secoes 9-11 | 1 cluster + Argo | ~1.5-2.0 GB |

## Estrutura do Projeto

```plaintext
n4/m1/b-gitops/
+-- README.md                               # Este arquivo
+-- manifests/                              # YAMLs do cluster e Argo CD
|   +-- 00-kind-cluster.yaml               # Cluster Kind otimizado
|   +-- 00-kind-cluster-staging.yaml       # Cluster staging (aula 8)
|   +-- 01-namespace-argocd.yaml           # Namespace argocd
|   +-- 02-argocd-resource-patches.yaml    # Patches de resource limits
|   +-- 03-namespace-app.yaml              # Namespace demo-app
|   +-- 04-argocd-repository.yaml          # Secret para repo Git
|   +-- 05-argocd-application.yaml         # Application CRD
|   +-- 06-argocd-application-staging.yaml # Application staging
|   +-- 07-argocd-applicationset.yaml      # ApplicationSet multi-cluster
|   +-- 08-argocd-credential-template.yaml # Credential Template SSH
|   +-- 09-argocd-project.yaml            # AppProject basico
|   +-- 10-argocd-project-restricted.yaml  # AppProject com RBAC
+-- apps/                                   # App demo gerenciada pelo Argo CD
|   +-- demo-nginx/
|       +-- configmap.yaml                 # HTML customizado
|       +-- deployment.yaml                # nginx:1.27-alpine
|       +-- service.yaml                   # ClusterIP:80
+-- docs/                                   # Documentacao por topico
|   +-- 01-fundamentos-gitops.md           # Teoria GitOps (aulas 1-2)
|   +-- 02-argocd-conceitos.md             # Conceitos Argo CD (aula 3)
|   +-- 03-argocd-instalacao.md            # Guia instalacao (aula 4)
|   +-- 04-application-crd.md              # Application explicado (aula 5)
|   +-- 05-operacao-pratica.md             # Sync, Drift, Rollback (aula 6)
|   +-- 06-ci-integrada-gitops.md          # CI + Argo CD (aula 7)
|   +-- 07-multi-cluster.md                # Multi-cluster Kind (aula 8)
|   +-- 08-applicationset.md               # ApplicationSet (aula 9)
|   +-- 09-credential-templates.md         # Credential Templates (aula 10)
|   +-- 10-projects-governanca.md          # Projects e RBAC (aula 11)
|   +-- 11-otimizacao-recursos.md          # Guia RAM otimizada
+-- scripts/                                # Automacao
|   +-- 01-setup-cluster.sh                # Cria cluster + instala Argo CD
|   +-- 02-setup-staging.sh                # Cria cluster staging
|   +-- 03-simulate-ci.sh                  # Simula pipeline CI
|   +-- 04-monitor-argocd.sh               # Monitor em tempo real
|   +-- 05-cleanup.sh                      # Limpeza completa
|   +-- 06-check-resources.sh              # Verifica consumo RAM
+-- reference/
    +-- ci-gitops-workflow.yml             # GitHub Actions (referencia)
```

## Documentacao Complementar

| Documento | Aula(s) | Descricao |
|-----------|---------|-----------|
| [Fundamentos GitOps](docs/01-fundamentos-gitops.md) | 1-2 | Teoria, declarativo vs imperativo, drift |
| [Conceitos Argo CD](docs/02-argocd-conceitos.md) | 3 | Arquitetura, componentes, CRD pattern |
| [Instalacao Argo CD](docs/03-argocd-instalacao.md) | 4 | Tipos de instalacao, componentes, acesso |
| [Application CRD](docs/04-application-crd.md) | 5 | Anatomia, estados, sync policy |
| [Operacao Pratica](docs/05-operacao-pratica.md) | 6 | AutoSync, drift, diff, rollback |
| [CI Integrada](docs/06-ci-integrada-gitops.md) | 7 | Pipeline CI, simulacao local |
| [Multi-Cluster](docs/07-multi-cluster.md) | 8 | Kind staging, registro de clusters |
| [ApplicationSet](docs/08-applicationset.md) | 9 | Generators, templates, multi-deploy |
| [Credential Templates](docs/09-credential-templates.md) | 10 | SSH reutilizavel, delete cascade |
| [Projects e Governanca](docs/10-projects-governanca.md) | 11 | RBAC, Sync Windows, organizacao |
| [Otimizacao de Recursos](docs/11-otimizacao-recursos.md) | - | Resource limits para RAM limitada |

---

## Pratica Passo a Passo

### Secao 1 -- Fundamentos de GitOps (Aula 1)

**Contexto**: GitOps e um paradigma operacional onde o Git e a unica fonte da verdade para o estado da infraestrutura e aplicacoes.

**Objetivo**: Entender os fundamentos de GitOps, declarativo vs imperativo, e o papel do Git como fonte da verdade.

**Conceitos**:

- **GitOps**: modelo operacional onde TODO o estado esta no Git
- **Fonte da verdade**: Git define o que existe, como existe e quando mudou
- **Declarativo**: voce descreve o estado desejado; o sistema converge
- **Imperativo**: voce descreve os passos a executar; sem garantia de convergencia

**O que estudar**: Leia o documento [Fundamentos GitOps](docs/01-fundamentos-gitops.md), secoes sobre GitOps e IaC.

**O que observar**:

- A diferenca entre "fazer uma coisa" (imperativo) e "declarar o que voce quer" (declarativo)
- Como IaC (Terraform, CloudFormation) aplica o mesmo conceito para infraestrutura
- Por que Git e ideal: versionamento, PRs, auditoria, rollback

**Resumo**: GitOps usa Git como fonte unica da verdade. Tudo que nao esta no Git nao e confiavel.

---

### Secao 2 -- GitOps no Kubernetes (Aula 2)

**Contexto**: Kubernetes ja e declarativo (YAMLs), mas sem GitOps, depende de acoes manuais (`kubectl apply`) que nao sao rastreavies.

**Objetivo**: Entender como GitOps se aplica ao Kubernetes e os conceitos de drift e reconciliacao.

**Conceitos**:

- **Estado desejado**: o que esta definido nos YAMLs no Git
- **Estado real**: o que esta rodando no cluster Kubernetes
- **Drift**: divergencia entre Git e cluster (ex: alguem alterou replicas manualmente)
- **Reconciliacao**: processo de convergir o cluster para o estado do Git

**O que estudar**: Leia o documento [Fundamentos GitOps](docs/01-fundamentos-gitops.md), secoes sobre Kubernetes.

**O que observar**:

- `kubectl apply` manual nao tem rastreabilidade (quem aplicou? quando? por que?)
- Pull-based delivery: o cluster PUXA mudancas do Git (mais seguro que push)
- O cluster pode ser reconstruido apenas reaplicando os YAMLs

**Resumo**: GitOps no Kubernetes garante que o cluster sempre reflita o Git, nao o contrario.

---

### Secao 3 -- Argo CD Conceitual (Aula 3)

**Contexto**: Argo CD e a ferramenta que implementa GitOps de forma nativa no Kubernetes, usando CRDs e Controllers.

**Objetivo**: Entender a arquitetura, componentes e conceitos operacionais do Argo CD.

**Conceitos**:

- **CRD** (Custom Resource Definition): estende a API do Kubernetes com novos tipos de recurso
- **Controller**: componente que monitora CRDs e reconcilia estado
- **Application**: CRD principal do Argo CD (define source + destination)
- **ApplicationSet**: gera multiplas Applications automaticamente
- **AppProject**: agrupa Applications com restricoes de governanca

**O que estudar**: Leia o documento [Conceitos Argo CD](docs/02-argocd-conceitos.md).

**O que observar**:

- Argo CD e instalado DENTRO do cluster como qualquer outro workload
- Monitora Git E cluster simultaneamente, corrigindo divergencias
- Modos de sync: manual (usuario decide) vs automatico (Argo decide)
- Argo CD NAO e ferramenta de observabilidade — apenas entrega continua

**Resumo**: Argo CD implementa GitOps como CRD nativo do Kubernetes, com reconciliacao continua.

---

### Secao 4 -- Instalacao do Argo CD (Aula 4)

**Contexto**: Hora de colocar a mao na massa. Vamos criar o cluster Kind e instalar o Argo CD com resource limits otimizados.

**Objetivo**: Instalar Argo CD no cluster local e acessar a interface web.

**Pre-requisitos**: Docker rodando, Kind e kubectl instalados.

#### Passo a passo

**4.1. Verificar recursos da maquina**

```bash
bash scripts/06-check-resources.sh
```

**4.2. Criar cluster e instalar Argo CD (automatizado)**

```bash
bash scripts/01-setup-cluster.sh
```

O script executa: criar cluster Kind, namespace argocd, instalar Argo CD, aplicar patches de resource limits, aguardar pods.

**4.3. Ou passo a passo manual (para aprender cada etapa)**

```bash
# Criar cluster Kind otimizado (1 control-plane, sem workers)
kind create cluster --config manifests/00-kind-cluster.yaml

# Criar namespace dedicado para o Argo CD
kubectl apply -f manifests/01-namespace-argocd.yaml

# Instalar Argo CD (non-HA, com UI)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Aguardar 30 segundos para deployments serem criados
sleep 30

# Verificar CRDs criados pelo Argo CD
kubectl get crd | grep argo
# Esperado: applications.argoproj.io, applicationsets.argoproj.io, appprojects.argoproj.io

# Verificar pods do Argo CD
kubectl get pods -n argocd
# Aguardar todos ficarem Running/Ready (1-3 minutos)
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
```

**4.4. Acessar a UI do Argo CD**

```bash
# Em um terminal separado, iniciar port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Acesse no navegador: `https://localhost:8080`

Aceite o certificado autoassinado (aviso de seguranca e normal em ambiente local).

**4.5. Obter credenciais**

```bash
# Usuario: admin
# Senha: armazenada em um Secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**4.6. Login via CLI (opcional)**

```bash
argocd login localhost:8080 --insecure --username admin --password '<senha-obtida-acima>'
```

**O que observar**:

- Na UI: tela de login, dashboard vazio (nenhuma Application ainda)
- Nos pods: 7 deployments do Argo CD rodando no namespace argocd
- Nos CRDs: 3 novos tipos de recurso (applications, applicationsets, appprojects)

**Erros comuns**:

| Erro | Causa | Solucao |
|------|-------|---------|
| Pods em CrashLoopBackOff | RAM insuficiente | Fechar apps desnecessarias, verificar com `06-check-resources.sh` |
| Port-forward falha | Porta 8080 ocupada | Usar outra porta: `kubectl port-forward svc/argocd-server -n argocd 9090:443` |
| Secret nao encontrado | Argo CD ainda iniciando | Aguardar pods ficarem Ready |
| Timeout no wait | Cluster lento | Aumentar timeout ou verificar logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server` |

**Resumo**: Argo CD instalado no cluster local com UI acessivel em https://localhost:8080.

---

### Secao 5 -- Primeira Application (Aula 5)

**Contexto**: Agora vamos conectar o Argo CD ao repositorio Git e criar a primeira Application para gerenciar o deploy do nginx.

**Objetivo**: Criar uma Application no Argo CD que sincronize manifests do Git para o cluster.

**Pre-requisitos**: Secao 4 concluida, Argo CD rodando, repositorio Git com push feito.

**IMPORTANTE**: Antes de comecar, certifique-se de que os arquivos `apps/demo-nginx/` estejam commitados e enviados para o GitHub:

```bash
git add n4/m1/b-gitops/apps/demo-nginx/
git commit -m "feat(n4-m1): add demo-nginx app for ArgoCD"
git push
```

#### Passo a passo

**5.1. Criar namespace da aplicacao**

```bash
kubectl apply -f manifests/03-namespace-app.yaml
```

**5.2. Registrar repositorio no Argo CD**

```bash
# Para repositorio PUBLICO, basta aplicar o Secret
kubectl apply -f manifests/04-argocd-repository.yaml

# Verificar na UI: Settings -> Repositories
# Status deve ser "Successful"
```

**5.3. Examinar a Application antes de aplicar**

Abra `manifests/05-argocd-application.yaml` e observe:

- `spec.source.repoURL`: URL do seu repositorio GitHub
- `spec.source.path`: caminho dos YAMLs (`n4/m1/b-gitops/apps/demo-nginx`)
- `spec.destination.server`: cluster local (`https://kubernetes.default.svc`)
- `spec.destination.namespace`: namespace de destino (`demo-app`)
- `spec.syncPolicy`: comentado (sync MANUAL inicialmente)

**5.4. Criar a Application**

```bash
kubectl apply -f manifests/05-argocd-application.yaml
```

**5.5. Verificar na UI**

Acesse `https://localhost:8080`. A Application "demo-nginx" aparece com status **OutOfSync** (Git difere do cluster porque ainda nao sincronizamos).

**5.6. Fazer sync manual**

Na UI: clique em "demo-nginx" -> botao "SYNC" -> "SYNCHRONIZE"

Ou via CLI:

```bash
argocd app sync demo-nginx
```

**5.7. Verificar deploy**

```bash
# Verificar pods criados
kubectl get pods -n demo-app

# Verificar todos os recursos
kubectl get all -n demo-app

# Acessar a aplicacao
kubectl port-forward svc/demo-nginx -n demo-app 8081:80
# Acesse: http://localhost:8081
```

**O que observar**:

- Na UI: Application muda de **OutOfSync** para **Synced** e **Healthy**
- Na UI: hierarquia visual Application -> Deployment -> ReplicaSet -> Pod
- No navegador: pagina HTML da demo-nginx com versao "v1"

**Erros comuns**:

| Erro | Causa | Solucao |
|------|-------|---------|
| ComparisonError | Path nao encontrado no repo | Verificar se fez push dos arquivos |
| OutOfSync persistente | Namespace nao existe | Criar namespace manualmente ou usar syncOptions CreateNamespace |
| Repository not found | URL errada ou repo privado | Verificar URL no Secret 04 |

**Resumo**: Primeira Application criada. Argo CD sincroniza YAMLs do Git para o cluster.

---

### Secao 6 -- Operacao Dia-a-Dia (Aula 6)

**Contexto**: Agora que a Application funciona com sync manual, vamos habilitar AutoSync e explorar o dia-a-dia: drift detection, diff e rollback.

**Objetivo**: Operar o Argo CD no dia-a-dia com AutoSync, detectar drift e fazer rollback.

**Pre-requisitos**: Secao 5 concluida, Application "demo-nginx" sincronizada.

#### Passo a passo

**6.1. Habilitar AutoSync**

Edite `manifests/05-argocd-application.yaml` e descomente o bloco `syncPolicy`:

```yaml
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
```

Aplique a mudanca:

```bash
kubectl apply -f manifests/05-argocd-application.yaml
```

**6.2. Testar AutoSync com mudanca no Git**

Altere a versao no ConfigMap (`apps/demo-nginx/configmap.yaml`):

Mude `<div class="version">v1</div>` para `<div class="version">v2</div>`

Faca commit e push:

```bash
git add n4/m1/b-gitops/apps/demo-nginx/configmap.yaml
git commit -m "feat(n4-m1): update demo-nginx to v2"
git push
```

Aguarde ~180 segundos (polling padrao) ou force refresh:

```bash
argocd app get demo-nginx --refresh
```

**6.3. Verificar mudanca aplicada**

```bash
# Port-forward se nao estiver ativo
kubectl port-forward svc/demo-nginx -n demo-app 8081:80
# Acesse http://localhost:8081 -- deve mostrar v2
```

**6.4. Simular drift (mudanca manual no cluster)**

```bash
# Escalar para 3 replicas manualmente (fora do Git)
kubectl scale deployment demo-nginx -n demo-app --replicas=3

# Verificar imediatamente
kubectl get pods -n demo-app
# 3 pods rodando

# Aguardar selfHeal (alguns segundos)
# O Argo CD detecta a divergencia e reverte para 1 replica (valor no Git)
kubectl get pods -n demo-app
# Volta para 1 pod
```

**6.5. Observar diff na UI**

Na UI do Argo CD, clique em "demo-nginx" -> aba "DIFF":

- Mostra a diferenca entre o estado do Git e o estado do cluster
- Util para entender O QUE mudou

**6.6. Testar rollback (via UI)**

Na UI: "demo-nginx" -> "HISTORY AND ROLLBACK" -> selecione uma versao anterior -> "Rollback"

**IMPORTANTE**: Rollback fora do Git gera dissonancia temporaria. O Argo CD ira eventualmente re-sincronizar para o estado do Git. Para um rollback permanente, reverta o commit no Git.

**O que observar**:

- AutoSync aplica mudancas do Git automaticamente (~180s de delay)
- selfHeal reverte qualquer mudanca manual no cluster
- Diff mostra exatamente o que mudou
- Rollback pela UI e temporario; o Git tem precedencia

**Erros comuns**:

| Erro | Causa | Solucao |
|------|-------|---------|
| Mudanca nao detectada | Polling de ~180s | Use `argocd app get <app> --refresh` |
| selfHeal nao funciona | syncPolicy nao aplicada | Verifique se o YAML tem `automated.selfHeal: true` |
| Rollback revertido | AutoSync ativo | Normal: Git tem precedencia sobre rollback manual |

**Resumo**: AutoSync com selfHeal garante que o cluster SEMPRE converge para o Git.

---

### Secao 7 -- CI Integrada ao GitOps (Aula 7)

**Contexto**: Em GitOps, a CI (Continuous Integration) e responsavel por build e push de imagens. O CD (Continuous Delivery) e feito pelo Argo CD. Sao responsabilidades SEPARADAS.

**Objetivo**: Entender a separacao CI/CD em GitOps e simular o fluxo CI localmente.

**Pre-requisitos**: Secao 6 concluida, AutoSync habilitado.

**Conceitos**:

- **CI**: build do codigo -> testes -> gera imagem Docker -> push no registry -> atualiza YAML no Git
- **CD**: Argo CD observa Git -> detecta mudanca no YAML -> sincroniza no cluster
- A CI NAO faz deploy. Apenas atualiza o Git. O Argo CD faz o deploy.

#### Passo a passo

**7.1. Estudar o workflow CI de referencia**

Abra `reference/ci-gitops-workflow.yml` e observe:

- Trigger filtra `paths: src/**` (evita loop infinito)
- Gera tag com SHA do commit (rastreabilidade)
- Atualiza o YAML com `yaml-update-action`
- Commit automatico nao dispara novo build

**7.2. Simular CI localmente**

```bash
# Atualizar versao para v3
bash scripts/03-simulate-ci.sh v3
```

O script: atualiza versao no ConfigMap -> `git add` -> `git commit`

**7.3. Fazer push**

```bash
git push
```

**7.4. Observar deploy automatico**

```bash
# Forcar refresh (ou aguardar ~180s)
argocd app get demo-nginx --refresh

# Verificar app
kubectl port-forward svc/demo-nginx -n demo-app 8081:80
# Acesse http://localhost:8081 -- deve mostrar v3
```

**7.5. Repetir o ciclo**

```bash
bash scripts/03-simulate-ci.sh v4
git push
# Observar novo deploy automatico
```

**O que observar**:

- A CI muda apenas o Git. O Argo CD faz o deploy.
- Cada versao e rastreavel no historico Git
- O fluxo e o mesmo em producao (com GitHub Actions real)

Leitura complementar: [CI Integrada ao GitOps](docs/06-ci-integrada-gitops.md)

**Resumo**: CI e CD sao separados em GitOps. CI atualiza Git. Argo CD (CD) sincroniza.

---

### Secao 8 -- Multi-Cluster (Aula 8)

**Contexto**: Em ambientes reais, voce tem multiplos clusters (producao, staging, homologacao). O Argo CD pode gerenciar TODOS a partir de um unico ponto.

**Objetivo**: Configurar multi-cluster com Argo CD gerenciando um cluster staging.

**Pre-requisitos**: Secao 7 concluida. RAM disponivel: ~2.5 GB para Opcao A.

#### Opcao A -- Dois clusters Kind reais (recomendada)

**A.1. Criar cluster staging**

```bash
bash scripts/02-setup-staging.sh
```

O script: cria cluster staging -> obtem IP real -> registra no Argo CD.

**A.2. Verificar clusters registrados**

```bash
# Listar clusters no Argo CD
argocd cluster list

# Listar contextos kubectl
kubectl config get-contexts
```

**A.3. Criar Application para staging**

Edite `manifests/06-argocd-application-staging.yaml` e substitua `STAGING-CLUSTER-URL` pela URL real exibida pelo script.

```bash
kubectl apply -f manifests/06-argocd-application-staging.yaml
```

**A.4. Verificar na UI**

Acesse `https://localhost:8080` — duas Applications agora: `demo-nginx` (prod) e `demo-nginx-staging`.

#### Opcao B -- Simulacao com namespaces (fallback para RAM limitada)

Se sua maquina nao suporta 2 clusters simultaneamente:

```bash
# Criar namespace staging no cluster existente
kubectl create namespace staging

# Copiar os manifests da app para staging
kubectl apply -f apps/demo-nginx/configmap.yaml -n staging
kubectl apply -f apps/demo-nginx/deployment.yaml -n staging
kubectl apply -f apps/demo-nginx/service.yaml -n staging
```

Crie uma Application manualmente via UI apontando para namespace `staging`.

**O que observar**:

- Argo CD instalado em 1 cluster gerencia N clusters
- Clusters remotos NAO precisam ter Argo instalado
- O problema do modelo 1:1: cada cluster precisa de uma Application separada

Leitura complementar: [Multi-Cluster](docs/07-multi-cluster.md)

**Resumo**: Argo CD gerencia multiplos clusters de um unico ponto. Modelo 1:1 nao escala.

---

### Secao 9 -- ApplicationSet (Aula 9)

**Contexto**: O modelo 1:1 (1 Application por cluster) nao escala. O ApplicationSet resolve isso gerando multiplas Applications automaticamente.

**Objetivo**: Criar um ApplicationSet que faz deploy simultaneo em multiplos clusters.

**Pre-requisitos**: Secao 8 concluida (Opcao A ou B).

#### Passo a passo

**9.1. Verificar CRDs**

```bash
kubectl get crd applicationsets.argoproj.io
```

**9.2. Remover Applications individuais**

Antes de aplicar o ApplicationSet, remova as Applications criadas nas secoes 5 e 8:

```bash
kubectl delete application demo-nginx -n argocd
kubectl delete application demo-nginx-staging -n argocd 2>/dev/null
```

**9.3. Editar o ApplicationSet**

Abra `manifests/07-argocd-applicationset.yaml` e substitua `STAGING-CLUSTER-URL` pela URL real do cluster staging (ou use `https://kubernetes.default.svc` para Opcao B com namespace diferente).

**9.4. Aplicar o ApplicationSet**

```bash
kubectl apply -f manifests/07-argocd-applicationset.yaml
```

**9.5. Verificar Applications geradas**

```bash
# Listar Applications (devem ser 2: demo-nginx-prod e demo-nginx-staging)
kubectl get applications -n argocd

# Listar ApplicationSets
kubectl get applicationsets -n argocd
```

**9.6. Observar na UI**

Duas Applications geradas automaticamente a partir de um unico ApplicationSet.

**O que observar**:

- Um unico YAML gera N Applications
- Variaveis `{{cluster}}` e `{{url}}` sao substituidas pelos valores do generator
- SyncPolicy e aplicada a TODAS as Applications geradas
- Para adicionar um novo cluster: basta adicionar um novo elemento no generator

**Erros comuns**:

| Erro | Causa | Solucao |
|------|-------|---------|
| Duplicate name | Variaveis nao usadas no name | Usar `{{cluster}}` no campo name |
| Application ja existe | Nao removeu Applications anteriores | Deletar Applications individuais |

Leitura complementar: [ApplicationSet](docs/08-applicationset.md)

**Resumo**: ApplicationSet gera multiplas Applications de um unico template. Escala para N clusters.

---

### Secao 10 -- Credential Templates (Aula 10)

**Contexto**: Registrar repositorios um por um no Argo CD nao escala quando voce tem dezenas de repos. Credential Templates resolvem isso.

**Objetivo**: Entender Credential Templates e o comportamento de delete cascade.

**Pre-requisitos**: Secao 9 concluida.

#### Passo a passo

**10.1. Entender o conceito**

Credential Templates sao Secrets com label `argocd.argoproj.io/secret-type: repo-creds` (diferente de `repository`). Funcionam por pattern matching: um template para a organizacao cobre todos os repos.

**10.2. Examinar o template (referencia)**

```bash
# Abra e leia o manifest de referencia
# NOTA: Para repositorios PUBLICOS via HTTPS, templates nao sao necessarios
# Este e um exemplo para repositorios PRIVADOS via SSH
cat manifests/08-argocd-credential-template.yaml
```

**10.3. Testar delete cascade**

```bash
# Deletar Application COM cascade (padrao)
# Remove a Application E os recursos Kubernetes (Deployment, Service, etc)
kubectl delete application demo-nginx-prod -n argocd
# Verificar: pods foram removidos do namespace demo-app
kubectl get pods -n demo-app
```

**10.4. Recriar e testar non-cascade**

```bash
# Recriar via ApplicationSet (que ainda existe)
# O ApplicationSet recria automaticamente

# Ou aplicar manualmente
kubectl apply -f manifests/05-argocd-application.yaml
argocd app sync demo-nginx

# Deletar SEM cascade (apenas Application, recursos permanecem)
argocd app delete demo-nginx --cascade=false -y
# Verificar: pods AINDA existem no namespace demo-app
kubectl get pods -n demo-app
```

**O que observar**:

- **Cascade** (padrao): deletar Application remove tudo do cluster
- **Non-cascade**: deletar Application mantem recursos rodando
- Em producao, non-cascade e util para desacoplar Argo CD sem derrubar a app

Leitura complementar: [Credential Templates](docs/09-credential-templates.md)

**Resumo**: Credential Templates escalam autenticacao. Entenda cascade para nao derrubar producao.

---

### Secao 11 -- Projects e Governanca (Aula 11)

**Contexto**: O project "default" permite tudo. Em producao, voce precisa de restricoes: quais repos, quais clusters, quais namespaces, quem pode fazer sync.

**Objetivo**: Criar AppProjects com governanca, RBAC e Sync Windows.

**Pre-requisitos**: Secao 10 concluida.

#### Passo a passo

**11.1. Verificar project default**

```bash
# O project default permite tudo
argocd proj list
argocd proj get default
```

**11.2. Criar project com restricoes**

```bash
kubectl apply -f manifests/09-argocd-project.yaml
```

Examine o YAML: `sourceRepos` restringe repos, `destinations` restringe clusters/namespaces.

**11.3. Mover Application para o novo project**

Edite `manifests/05-argocd-application.yaml` e mude `project: default` para `project: demo-project`.

```bash
kubectl apply -f manifests/05-argocd-application.yaml
```

**11.4. Testar restricoes**

Tente criar uma Application fora dos limites do project (outro namespace, outro repo). O Argo CD deve rejeitar.

**11.5. Explorar RBAC e Sync Windows (referencia)**

```bash
# Aplicar project com RBAC avancado
kubectl apply -f manifests/10-argocd-project-restricted.yaml

# Verificar restricoes
argocd proj get restricted-project
```

O YAML define:
- **Role read-only**: apenas visualizacao (para desenvolvedores)
- **Role sync-only**: pode sincronizar (para DevOps)
- **Sync Windows**: deploy permitido apenas em horario comercial

**11.6. Reflexao: por que Helm?**

Observe a quantidade de manifests YAML neste projeto. Em producao:
- Dezenas de microservicos
- Cada um com Deployment, Service, ConfigMap, HPA, PDB...
- Duplicacao massiva de YAML

**Helm** resolve isso com templates parametrizados. Sera abordado nos proximos modulos.

**O que observar**:

- Projects isolam Applications por time/ambiente
- RBAC controla quem pode fazer o que
- Sync Windows controlam quando deploys podem acontecer
- Tudo declarado em YAML (GitOps aplicado ao proprio Argo CD)

Leitura complementar: [Projects e Governanca](docs/10-projects-governanca.md)

**Resumo**: Projects aplicam governanca. RBAC controla acesso. Sync Windows controlam timing.

---

## Comandos Uteis

| Comando | Descricao |
|---------|-----------|
| `kubectl get applications -n argocd` | Listar Applications |
| `kubectl get applicationsets -n argocd` | Listar ApplicationSets |
| `kubectl get appprojects -n argocd` | Listar Projects |
| `argocd app list` | Listar apps (via CLI) |
| `argocd app get <app>` | Detalhes de uma app |
| `argocd app get <app> --refresh` | Forcar refresh |
| `argocd app sync <app>` | Sincronizar manualmente |
| `argocd app diff <app>` | Ver diferenca Git vs cluster |
| `argocd app history <app>` | Historico de deploy |
| `argocd app rollback <app> <id>` | Rollback para versao anterior |
| `argocd cluster list` | Listar clusters registrados |
| `argocd proj list` | Listar projects |
| `argocd proj get <proj>` | Detalhes de um project |

## Troubleshooting

| Problema | Causa Provavel | Solucao |
|----------|---------------|---------|
| Pods CrashLoopBackOff | RAM insuficiente | `bash scripts/06-check-resources.sh`, fechar apps |
| Application OutOfSync | Git difere do cluster | Sync manual ou habilitar AutoSync |
| Repository connection failed | URL errada ou repo privado | Verificar Secret em `manifests/04-argocd-repository.yaml` |
| Path does not exist | Arquivos nao commitados | `git push` os YAMLs para o GitHub |
| Port-forward falha | Porta ocupada ou pod reiniciando | Usar porta alternativa, verificar pods |
| Sync lento (~180s) | Polling padrao do Argo CD | `argocd app get <app> --refresh` para forcar |
| selfHeal nao funciona | syncPolicy nao configurada | Verificar `automated.selfHeal: true` no YAML |
| ApplicationSet duplicate name | Variavel nao usada no name | Usar `{{cluster}}` no campo name |

## Limpeza

```bash
# Remover TUDO (clusters Kind)
bash scripts/05-cleanup.sh

# Verificar se foi limpo
kind get clusters
docker ps
```

## Checklist de Validacao

- [ ] Cluster Kind criado e pods do Argo CD rodando
- [ ] UI acessivel em https://localhost:8080
- [ ] Application "demo-nginx" criada e sincronizada
- [ ] App demo acessivel em http://localhost:8081
- [ ] AutoSync habilitado e funcionando
- [ ] Drift detectado e corrigido (selfHeal)
- [ ] Simulacao CI executada (versao atualizada)
- [ ] (Opcional) Cluster staging configurado
- [ ] ApplicationSet gerando multiplas Applications
- [ ] AppProject criado com restricoes
- [ ] Limpeza executada com sucesso

## Conceitos Aprendidos

| Conceito | Descricao |
|----------|-----------|
| GitOps | Git como unica fonte da verdade |
| Declarativo | Descrever o estado desejado, nao os passos |
| Drift | Divergencia entre Git e cluster |
| Reconciliacao | Convergir cluster para o Git |
| Application | CRD principal do Argo CD |
| ApplicationSet | Gera multiplas Applications automaticamente |
| AppProject | Camada de governanca do Argo CD |
| selfHeal | Reverte mudancas manuais no cluster |
| Prune | Remove recursos que nao estao mais no Git |
| Sync Window | Controla quando deploys podem acontecer |

## Proximos Passos

- **Helm**: Templates parametrizados para reduzir duplicacao de YAML
- **Argo Rollouts**: Estrategias de deploy avancadas (blue-green, canary)
- **Sealed Secrets**: Gerenciamento seguro de secrets no Git
- **Argo CD Image Updater**: Atualizar tags de imagem automaticamente

## Referencias

- [Argo CD - Documentacao Oficial](https://argo-cd.readthedocs.io/)
- [Argo CD - GitHub](https://github.com/argoproj/argo-cd)
- [Kind - Documentacao](https://kind.sigs.k8s.io/)
- [GitOps - OpenGitOps](https://opengitops.dev/)
- [CNCF - Argo Project](https://www.cncf.io/projects/argo/)
