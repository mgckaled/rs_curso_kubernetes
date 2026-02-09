<!-- markdownlint-disable -->

# ApplicationSet do Argo CD - Aula 9

Documentacao sobre o recurso ApplicationSet do Argo CD, que permite
gerar multiplas Applications automaticamente a partir de templates
e geradores. Este documento cobre o problema que o ApplicationSet
resolve, a logica de generators e templates, o generator "list",
variaveis de template, erros comuns e a comparacao com Applications
individuais.

---

## Indice

1. [O que e ApplicationSet](#o-que-e-applicationset)
2. [Problema que o ApplicationSet Resolve](#problema-que-o-applicationset-resolve)
3. [Analogia: Generator e Template](#analogia-generator-e-template)
4. [Generator "list"](#generator-list)
5. [Variaveis de Template](#variaveis-de-template)
6. [SyncPolicy no ApplicationSet](#syncpolicy-no-applicationset)
7. [CRDs do Argo CD](#crds-do-argo-cd)
8. [Erro Comum: "duplicate name"](#erro-comum-duplicate-name)
9. [Outros Generators](#outros-generators)
10. [Exemplo YAML Completo](#exemplo-yaml-completo)
11. [Tabela Comparativa: Application vs ApplicationSet](#tabela-comparativa-application-vs-applicationset)
12. [Resumo](#resumo)
13. [Referencias](#referencias)

---

## O que e ApplicationSet

O **ApplicationSet** e um recurso (CRD) do Argo CD que funciona
como um **orquestrador de Applications**. Em vez de criar cada
Application manualmente (uma por uma), voce define um
ApplicationSet que **gera automaticamente** multiplas Applications
a partir de um template e um conjunto de parametros.

O ApplicationSet e gerenciado pelo componente
`argocd-applicationset-controller`, que roda como um Deployment
dentro do namespace `argocd`.

### Fluxo de funcionamento

```
+----------------------------+
|      ApplicationSet        |
|  (1 recurso YAML)          |
|                            |
|  Generator: lista de       |
|  parametros (dev, stg, prd)|
|                            |
|  Template: modelo de       |
|  Application com variaveis |
+------+---------------------+
       |
       | gera automaticamente
       |
       v
+------+-----+------+-----+------+-----+
|  App dev   |  App stg   |  App prd   |
|  (gerada)  |  (gerada)  |  (gerada)  |
+------------+------------+------------+
```

---

## Problema que o ApplicationSet Resolve

Sem ApplicationSet, o modelo do Argo CD e **1:1**: cada deploy
requer a criacao manual de uma Application. Isso funciona bem
para poucos deploys, mas **nao escala**.

### Cenario sem ApplicationSet

Imagine que voce precisa fazer deploy da mesma aplicacao em tres
ambientes (dev, staging, producao), cada um em um cluster ou
namespace diferente. Voce precisaria criar tres arquivos YAML
praticamente identicos:

```
application-dev.yaml      (muda: name, namespace, cluster)
application-staging.yaml   (muda: name, namespace, cluster)
application-prod.yaml      (muda: name, namespace, cluster)
```

### Problemas desse modelo

| Problema | Descricao |
|----------|-----------|
| **Duplicacao** | 95% do YAML e identico, so mudam 2-3 campos |
| **Manutencao** | Alterar a branch ou o path exige editar todos os arquivos |
| **Erro humano** | Facil esquecer de atualizar um dos arquivos |
| **Escalabilidade** | Com 10 ambientes ou 20 microservicos, a quantidade de YAMLs explode |

### Cenario com ApplicationSet

Com um unico ApplicationSet, voce define o template uma vez e
lista os parametros que variam. O Argo CD gera as Applications
automaticamente:

```
applicationset.yaml  -->  gera 3 Applications automaticamente
  (1 arquivo)              (dev, staging, prod)
```

---

## Analogia: Generator e Template

Para facilitar o entendimento, pense no ApplicationSet como
um **loop de programacao**:

### Generator = "for each"

O generator define **sobre quais elementos** o Argo CD deve
iterar. E equivalente ao `for each` de uma linguagem de
programacao. Cada elemento do generator e um conjunto de
variaveis que sera injetado no template.

### Template = modelo com variaveis

O template define o **formato da Application** que sera gerada,
usando variaveis que serao substituidas pelos valores do
generator.

### Pseudocodigo equivalente

```
// Generator (lista de elementos)
ambientes = [
  { cluster: "dev",     url: "https://172.18.0.3:6443", namespace: "app-dev"  },
  { cluster: "staging", url: "https://172.18.0.4:6443", namespace: "app-stg"  },
  { cluster: "prod",    url: "https://172.18.0.5:6443", namespace: "app-prod" },
]

// Template (modelo da Application)
for each ambiente in ambientes:
  criar Application:
    name:      "demo-app-{ambiente.cluster}"
    server:    ambiente.url
    namespace: ambiente.namespace
    repoURL:   "https://github.com/usuario/repo.git"
    path:      "k8s/manifests"
```

Esse pseudocodigo geraria tres Applications com nomes e destinos
diferentes, todas baseadas no mesmo template.

---

## Generator "list"

O generator mais simples e direto e o **list**. Ele define uma
**lista fixa de elementos**, onde cada elemento e um conjunto
de pares chave-valor que serao usados como variaveis no template.

### Estrutura do generator list

```yaml
generators:
  # O generator "list" itera sobre uma lista fixa de elementos
  - list:
      elements:
        # Primeiro elemento: ambiente de desenvolvimento
        - cluster: dev
          url: https://172.18.0.3:6443
          namespace: app-dev
        # Segundo elemento: ambiente de staging
        - cluster: staging
          url: https://172.18.0.4:6443
          namespace: app-stg
        # Terceiro elemento: ambiente de producao
        - cluster: prod
          url: https://172.18.0.5:6443
          namespace: app-prod
```

### Como funciona

1. O Argo CD le a lista de `elements`
2. Para cada elemento, substitui as variaveis no template
3. Gera uma Application para cada elemento
4. No exemplo acima: 3 elementos = 3 Applications geradas

### Quando usar o generator list

- Numero pequeno e fixo de destinos (clusters, ambientes)
- Quando os parametros nao mudam frequentemente
- Cenarios simples de multi-cluster ou multi-namespace
- Aprendizado e prototipacao

---

## Variaveis de Template

As variaveis de template sao definidas pelo generator e
referenciadas no template usando a sintaxe de duplas chaves:
`{{variavel}}`.

### Sintaxe

```yaml
# No generator, cada chave se torna uma variavel
elements:
  - cluster: dev       # {{cluster}} = "dev"
    url: https://...   # {{url}} = "https://..."
    namespace: app-dev # {{namespace}} = "app-dev"

# No template, as variaveis sao substituidas
template:
  metadata:
    name: 'demo-app-{{cluster}}'    # Resultado: "demo-app-dev"
  spec:
    destination:
      server: '{{url}}'             # Resultado: "https://..."
      namespace: '{{namespace}}'    # Resultado: "app-dev"
```

### Variaveis comuns

| Variavel | Uso tipico | Exemplo de valor |
|----------|-----------|-----------------|
| `{{cluster}}` | Nome do cluster de destino | `dev`, `staging`, `prod` |
| `{{url}}` | URL do API server do cluster | `https://172.18.0.3:6443` |
| `{{namespace}}` | Namespace de destino | `app-dev`, `app-prod` |

### Regra importante

Toda chave definida no generator **deve** ser usada no template.
Se voce definir uma chave `cluster` no generator mas nao usar
`{{cluster}}` no template, ela sera ignorada (sem erro, mas
desperdicio).

Da mesma forma, se voce referenciar `{{variavel}}` no template
mas essa chave nao existir no generator, o Argo CD **nao**
substituira o valor (fica como texto literal).

---

## SyncPolicy no ApplicationSet

O ApplicationSet herda o mesmo conceito de `syncPolicy` das
Applications individuais. Dentro do template, voce define como
cada Application gerada deve se comportar em relacao a
sincronizacao.

### Opcoes de syncPolicy

```yaml
template:
  spec:
    syncPolicy:
      automated:
        # selfHeal: reverte alteracoes manuais feitas no cluster
        # Se alguem fizer kubectl edit/scale diretamente,
        # o Argo CD desfaz a mudanca para corresponder ao Git
        selfHeal: true
        # prune: remove recursos que nao existem mais no Git
        # Se voce deletar um Service do repositorio,
        # o Argo CD tambem deleta o Service do cluster
        prune: true
```

### selfHeal em detalhe

| Cenario | Sem selfHeal | Com selfHeal |
|---------|-------------|-------------|
| Alguem executa `kubectl scale --replicas=10` | Fica com 10 replicas (drift) | Argo CD reverte para o valor do Git |
| Alguem edita um ConfigMap manualmente | Mudanca persiste | Argo CD sobrescreve com o valor do Git |
| Alguem deleta um Pod | Kubernetes recria (ReplicaSet) | Mesmo comportamento (Kubernetes ja cuida) |

### prune em detalhe

| Cenario | Sem prune | Com prune |
|---------|----------|----------|
| YAML de um Service e removido do Git | Service permanece no cluster (orfao) | Argo CD deleta o Service do cluster |
| Namespace inteiro e removido do Git | Recursos permanecem | Argo CD limpa os recursos |

---

## CRDs do Argo CD

O Argo CD registra tres CRDs (Custom Resource Definitions) no
cluster. E importante conhece-los para entender a hierarquia de
recursos.

| CRD | apiVersion | Descricao |
|-----|-----------|-----------|
| `applications.argoproj.io` | `argoproj.io/v1alpha1` | Define uma unica aplicacao gerenciada (source + destination + syncPolicy) |
| `applicationsets.argoproj.io` | `argoproj.io/v1alpha1` | Gera multiplas Applications a partir de generators e templates |
| `appprojects.argoproj.io` | `argoproj.io/v1alpha1` | Agrupa Applications e define politicas de acesso (repositorios, clusters, namespaces permitidos) |

### Hierarquia de recursos

```
AppProject (governanca)
  |
  +-- ApplicationSet (orquestrador)
  |     |
  |     +-- Application (gerada automaticamente)
  |     +-- Application (gerada automaticamente)
  |     +-- Application (gerada automaticamente)
  |
  +-- Application (criada manualmente)
```

### Comandos para verificar os CRDs

```bash
# Listar CRDs do Argo CD
kubectl get crd | grep argoproj

# Listar todas as Applications
kubectl get applications -n argocd

# Listar todos os ApplicationSets
kubectl get applicationsets -n argocd

# Listar todos os AppProjects
kubectl get appprojects -n argocd
```

---

## Erro Comum: "duplicate name"

Um erro frequente ao criar ApplicationSets e o **"duplicate name"**.
Isso acontece quando o template gera Applications com o mesmo nome.

### Causa do erro

Se voce usar um nome fixo (sem variavel) no template, todas as
Applications geradas terao o mesmo nome, o que causa conflito:

```yaml
# ERRADO: nome fixo causa duplicacao
template:
  metadata:
    name: demo-app  # Todas as Applications geradas terao esse nome
```

### Mensagem de erro tipica

```
error: admission webhook "applicationsets.argoproj.io" denied the request:
  application "demo-app" already exists
```

### Solucao: usar variaveis no name

```yaml
# CORRETO: variavel garante nomes unicos
template:
  metadata:
    name: 'demo-app-{{cluster}}'  # Gera: demo-app-dev, demo-app-staging, demo-app-prod
```

### Regra

O campo `metadata.name` do template **deve** conter pelo menos
uma variavel que garanta unicidade entre os elementos do generator.
Cada Application gerada precisa de um nome unico no namespace.

---

## Outros Generators

Alem do generator **list**, o ApplicationSet suporta outros tipos
de generators para cenarios mais avancados. Aqui uma visao geral
dos principais:

| Generator | Descricao | Caso de uso |
|-----------|-----------|-------------|
| **list** | Lista fixa de elementos com variaveis | Multi-cluster simples, poucos destinos |
| **cluster** | Gera uma Application para cada cluster registrado no Argo CD | Automatizar deploy em novos clusters adicionados |
| **git (directories)** | Gera uma Application para cada diretorio em um caminho do repositorio | Mono-repo com varios microservicos em diretorios separados |
| **git (files)** | Gera uma Application para cada arquivo JSON/YAML em um caminho do repositorio | Configuracoes externalizadas em arquivos individuais |
| **matrix** | Combina dois generators (produto cartesiano) | Todas as combinacoes de clusters x aplicacoes |
| **merge** | Combina generators com sobreposicao seletiva | Valores padrao com excecoes por ambiente |
| **pull request** | Gera Applications para cada Pull Request aberto | Preview environments automaticos |

### Generator "cluster"

Particularmente util: ao registrar um novo cluster no Argo CD
com `argocd cluster add`, o generator "cluster" automaticamente
gera uma Application para esse cluster, sem necessidade de editar
o ApplicationSet.

### Generator "git (directories)"

Ideal para mono-repos onde cada microservico tem seu proprio
diretorio:

```
repo/
├── microservico-a/
│   ├── deployment.yaml
│   └── service.yaml
├── microservico-b/
│   ├── deployment.yaml
│   └── service.yaml
└── microservico-c/
    ├── deployment.yaml
    └── service.yaml
```

O generator leria os diretorios e geraria uma Application para
cada um (`microservico-a`, `microservico-b`, `microservico-c`).

---

## Exemplo YAML Completo

Abaixo, um ApplicationSet completo com comentarios explicativos
em cada linha:

```yaml
# apiVersion do ApplicationSet (mesmo grupo do Application)
apiVersion: argoproj.io/v1alpha1
# Tipo do recurso: ApplicationSet
kind: ApplicationSet
metadata:
  # Nome do ApplicationSet (unico no namespace)
  name: demo-app-set
  # Namespace onde o Argo CD esta instalado
  namespace: argocd
spec:
  generators:
    # Generator do tipo "list": lista fixa de elementos
    - list:
        elements:
          # Primeiro elemento: ambiente de desenvolvimento
          - cluster: dev
            url: https://kubernetes.default.svc
            namespace: app-dev
          # Segundo elemento: ambiente de staging
          - cluster: staging
            url: https://kubernetes.default.svc
            namespace: app-staging
          # Terceiro elemento: ambiente de producao
          - cluster: prod
            url: https://kubernetes.default.svc
            namespace: app-prod
  template:
    metadata:
      # Nome da Application gerada (variavel garante unicidade)
      name: 'demo-app-{{cluster}}'
    spec:
      # Projeto do Argo CD ao qual a Application pertence
      project: default
      source:
        # URL do repositorio Git contendo os manifests
        repoURL: https://github.com/seu-usuario/seu-repo.git
        # Branch ou tag a ser monitorada
        targetRevision: main
        # Caminho dentro do repositorio onde estao os YAMLs
        path: k8s/manifests
      destination:
        # URL do cluster de destino (vem do generator)
        server: '{{url}}'
        # Namespace de destino (vem do generator)
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          # Remover recursos que nao existem mais no Git
          prune: true
          # Reverter alteracoes manuais feitas no cluster
          selfHeal: true
        syncOptions:
          # Criar o namespace automaticamente se nao existir
          - CreateNamespace=true
```

### O que esse ApplicationSet gera

Ao aplicar o YAML acima, o Argo CD cria automaticamente tres
Applications:

| Application gerada | Cluster destino | Namespace destino |
|--------------------|-----------------|-------------------|
| `demo-app-dev` | `https://kubernetes.default.svc` | `app-dev` |
| `demo-app-staging` | `https://kubernetes.default.svc` | `app-staging` |
| `demo-app-prod` | `https://kubernetes.default.svc` | `app-prod` |

### Aplicar o ApplicationSet

```bash
# Aplicar o ApplicationSet
kubectl apply -f applicationset.yaml

# Verificar as Applications geradas
kubectl get applications -n argocd

# Verificar o ApplicationSet
kubectl get applicationsets -n argocd
```

---

## Tabela Comparativa: Application vs ApplicationSet

| Aspecto | Application | ApplicationSet |
|---------|-------------|----------------|
| **Escopo** | 1 deploy (1 source -> 1 destination) | N deploys (1 template -> N Applications) |
| **Criacao** | Manual (1 YAML por deploy) | Automatica (generator + template) |
| **Escalabilidade** | Nao escala (duplicacao de YAMLs) | Escala naturalmente (adicionar elemento ao generator) |
| **Manutencao** | Editar cada YAML individualmente | Editar o template uma vez, todas as Applications atualizam |
| **Variaveis** | Nao suporta | Suporta via `{{variavel}}` |
| **Generators** | Nao aplica | list, cluster, git, matrix, merge, pull request |
| **Caso de uso** | Aplicacao unica em um unico destino | Multi-cluster, multi-namespace, mono-repo |
| **CRD** | `applications.argoproj.io` | `applicationsets.argoproj.io` |
| **Controller** | `argocd-application-controller` | `argocd-applicationset-controller` |
| **Quando usar** | Poucos deploys simples | Qualquer cenario com repeticao de padroes |

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **ApplicationSet** | CRD que gera multiplas Applications automaticamente |
| **Generator** | Define os elementos sobre os quais iterar (equivalente a "for each") |
| **Template** | Modelo da Application com variaveis substituiveis |
| **Generator list** | Lista fixa de elementos com pares chave-valor |
| **Variaveis** | Sintaxe `{{chave}}` substituida pelos valores do generator |
| **selfHeal** | Reverte alteracoes manuais no cluster |
| **prune** | Remove recursos do cluster que foram deletados do Git |
| **Erro duplicate name** | Ocorre quando o template nao usa variavel no campo `name` |
| **Outros generators** | cluster, git (directories), git (files), matrix, merge, pull request |

---

## Referencias

- [Argo CD - ApplicationSet Controller](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Argo CD - ApplicationSet Generators](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/)
- [Argo CD - List Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-List/)
- [Argo CD - Git Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/)
- [Argo CD - Cluster Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/)
