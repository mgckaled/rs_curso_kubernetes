<!-- markdownlint-disable -->

# Multi-Cluster com Argo CD - Aula 8

Documentacao sobre gerenciamento multi-cluster com Argo CD, cobrindo
a arquitetura de um unico Argo CD controlando multiplos clusters,
o registro de clusters externos, os desafios de rede em ambientes
locais (Kind) e duas abordagens praticas: clusters reais e simulacao
com namespaces.

---

## Indice

1. [Arquitetura Multi-Cluster](#arquitetura-multi-cluster)
2. [Como Funciona o Registro de Clusters](#como-funciona-o-registro-de-clusters)
3. [Problema do Localhost no Kind](#problema-do-localhost-no-kind)
4. [Solucao: IP Real do Container Docker](#solucao-ip-real-do-container-docker)
5. [Opcao A: Dois Clusters Kind Reais](#opcao-a-dois-clusters-kind-reais)
6. [Opcao B: Simulacao com Namespaces](#opcao-b-simulacao-com-namespaces)
7. [Demonstracao: Application Apontando para Cluster Externo](#demonstracao-application-apontando-para-cluster-externo)
8. [Tabela Comparativa: Opcao A vs Opcao B](#tabela-comparativa-opcao-a-vs-opcao-b)
9. [Comandos Uteis](#comandos-uteis)
10. [Resumo](#resumo)
11. [Referencias](#referencias)

---

## Arquitetura Multi-Cluster

O Argo CD suporta nativamente a gestao multi-cluster. O modelo
funciona assim: **um unico Argo CD** instalado em um cluster central
(chamado de management cluster ou hub cluster) gerencia a entrega
continua de aplicacoes em **N clusters de destino** (workload clusters).

```
+------------------------------------------------------------------+
|                    CLUSTER CENTRAL (hub)                          |
|                                                                  |
|   +-------------------+   +----------------------------------+   |
|   |  Argo CD          |   |  Application CRDs                |   |
|   |  (server, ctrl,   |   |                                  |   |
|   |   repo-server...) |   |  app-a -> cluster-dev            |   |
|   +-------------------+   |  app-b -> cluster-staging         |   |
|                            |  app-c -> cluster-prod            |   |
|                            +----------------------------------+   |
+------+---------------------+---------------------+---------------+
       |                     |                     |
       v                     v                     v
+-------------+    +----------------+    +----------------+
| cluster-dev |    | cluster-staging|    | cluster-prod   |
|             |    |                |    |                |
| (namespace  |    | (namespace     |    | (namespace     |
|  demo-app)  |    |  demo-app)     |    |  demo-app)     |
+-------------+    +----------------+    +----------------+
```

### Ponto-chave: clusters de destino NAO precisam do Argo CD

Os clusters de destino (dev, staging, prod) **nao precisam ter o
Argo CD instalado**. O Argo CD do cluster central se conecta
remotamente a API do Kubernetes de cada cluster externo e aplica
os manifests diretamente.

Isso significa que:

- Existe apenas **uma instancia** do Argo CD para gerenciar
- Os clusters de destino sao **consumidores passivos**
- A complexidade operacional fica centralizada no hub
- Credenciais de acesso aos clusters sao armazenadas como Secrets
  no namespace `argocd` do cluster central

### Beneficios do modelo multi-cluster

| Beneficio | Descricao |
|-----------|-----------|
| **Centralizacao** | Uma unica interface (UI) para visualizar todas as aplicacoes em todos os clusters |
| **Padronizacao** | Os mesmos manifests GitOps sao aplicados em multiplos clusters |
| **Governanca** | Controle de acesso e politicas definidos em um unico lugar |
| **Custo operacional** | Menos instancias de Argo CD para manter e monitorar |

---

## Como Funciona o Registro de Clusters

Para que o Argo CD consiga gerenciar um cluster externo, e
necessario **registra-lo**. O registro cria um Secret no namespace
`argocd` contendo as credenciais de acesso ao cluster de destino.

### Comando de registro

```bash
# Registrar um cluster externo usando o contexto do kubeconfig
argocd cluster add <context-name>
```

Onde `<context-name>` e o nome do contexto Kubernetes conforme
listado no seu kubeconfig. Para listar os contextos disponiveis:

```bash
kubectl config get-contexts
```

### O que acontece internamente

Ao executar `argocd cluster add`, o Argo CD:

1. Le as credenciais do contexto informado no kubeconfig
2. Cria um **ServiceAccount** no cluster de destino com permissoes
   de cluster-admin
3. Armazena o token e o endereco do API server como um **Secret**
   no namespace `argocd` do cluster central
4. O Argo CD passa a conseguir aplicar manifests nesse cluster

### Cluster "in-cluster" (padrao)

O cluster onde o Argo CD esta instalado e automaticamente
registrado com a URL especial `https://kubernetes.default.svc`.
Esse e o cluster local (in-cluster) e nao precisa de registro
manual.

```bash
# Listar clusters registrados no Argo CD
argocd cluster list
```

Saida tipica:

```
SERVER                          NAME        VERSION  STATUS
https://kubernetes.default.svc  in-cluster  1.34     Successful
https://172.18.0.3:6443         kind-dev    1.34     Successful
```

---

## Problema do Localhost no Kind

Ao trabalhar com multiplos clusters Kind na mesma maquina, um
problema de rede impede o registro direto entre clusters.

### O problema

O Kind expoe o API server de cada cluster como `127.0.0.1:<porta>`
no host (sua maquina). No entanto, os containers Docker que
compoem os clusters Kind **nao compartilham** a interface de
loopback (`127.0.0.1`) entre si.

```
+------------------------------------------------------+
|                    Sua Maquina (Host)                 |
|                                                      |
|  kind-argocd ──> 127.0.0.1:36443                     |
|  kind-dev    ──> 127.0.0.1:37443                     |
|                                                      |
|  O host acessa ambos via 127.0.0.1 (funciona)        |
+------------------------------------------------------+

+------------------------------------------------------+
|              Container Docker: kind-argocd            |
|                                                      |
|  Argo CD tenta acessar 127.0.0.1:37443               |
|  Mas 127.0.0.1 aqui e O PROPRIO container, nao o dev |
|  RESULTADO: conexao recusada                          |
+------------------------------------------------------+
```

### Por que isso acontece

- Cada container Docker tem seu proprio **network namespace**
- O endereco `127.0.0.1` dentro de um container aponta para
  **ele mesmo**, nao para o host ou outros containers
- O kubeconfig gerado pelo Kind usa `127.0.0.1` porque pressupoe
  que voce acessa o cluster a partir do host

---

## Solucao: IP Real do Container Docker

A solucao e substituir `127.0.0.1` pelo **IP real do container
Docker** na rede interna do Docker. Containers Docker na mesma
rede podem se comunicar usando seus IPs internos.

### Como descobrir o IP real

```bash
# Obter o IP do container do cluster de destino
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-dev-control-plane
```

Saida tipica:

```
172.18.0.3
```

### Como corrigir o kubeconfig

Apos descobrir o IP real, edite o kubeconfig para substituir
`127.0.0.1` pelo IP do container:

```bash
# Antes (nao funciona entre containers)
server: https://127.0.0.1:37443

# Depois (funciona entre containers)
server: https://172.18.0.3:6443
```

Voce pode fazer a correcao com o `kubectl config`:

```bash
# Alterar o server do cluster no kubeconfig
kubectl config set-cluster kind-dev \
  --server=https://172.18.0.3:6443
```

> **Nota:** a porta tambem muda. Dentro do container, o API
> server roda na porta padrao `6443`, enquanto no host o Kind
> mapeia para uma porta aleatoria (como `37443`).

---

## Opcao A: Dois Clusters Kind Reais

Esta opcao cria dois clusters Kind separados: um para o Argo CD
(hub) e outro como cluster de destino (workload). E a abordagem
mais realista, mas consome mais RAM.

### Requisitos de recursos

| Recurso | Consumo estimado |
|---------|-----------------|
| Cluster hub (Argo CD) | ~1.4 GB (control-plane + Argo CD) |
| Cluster dev (workload) | ~0.7 GB (control-plane apenas) |
| **Total** | **~2.1 GB de RAM** |

### Passo a passo

#### 1. Criar o cluster hub (com Argo CD)

```bash
# Criar o cluster hub
kind create cluster --name argocd-hub

# Criar namespace e instalar Argo CD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Aguardar pods ficarem prontos
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
```

#### 2. Criar o cluster de destino

```bash
# Criar o cluster de destino
kind create cluster --name dev-cluster
```

#### 3. Descobrir o IP real do cluster de destino

```bash
# Obter o IP interno do container Docker
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dev-cluster-control-plane
```

Anote o IP retornado (exemplo: `172.18.0.3`).

#### 4. Atualizar o kubeconfig com o IP real

```bash
# Substituir 127.0.0.1 pelo IP real do container
kubectl config set-cluster kind-dev-cluster \
  --server=https://172.18.0.3:6443
```

#### 5. Mudar para o contexto do cluster hub

```bash
# Voltar para o contexto do hub (onde o Argo CD esta)
kubectl config use-context kind-argocd-hub
```

#### 6. Fazer login no Argo CD e registrar o cluster

```bash
# Obter a senha do admin
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# Port-forward para acessar o Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login no CLI do Argo CD
argocd login localhost:8080 --insecure --username admin --password "$ARGOCD_PASS"

# Registrar o cluster de destino
argocd cluster add kind-dev-cluster --yes
```

#### 7. Verificar o registro

```bash
# Listar clusters registrados
argocd cluster list
```

Saida esperada:

```
SERVER                          NAME              VERSION  STATUS
https://kubernetes.default.svc  in-cluster        1.34     Successful
https://172.18.0.3:6443         kind-dev-cluster  1.34     Successful
```

---

## Opcao B: Simulacao com Namespaces

Se a maquina nao possui RAM suficiente para dois clusters Kind,
e possivel **simular** o cenario multi-cluster usando namespaces
diferentes dentro do mesmo cluster. Essa abordagem nao e
multi-cluster real, mas permite praticar os mesmos conceitos do
Argo CD (Applications apontando para diferentes destinos).

### Requisitos de recursos

| Recurso | Consumo estimado |
|---------|-----------------|
| Cluster unico (Argo CD + workloads) | ~1.4 GB |
| **Total** | **~1.4 GB de RAM** |

### Passo a passo

#### 1. Criar namespaces que representam "clusters"

```bash
# Namespace representando o ambiente de desenvolvimento
kubectl create namespace simulated-dev

# Namespace representando o ambiente de staging
kubectl create namespace simulated-staging

# Namespace representando o ambiente de producao
kubectl create namespace simulated-prod
```

#### 2. Criar Applications apontando para namespaces diferentes

Cada Application do Argo CD aponta para o mesmo cluster
(`https://kubernetes.default.svc`) mas com namespace diferente:

```yaml
# application-dev.yaml
# Application que simula deploy no "cluster de dev"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  # Nome da Application no Argo CD
  name: demo-app-dev
  # Namespace onde o Argo CD esta instalado
  namespace: argocd
spec:
  # Projeto do Argo CD (default permite tudo)
  project: default
  source:
    # URL do repositorio Git com os manifests
    repoURL: https://github.com/seu-usuario/seu-repo.git
    # Branch a ser monitorada
    targetRevision: main
    # Caminho dos manifests dentro do repositorio
    path: k8s/manifests
  destination:
    # Cluster de destino (in-cluster, pois e o mesmo)
    server: https://kubernetes.default.svc
    # Namespace que simula o "cluster de dev"
    namespace: simulated-dev
  syncPolicy:
    automated:
      # Remover recursos que nao existem mais no Git
      prune: true
      # Reverter alteracoes manuais no cluster
      selfHeal: true
```

#### 3. Replicar para staging e producao

Basta duplicar o YAML acima, alterando `name` e `namespace`
no campo `destination`:

- `demo-app-staging` -> `namespace: simulated-staging`
- `demo-app-prod` -> `namespace: simulated-prod`

#### 4. Aplicar as Applications

```bash
kubectl apply -f application-dev.yaml
kubectl apply -f application-staging.yaml
kubectl apply -f application-prod.yaml
```

#### 5. Verificar no Argo CD

```bash
# Listar todas as Applications
argocd app list

# Ou via kubectl
kubectl get applications -n argocd
```

A UI do Argo CD mostrara tres Applications separadas, cada uma
apontando para um namespace diferente, simulando visualmente
o cenario multi-cluster.

---

## Demonstracao: Application Apontando para Cluster Externo

Usando a Opcao A (dois clusters reais), a Application deve
referenciar o **server URL** do cluster externo no campo
`destination.server`:

```yaml
# application-external.yaml
# Application que faz deploy em um cluster EXTERNO
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  # Nome unico da Application
  name: demo-app-external
  # Sempre no namespace do Argo CD
  namespace: argocd
spec:
  # Projeto padrao (sem restricoes)
  project: default
  source:
    # Repositorio Git contendo os manifests
    repoURL: https://github.com/seu-usuario/seu-repo.git
    # Branch monitorada
    targetRevision: main
    # Diretorio dos manifests
    path: k8s/manifests
  destination:
    # URL do cluster EXTERNO (registrado previamente)
    server: https://172.18.0.3:6443
    # Namespace de destino no cluster externo
    namespace: demo-app
  syncPolicy:
    automated:
      # Remover recursos orfaos
      prune: true
      # Corrigir drift automaticamente
      selfHeal: true
    syncOptions:
      # Criar o namespace automaticamente se nao existir
      - CreateNamespace=true
```

### Pontos importantes

- O campo `destination.server` aponta para o IP real do cluster
  externo (nao `127.0.0.1`)
- O cluster deve ter sido registrado previamente com
  `argocd cluster add`
- A opcao `CreateNamespace=true` garante que o namespace sera
  criado automaticamente no cluster externo se ainda nao existir
- O Argo CD se conecta ao API server do cluster externo usando
  as credenciais armazenadas no Secret de registro

---

## Tabela Comparativa: Opcao A vs Opcao B

| Aspecto | Opcao A (2 Clusters Reais) | Opcao B (Simulacao com Namespaces) |
|---------|---------------------------|-------------------------------------|
| **Realismo** | Alto - clusters separados de verdade | Baixo - mesmo cluster, namespaces diferentes |
| **Consumo de RAM** | ~2.1 GB (dois clusters Kind) | ~1.4 GB (um cluster Kind) |
| **Rede entre clusters** | Requer ajuste de IP (docker inspect) | Sem necessidade (mesmo cluster) |
| **Registro de cluster** | Obrigatorio (`argocd cluster add`) | Nao necessario (usa in-cluster) |
| **Isolamento** | Real - cada cluster tem seu etcd e API server | Parcial - namespaces compartilham o mesmo cluster |
| **Dificuldade** | Maior (requer mais passos e troubleshooting) | Menor (poucos comandos) |
| **Quando usar** | Maquina com 3+ GB livres para clusters | Maquina com RAM limitada (< 2.5 GB livres) |
| **Didatica** | Ideal para entender multi-cluster real | Suficiente para praticar ApplicationSets |
| **Cenario de producao** | Simula o modelo real de producao | Nao reflete producao real |

### Recomendacao

- Se voce tem **3 GB ou mais** de RAM livre para o Docker/WSL2,
  use a **Opcao A** para experiencia completa.
- Se voce tem **menos de 2.5 GB** livres, use a **Opcao B** como
  fallback. Voce ainda pratica os mesmos conceitos do Argo CD
  (Applications, sync, prune, selfHeal), apenas sem a separacao
  real de clusters.

---

## Comandos Uteis

### Gerenciamento de contextos

```bash
# Listar todos os contextos Kubernetes disponiveis
kubectl config get-contexts

# Ver o contexto ativo no momento
kubectl config current-context

# Alternar para outro contexto
kubectl config use-context kind-argocd-hub
```

### Gerenciamento de clusters no Argo CD

```bash
# Listar clusters registrados no Argo CD
argocd cluster list

# Registrar um novo cluster
argocd cluster add <context-name> --yes

# Remover um cluster registrado
argocd cluster rm <server-url>
```

### Inspecao de rede Docker

```bash
# Ver o IP interno de um container Kind
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-name>

# Listar todos os containers Kind em execucao
docker ps --filter "label=io.x-k8s.kind.cluster"

# Ver a rede Docker usada pelo Kind
docker network ls | grep kind
```

### Verificacao de Applications

```bash
# Listar todas as Applications do Argo CD
argocd app list

# Ver detalhes de uma Application especifica
argocd app get demo-app-external

# Via kubectl
kubectl get applications -n argocd
```

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **Multi-cluster** | Um Argo CD central gerencia N clusters remotos |
| **Clusters de destino** | Nao precisam ter Argo CD instalado |
| **Registro** | Feito via `argocd cluster add <context-name>` |
| **Problema do localhost** | Kind usa `127.0.0.1`, mas containers nao compartilham loopback |
| **Solucao** | Usar o IP real do container Docker (`docker inspect`) |
| **Opcao A** | 2 clusters Kind reais (~2.1 GB RAM) - recomendada se houver recursos |
| **Opcao B** | Simulacao com namespaces (~1.4 GB RAM) - fallback para maquinas limitadas |
| **destination.server** | Campo da Application que define qual cluster recebe o deploy |

---

## Referencias

- [Argo CD - Clusters](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters)
- [Argo CD - Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Kind - Networking](https://kind.sigs.k8s.io/docs/user/configuration/#networking)
- [Docker - Container Networking](https://docs.docker.com/network/)
