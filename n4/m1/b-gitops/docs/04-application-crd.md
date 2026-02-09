<!-- markdownlint-disable -->

# Application CRD do Argo CD - Aula 5

Documentacao detalhada sobre o recurso `Application`, o CRD (Custom Resource Definition) principal do Argo CD. Este material explica cada campo da especificacao, os modos de conexao com repositorios Git, os estados de sincronizacao e os status de saude dos recursos gerenciados.

---

## Indice

1. [O que e uma Application no Argo CD](#o-que-e-uma-application-no-argo-cd)
2. [Anatomia Completa da Application](#anatomia-completa-da-application)
3. [metadata: Identificacao e Comportamento](#metadata-identificacao-e-comportamento)
4. [spec.project: Agrupamento Logico](#specproject-agrupamento-logico)
5. [spec.source: Origem dos Manifests](#specsource-origem-dos-manifests)
6. [spec.destination: Destino no Cluster](#specdestination-destino-no-cluster)
7. [spec.syncPolicy: Politica de Sincronizacao](#specsyncpolicy-politica-de-sincronizacao)
8. [Conexao com Repositorio Git](#conexao-com-repositorio-git)
9. [Estados da Application (Sync Status)](#estados-da-application-sync-status)
10. [Health Status dos Recursos](#health-status-dos-recursos)
11. [Tabela Comparativa: Sync Manual vs Automatico](#tabela-comparativa-sync-manual-vs-automatico)
12. [Exemplo YAML Comentado Completo](#exemplo-yaml-comentado-completo)
13. [Resumo](#resumo)
14. [Referencias](#referencias)

---

## O que e uma Application no Argo CD

A `Application` e o **recurso central** do Argo CD. Ela representa a ligacao entre um repositorio Git (fonte da verdade) e um cluster Kubernetes (destino). Tudo que o Argo CD faz gira em torno deste recurso.

Em termos praticos, uma Application responde a tres perguntas fundamentais:

| Pergunta | Campo no YAML | Exemplo |
|----------|---------------|---------|
| **De onde vem?** | `spec.source` | Repositorio Git, branch `main`, path `/k8s/manifests` |
| **Para onde vai?** | `spec.destination` | Cluster local, namespace `demo-app` |
| **Como sincronizar?** | `spec.syncPolicy` | Automatico com selfHeal e prune |

A Application e um CRD (Custom Resource Definition) registrado na API do Kubernetes pelo Argo CD. Isso significa que ela e gerenciada como qualquer recurso nativo:

```bash
# Listar todas as Applications
kubectl get applications -n argocd

# Descrever uma Application especifica
kubectl describe application demo-nginx -n argocd

# Criar uma Application a partir de um YAML
kubectl apply -f application.yaml
```

### Application como Controller Pattern

O Argo CD segue o padrao **Controller** do Kubernetes. A Application define o **estado desejado** (quais YAMLs do Git devem estar no cluster). O `argocd-application-controller` observa esse recurso continuamente e age para garantir que o cluster reflita o que esta definido.

```
┌────────────────────────┐         ┌──────────────────────────────┐
│  Application (CRD)     │ ------> │  argocd-application-controller│
│                        │         │                              │
│  "Quero os YAMLs do   │         │  1. Le a Application         │
│   path X do repo Y    │         │  2. Clona o repo via         │
│   no namespace Z"     │         │     repo-server              │
│                        │         │  3. Compara Git vs Cluster   │
└────────────────────────┘         │  4. Reconcilia se preciso    │
                                   └──────────────────────────────┘
```

---

## Anatomia Completa da Application

A estrutura geral de uma Application segue este formato:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <nome-da-aplicacao>
  namespace: argocd
  labels:
    <chave>: <valor>
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: <nome-do-project>
  source:
    repoURL: <url-do-repositorio>
    targetRevision: <branch-ou-tag>
    path: <caminho-dentro-do-repo>
  destination:
    server: <url-do-cluster>
    namespace: <namespace-destino>
  syncPolicy:
    automated:
      selfHeal: <true|false>
      prune: <true|false>
    syncOptions:
      - <opcao>=<valor>
```

As secoes a seguir detalham cada bloco.

---

## metadata: Identificacao e Comportamento

O bloco `metadata` define **quem e** a Application e como ela se comporta ao ser deletada.

### Campos do metadata

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `name` | Sim | Nome unico da Application. Aparece na UI do Argo CD e e usado em comandos CLI. |
| `namespace` | Sim | **Deve ser `argocd`**. As Applications sao gerenciadas no namespace onde o Argo CD esta instalado. |
| `labels` | Nao | Pares chave-valor para organizacao e filtragem. Uteis para agrupar Applications por equipe, ambiente ou projeto. |
| `finalizers` | Nao | Lista de finalizers que controlam o comportamento de delecao. |

### name

O nome da Application aparece em varios contextos:

- Na **interface web** (UI) como um card na lista de Applications
- Em **comandos CLI** como `argocd app sync demo-nginx`
- Em **logs** do application-controller para rastreamento

Boas praticas para nomeacao:

- Usar nomes descritivos e curtos (ex: `demo-nginx`, `api-payments`, `frontend-v2`)
- Incluir o ambiente se necessario (ex: `api-payments-staging`, `api-payments-prod`)
- Usar apenas letras minusculas, numeros e hifens (padrao DNS do Kubernetes)

### namespace

O namespace **sempre deve ser `argocd`** (ou o namespace onde o Argo CD esta instalado). Isso porque o `argocd-application-controller` monitora Applications apenas no seu proprio namespace por padrao.

### labels

Labels sao metadados opcionais que facilitam a organizacao:

```yaml
labels:
  project: n4-m1-gitops    # Projeto do curso
  tier: demo                # Tipo: demo, backend, frontend
  team: platform            # Equipe responsavel
  environment: development  # Ambiente: dev, staging, prod
```

Labels permitem filtrar Applications na UI e via CLI:

```bash
# Filtrar por label
kubectl get applications -n argocd -l tier=demo
kubectl get applications -n argocd -l environment=production
```

### finalizers

O finalizer `resources-finalizer.argocd.argoproj.io` e crucial. Ele define o que acontece quando a Application e **deletada**:

| Com finalizer | Sem finalizer |
|---------------|---------------|
| Ao deletar a Application, o Argo CD **remove tambem** todos os recursos Kubernetes que ela gerenciava (Deployments, Services, etc.) | Ao deletar a Application, os recursos Kubernetes continuam existindo no cluster (orfaos) |

Esse comportamento e chamado de **cascade delete**. Em geral, e recomendado manter o finalizer para evitar recursos orfaos.

```yaml
finalizers:
  # Habilita cascade delete (remove recursos ao deletar a Application)
  - resources-finalizer.argocd.argoproj.io
```

---

## spec.project: Agrupamento Logico

O campo `spec.project` define a qual **AppProject** a Application pertence. O AppProject e um recurso do Argo CD que agrupa Applications e define restricoes de seguranca.

### Project default

Toda instalacao do Argo CD cria automaticamente um project chamado `default`. Ele permite:

- Qualquer repositorio Git como source
- Qualquer cluster como destination
- Qualquer namespace como destino
- Qualquer recurso Kubernetes

```yaml
spec:
  project: default  # Sem restricoes (ideal para estudo)
```

### Project customizado

Em ambientes de producao, e recomendado criar projects especificos com restricoes:

```yaml
# Exemplo de AppProject com restricoes
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: equipe-backend
  namespace: argocd
spec:
  # Apenas estes repositorios sao permitidos
  sourceRepos:
    - https://github.com/empresa/backend-manifests.git

  # Apenas estes destinos sao permitidos
  destinations:
    - server: https://kubernetes.default.svc
      namespace: backend-prod
    - server: https://kubernetes.default.svc
      namespace: backend-staging

  # Apenas estes recursos podem ser criados
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
  namespaceResourceWhitelist:
    - group: 'apps'
      kind: Deployment
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
```

### Tabela comparativa: default vs customizado

| Aspecto | Project default | Project customizado |
|---------|-----------------|---------------------|
| Repositorios permitidos | Todos | Lista especifica |
| Clusters permitidos | Todos | Lista especifica |
| Namespaces permitidos | Todos | Lista especifica |
| Recursos permitidos | Todos | Lista especifica |
| Cenario recomendado | Estudo, desenvolvimento | Producao, multi-equipe |
| Seguranca | Minima | Granular |

---

## spec.source: Origem dos Manifests

O bloco `spec.source` define **de onde** o Argo CD busca os manifests YAML. E a conexao com o repositorio Git.

### Campos do source

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `repoURL` | Sim | URL do repositorio Git. Pode ser HTTPS (publico) ou SSH (privado). |
| `targetRevision` | Sim | Branch, tag ou commit SHA a ser observado. |
| `path` | Sim | Caminho dentro do repositorio onde estao os manifests YAML. |

### repoURL

A URL do repositorio Git que contem os manifests Kubernetes. Dois formatos sao suportados:

```yaml
# HTTPS (para repositorios publicos ou com token)
repoURL: https://github.com/usuario/repo.git

# SSH (para repositorios privados com chave SSH)
repoURL: git@github.com:usuario/repo.git
```

O repositorio deve estar **registrado** no Argo CD (via Secret ou pela UI) antes de ser usado em uma Application.

### targetRevision

Define qual **versao** do repositorio o Argo CD deve observar:

| Valor | Descricao | Exemplo |
|-------|-----------|---------|
| `HEAD` | Branch padrao do repositorio (geralmente `main`) | `targetRevision: HEAD` |
| Nome da branch | Branch especifica | `targetRevision: main` |
| Tag | Versao marcada com tag | `targetRevision: v1.2.0` |
| Commit SHA | Commit especifico (fixo) | `targetRevision: abc1234` |

Para ambientes de estudo, `HEAD` ou `main` sao as opcoes mais comuns. Em producao, tags sao preferidas para garantir que versoes especificas sejam implantadas.

### path

O caminho **relativo** dentro do repositorio onde estao os arquivos YAML:

```yaml
# O Argo CD ira aplicar TODOS os .yaml encontrados neste diretorio
path: n4/m1/b-gitops/apps/demo-nginx
```

O Argo CD processa **todos** os arquivos YAML encontrados no path especificado. Nao e necessario listar cada arquivo individualmente.

Estrutura tipica:

```
repositorio/
  └── n4/m1/b-gitops/apps/demo-nginx/    <-- path
      ├── deployment.yaml
      ├── service.yaml
      └── configmap.yaml
```

---

## spec.destination: Destino no Cluster

O bloco `spec.destination` define **para onde** os recursos serao aplicados.

### Campos do destination

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `server` | Sim (ou `name`) | URL do cluster Kubernetes de destino. |
| `name` | Sim (ou `server`) | Nome do cluster registrado no Argo CD (alternativa ao `server`). |
| `namespace` | Sim | Namespace onde os recursos serao criados. |

### server

A URL do cluster de destino. Para o cluster onde o Argo CD esta instalado (in-cluster), usa-se a URL interna do Kubernetes:

```yaml
# Cluster local (onde o Argo CD esta rodando)
server: https://kubernetes.default.svc

# Cluster externo (registrado no Argo CD)
server: https://meu-cluster-prod.exemplo.com:6443
```

A URL `https://kubernetes.default.svc` e o endereco interno do API Server do Kubernetes. O Argo CD usa essa URL para se comunicar com o cluster sem necessidade de configuracao adicional.

### namespace

O namespace onde os recursos Kubernetes serao criados:

```yaml
namespace: demo-app
```

Se o namespace nao existir, o Argo CD **nao o cria automaticamente** por padrao. E necessario:

- Criar o namespace manualmente antes: `kubectl create namespace demo-app`
- Ou habilitar a opcao `CreateNamespace=true` no `syncOptions`

---

## spec.syncPolicy: Politica de Sincronizacao

O bloco `spec.syncPolicy` define **como** o Argo CD reage ao detectar divergencia entre Git e cluster. E a diferenca entre um Argo CD passivo (observa e alerta) e ativo (observa e corrige).

### Sync manual (sem syncPolicy)

Quando o `syncPolicy` e omitido ou nao contem `automated`, o Argo CD opera em modo **manual**:

```yaml
spec:
  # Sem syncPolicy = sync manual
  # O Argo CD detecta drift mas NAO corrige automaticamente
```

No modo manual:

1. Argo CD detecta que Git e cluster estao diferentes
2. Marca a Application como **OutOfSync**
3. Aguarda acao explicita do usuario (botao Sync na UI ou `argocd app sync`)

### Sync automatico (automated)

Quando `automated` esta presente, o Argo CD sincroniza automaticamente:

```yaml
syncPolicy:
  automated:
    selfHeal: true   # Reverte mudancas manuais no cluster
    prune: true      # Remove recursos que nao estao mais no Git
```

#### selfHeal

O `selfHeal` e a capacidade do Argo CD de **reverter alteracoes manuais** feitas diretamente no cluster.

| selfHeal | Comportamento |
|----------|---------------|
| `true` | Se alguem executa `kubectl scale deployment --replicas=10` e o Git define `replicas: 3`, o Argo CD reverte para 3 |
| `false` | Alteracoes manuais permanecem ate o proximo sync explicito |

#### prune

O `prune` controla se o Argo CD **remove** do cluster recursos que foram deletados do Git.

| prune | Comportamento |
|-------|---------------|
| `true` | Se voce remove `service.yaml` do Git, o Argo CD deleta o Service do cluster |
| `false` | Recursos deletados do Git continuam existindo no cluster (orfaos) |

### syncOptions

O `syncOptions` fornece controles adicionais sobre o comportamento de sincronizacao:

```yaml
syncPolicy:
  automated:
    selfHeal: true
    prune: true
  syncOptions:
    # Cria o namespace automaticamente se nao existir
    - CreateNamespace=true
    # Valida os manifests antes de aplicar
    - Validate=true
    # Aplica usando server-side apply (recomendado para CRDs grandes)
    - ServerSideApply=true
    # Substitui recursos ao inves de fazer patch
    - Replace=false
```

| Opcao | Padrao | Descricao |
|-------|--------|-----------|
| `CreateNamespace=true` | `false` | Cria o namespace de destino se nao existir |
| `Validate=true` | `true` | Valida os manifests contra o schema do Kubernetes |
| `ServerSideApply=true` | `false` | Usa server-side apply do Kubernetes (evita conflitos) |
| `PruneLast=true` | `false` | Executa o prune como ultima operacao do sync |
| `ApplyOutOfSyncOnly=true` | `false` | Aplica apenas recursos que mudaram (mais rapido) |

---

## Conexao com Repositorio Git

Para que o Argo CD consiga acessar um repositorio Git, ele precisa estar **registrado**. A forma de registro depende do tipo de repositorio.

### Repositorio publico (HTTPS)

Para repositorios publicos, basta registrar a URL HTTPS. Nenhuma credencial e necessaria:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-meu-projeto
  namespace: argocd
  labels:
    # Label OBRIGATORIA para o Argo CD reconhecer como repositorio
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/usuario/repo.git
```

### Repositorio privado (HTTPS com token)

Para repositorios privados via HTTPS, e necessario um Personal Access Token (PAT):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-privado-https
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/empresa/repo-privado.git
  username: seu-usuario
  password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # GitHub PAT
```

### Repositorio privado (SSH)

Para repositorios privados via SSH, e necessaria uma chave SSH:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-privado-ssh
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: git@github.com:empresa/repo-privado.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...conteudo da chave privada...
    -----END OPENSSH PRIVATE KEY-----
```

### Resumo dos metodos de conexao

| Metodo | URL Format | Credencial | Cenario |
|--------|-----------|------------|---------|
| HTTPS publico | `https://github.com/user/repo.git` | Nenhuma | Projetos open source, estudo |
| HTTPS privado | `https://github.com/user/repo.git` | Username + Token (PAT) | Organizacoes com tokens |
| SSH privado | `git@github.com:user/repo.git` | Chave SSH privada | Organizacoes com SSH |

### Label obrigatoria

A label `argocd.argoproj.io/secret-type: repository` e **obrigatoria** no Secret. Sem ela, o Argo CD nao reconhece o Secret como configuracao de repositorio.

---

## Estados da Application (Sync Status)

O Argo CD classifica cada Application em um **estado de sincronizacao** (sync status) que indica a relacao entre o Git e o cluster.

### Tabela de estados

| Estado | Significado | Quando ocorre |
|--------|-------------|---------------|
| **Synced** | Git e cluster estao identicos | Apos um sync bem-sucedido e sem mudancas pendentes |
| **OutOfSync** | Git e cluster estao diferentes | Apos um novo commit no Git ou uma alteracao manual no cluster |
| **Missing** | Recurso existe no Git mas nao no cluster | Quando o recurso ainda nao foi criado no cluster |
| **Unknown** | Argo CD nao consegue determinar o estado | Problemas de conexao com o repositorio ou com o cluster |

### Fluxo tipico dos estados

```
Application criada
       |
       v
  [OutOfSync]  <-- Git tem YAMLs, cluster esta vazio
       |
   (sync)
       |
       v
   [Synced]  <-- Git e cluster estao iguais
       |
  (novo commit no Git)
       |
       v
  [OutOfSync]  <-- Git mudou, cluster ainda nao
       |
   (sync)
       |
       v
   [Synced]  <-- Cluster atualizado
```

### OutOfSync em detalhe

O estado OutOfSync e o mais importante para entender. Ele ocorre quando:

1. **Novo commit no Git:** alguem atualizou um YAML no repositorio, mas o cluster ainda nao reflete a mudanca
2. **Alteracao manual no cluster:** alguem executou `kubectl edit` ou `kubectl scale` diretamente, criando drift
3. **Recurso deletado do cluster:** um recurso que deveria existir foi removido manualmente

No modo **automatico** (AutoSync habilitado), o Argo CD resolve o OutOfSync sozinho. No modo **manual**, o usuario deve acionar o sync explicitamente.

---

## Health Status dos Recursos

Alem do sync status, o Argo CD monitora o **health status** (status de saude) de cada recurso Kubernetes gerenciado pela Application.

### Tabela de health status

| Status | Significado | Exemplo |
|--------|-------------|---------|
| **Healthy** | O recurso esta funcionando corretamente | Deployment com todas as replicas Ready |
| **Degraded** | O recurso esta parcialmente funcional | Deployment com replicas falhando (CrashLoopBackOff) |
| **Progressing** | O recurso esta em transicao | Deployment em rollout (atualizando pods) |
| **Missing** | O recurso nao existe no cluster | Recurso definido no Git mas nao criado ainda |
| **Suspended** | O recurso esta pausado intencionalmente | Deployment com `spec.paused: true` ou CronJob suspenso |
| **Unknown** | Argo CD nao consegue determinar a saude | Recurso customizado sem health check definido |

### Hierarquia de saude

O health status segue uma hierarquia natural dos recursos Kubernetes. A saude da Application depende da saude dos recursos que ela gerencia:

```
Application (Health: ?)
   |
   +-- Deployment (Health: ?)
   |      |
   |      +-- ReplicaSet (Health: ?)
   |             |
   |             +-- Pod 1 (Running / CrashLoopBackOff)
   |             +-- Pod 2 (Running / Pending)
   |             +-- Pod 3 (Running / Error)
   |
   +-- Service (Health: Healthy)
   |
   +-- ConfigMap (Health: Healthy)
```

A Application e considerada **Healthy** somente quando **todos** os seus recursos estao Healthy. Se qualquer recurso estiver Degraded, a Application inteira e marcada como Degraded.

### Exemplos praticos de health status

| Situacao | Health Status | Explicacao |
|----------|---------------|------------|
| 3/3 pods Running | Healthy | Todas as replicas estao funcionando |
| 2/3 pods Running, 1 CrashLoopBackOff | Degraded | Uma replica esta falhando |
| Rollout em andamento (pods antigos sendo substituidos) | Progressing | Deployment esta atualizando |
| Deployment criado mas nenhum pod agendado | Missing ou Progressing | Aguardando recursos do cluster |
| HPA escalando de 3 para 5 replicas | Progressing | Transicao de escala em andamento |

---

## Tabela Comparativa: Sync Manual vs Automatico

| Aspecto | Sync Manual | Sync Automatico |
|---------|-------------|-----------------|
| **Deteccao de drift** | Sim (Argo CD detecta) | Sim (Argo CD detecta) |
| **Correcao de drift** | Somente por acao humana | Automatica (com selfHeal) |
| **Novo commit no Git** | Fico OutOfSync ate o usuario sincronizar | Sincroniza automaticamente (~180s) |
| **Mudanca manual no cluster** | Permanece ate o proximo sync | Revertida automaticamente (selfHeal) |
| **Recurso removido do Git** | Permanece no cluster | Removido do cluster (prune) |
| **Controle sobre deploys** | Maximo (aprovacao explicita) | Minimo (automatizado) |
| **Risco de mudancas nao revisadas** | Nenhum | Mitigado por code review no Git |
| **Velocidade de deploy** | Depende do operador | Quase imediata apos o commit |
| **Cenario ideal** | Producao com aprovacao obrigatoria | Desenvolvimento, staging, ambientes de teste |
| **Configuracao YAML** | `syncPolicy` omitido ou vazio | `syncPolicy.automated` com `selfHeal` e `prune` |

---

## Exemplo YAML Comentado Completo

Abaixo esta um exemplo completo de Application com todos os campos explicados:

```yaml
# API version do Argo CD (padrao para todos os CRDs do Argo)
apiVersion: argoproj.io/v1alpha1

# Tipo do recurso: Application (CRD do Argo CD)
kind: Application

metadata:
  # Nome da Application (aparece na UI e nos comandos CLI)
  name: demo-nginx

  # Namespace OBRIGATORIO: deve ser o namespace do Argo CD
  namespace: argocd

  # Labels para organizacao e filtragem
  labels:
    project: n4-m1-gitops    # Identificador do projeto
    tier: demo                # Tipo da aplicacao
    environment: development  # Ambiente

  # Finalizer para cascade delete
  # Ao deletar a Application, os recursos K8s associados tambem sao removidos
  finalizers:
    - resources-finalizer.argocd.argoproj.io

spec:
  # Project: agrupamento logico com restricoes de seguranca
  # "default" permite qualquer source/destination (sem restricoes)
  project: default

  # SOURCE: de onde vem os manifests YAML
  source:
    # URL do repositorio Git (deve estar registrado no Argo CD)
    repoURL: https://github.com/usuario/repo.git

    # Branch, tag ou commit a observar
    # HEAD = branch padrao (geralmente main)
    targetRevision: HEAD

    # Caminho relativo dentro do repositorio
    # O Argo CD aplica TODOS os .yaml encontrados aqui
    path: n4/m1/b-gitops/apps/demo-nginx

  # DESTINATION: para onde vao os recursos
  destination:
    # URL do cluster de destino
    # "https://kubernetes.default.svc" = cluster local (in-cluster)
    server: https://kubernetes.default.svc

    # Namespace onde os recursos serao criados
    namespace: demo-app

  # SYNC POLICY: como sincronizar
  syncPolicy:
    # Modo automatico: Argo CD sincroniza sem intervencao humana
    automated:
      # selfHeal: reverte mudancas manuais feitas no cluster
      # Se alguem fizer kubectl edit, o Argo CD desfaz a mudanca
      selfHeal: true

      # prune: remove do cluster recursos que nao estao mais no Git
      # Se voce deletar um YAML do Git, o recurso e removido do cluster
      prune: true

    # Opcoes adicionais de sincronizacao
    syncOptions:
      # Cria o namespace automaticamente se nao existir
      - CreateNamespace=true
```

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **Application** | CRD principal do Argo CD que conecta Git (source) ao cluster (destination) |
| **metadata.name** | Nome unico da Application (aparece na UI e CLI) |
| **metadata.namespace** | Deve ser `argocd` (namespace do Argo CD) |
| **metadata.finalizers** | Habilita cascade delete (remove recursos ao deletar Application) |
| **spec.project** | Agrupamento logico com restricoes (`default` = sem restricoes) |
| **spec.source** | Repositorio Git, branch e path dos manifests |
| **spec.destination** | Cluster e namespace de destino |
| **spec.syncPolicy** | Manual (omitido) ou automatico (com selfHeal e prune) |
| **Sync Status** | Synced, OutOfSync, Missing, Unknown |
| **Health Status** | Healthy, Degraded, Progressing, Missing, Suspended, Unknown |
| **Repositorio publico** | Secret com label `argocd.argoproj.io/secret-type: repository` |
| **Repositorio privado** | Secret com token (HTTPS) ou chave SSH |

---

## Referencias

- [Argo CD - Application Specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)
- [Argo CD - Sync Options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [Argo CD - Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [Argo CD - Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [Argo CD - Health Assessment](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/)
