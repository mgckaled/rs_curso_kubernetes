<!-- markdownlint-disable -->

# Plano Didático - Nível 1, Módulo 1

## Visão Geral

| Item | Descrição |
|------|-----------|
| **Nível** | 1 - Fundamentos do Kubernetes |
| **Módulo** | 1 - Introdução a Conceitos Fundamentais |
| **Blocos** | A (Conhecendo o K8s) + B (Orquestrando Containers) |
| **Pré-requisitos** | Docker Desktop, Kind, kubectl, Lens |

---

## Bloco A - Conhecendo o Kubernetes

### Objetivos de Aprendizado

- Entender o que é Kubernetes e seus trade-offs
- Compreender a arquitetura de um cluster (Control Plane + Workers)
- Conhecer os componentes principais (kube-scheduler, etcd, kubelet, kube-proxy)
- Configurar ambiente local com Kind

### Estrutura de Arquivos

```txt
n1/
└── m1/
    └── b-a/
        ├── README.md           # Guia passo a passo
        └── cluster/
            └── kind-config.yaml
```

### Prática: Criando o Primeiro Cluster

#### 1. Configuração do Kind

Arquivo: `n1/m1/b-a/cluster/kind-config.yaml`

```yaml
# Configuração do cluster Kind
# kind: tipo do recurso (Cluster para configuração do Kind)
# apiVersion: versão da API do Kind
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

# nodes: define os nós do cluster
nodes:
  # Control Plane: gerencia o estado do cluster
  # Executa: kube-apiserver, kube-scheduler, kube-controller-manager, etcd
  - role: control-plane

  # Worker Node: executa as cargas de trabalho (pods)
  # Executa: kubelet, kube-proxy, container runtime
  - role: worker
```

#### 2. Comandos Essenciais

```bash
# Criar cluster com configuração personalizada
# --name: nome do cluster (padrão: kind)
# --config: arquivo de configuração YAML
kind create cluster --name k8s-lab --config kind-config.yaml

# Listar clusters criados
kind get clusters

# Verificar nós do cluster
# Mostra: NAME, STATUS, ROLES, AGE, VERSION
kubectl get nodes

# Ver detalhes de um nó específico
# Mostra: recursos, condições, capacidade, pods alocados
kubectl describe node <nome-do-node>

# Deletar cluster
kind delete cluster --name k8s-lab
```

#### 3. Validação

| Verificação | Comando | Resultado Esperado |
|-------------|---------|-------------------|
| Cluster criado | `kind get clusters` | `k8s-lab` listado |
| Nós ativos | `kubectl get nodes` | 2 nós com STATUS `Ready` |
| Control Plane | `kubectl get nodes` | 1 nó com ROLE `control-plane` |
| Worker | `kubectl get nodes` | 1 nó com ROLE `<none>` (worker) |

---

## Bloco B - Orquestrando Containers

### Objetivos de Aprendizado

- Criar e gerenciar Pods
- Entender Namespaces para organização
- Implementar ReplicaSets para redundância
- Usar Deployments para versionamento
- Expor aplicações com Services

### Estrutura de Arquivos

```txt
n1/
└── m1/
    └── b-b/
        ├── README.md
        └── manifests/
            ├── 01-namespace.yaml
            ├── 02-pod.yaml
            ├── 03-replicaset.yaml
            ├── 04-deployment.yaml
            └── 05-service.yaml
```

### Prática 1: Namespace

Arquivo: `n1/m1/b-b/manifests/01-namespace.yaml`

```yaml
# Namespace: agrupa recursos logicamente
# Permite: isolamento, organização, governança
apiVersion: v1
kind: Namespace
metadata:
  # name: identificador único do namespace
  name: lab
```

```bash
# Criar namespace
kubectl apply -f 01-namespace.yaml

# Listar namespaces
# Padrão: default, kube-system, kube-public, kube-node-lease
kubectl get namespaces

# Abreviação
kubectl get ns
```

### Prática 2: Pod

Arquivo: `n1/m1/b-b/manifests/02-pod.yaml`

```yaml
# Pod: menor unidade do Kubernetes
# Encapsula um ou mais containers
apiVersion: v1
kind: Pod
metadata:
  # name: identificador único do pod no namespace
  name: nginx-pod
  # namespace: onde o pod será criado
  namespace: lab
  # labels: metadados para seleção e organização
  labels:
    app: nginx
spec:
  # containers: lista de containers no pod
  containers:
    # name: identificador do container dentro do pod
    - name: nginx
      # image: imagem do container (registry/nome:tag)
      image: nginx:1.27.5
      # resources: define limites e requisições de recursos
      resources:
        # requests: recursos mínimos garantidos
        # Usado pelo scheduler para alocar o pod
        requests:
          # cpu: 100m = 0.1 vCPU (milicores)
          cpu: "100m"
          # memory: 128Mi = 128 Mebibytes
          memory: "128Mi"
        # limits: recursos máximos permitidos
        # Container é terminado se exceder memory limit
        limits:
          cpu: "250m"
          memory: "256Mi"
      # ports: portas expostas pelo container
      ports:
        # containerPort: porta interna do container
        - containerPort: 80
```

```bash
# Criar pod
kubectl apply -f 02-pod.yaml

# Listar pods no namespace lab
# -n: especifica o namespace
kubectl get pods -n lab

# Ver detalhes do pod
kubectl describe pod nginx-pod -n lab

# Acessar pod via port-forward
# Mapeia porta local 8080 para porta 80 do container
kubectl port-forward pod/nginx-pod 8080:80 -n lab

# Testar acesso (em outro terminal)
curl http://localhost:8080

# Ver logs do pod
kubectl logs nginx-pod -n lab

# Deletar pod (demonstra efemeridade)
kubectl delete pod nginx-pod -n lab

# Verificar: pod não é recriado automaticamente
kubectl get pods -n lab
```

### Prática 3: ReplicaSet

Arquivo: `n1/m1/b-b/manifests/03-replicaset.yaml`

```yaml
# ReplicaSet: garante número desejado de réplicas
# Problema: não suporta atualizações de versão graciosamente
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  namespace: lab
  # labels: identificam o próprio ReplicaSet
  labels:
    app: nginx
spec:
  # replicas: quantidade de pods desejada
  replicas: 3
  # selector: como o ReplicaSet encontra os pods que gerencia
  selector:
    # matchLabels: pods DEVEM ter estas labels
    matchLabels:
      app: nginx
  # template: modelo para criar novos pods
  template:
    metadata:
      # labels: DEVEM corresponder ao selector
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.5
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
          ports:
            - containerPort: 80
```

```bash
# Criar ReplicaSet
kubectl apply -f 03-replicaset.yaml

# Listar ReplicaSets
# DESIRED: réplicas desejadas
# CURRENT: réplicas atuais
# READY: réplicas prontas
kubectl get replicaset -n lab
# Abreviação
kubectl get rs -n lab

# Listar pods (3 réplicas)
kubectl get pods -n lab

# Deletar um pod (ReplicaSet recria automaticamente)
kubectl delete pod <nome-do-pod> -n lab

# Verificar: novo pod criado
kubectl get pods -n lab

# Problema do ReplicaSet: alterar imagem não atualiza pods existentes
# Edite a imagem para nginx:1.28.0 e aplique novamente
# Os pods antigos continuam com a versão antiga!
```

### Prática 4: Deployment

Arquivo: `n1/m1/b-b/manifests/04-deployment.yaml`

```yaml
# Deployment: abstração sobre ReplicaSet
# Vantagens: rolling updates, rollback, histórico de versões
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: lab
  labels:
    app: nginx
spec:
  # replicas: quantidade de pods
  replicas: 3
  # selector: identifica pods gerenciados
  selector:
    matchLabels:
      app: nginx
  # template: modelo do pod (igual ao ReplicaSet)
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          # tag: associe ao commit/versão da aplicação
          image: nginx:1.27.5
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
          ports:
            - containerPort: 80
```

```bash
# Remover ReplicaSet anterior
kubectl delete replicaset nginx-replicaset -n lab

# Criar Deployment
kubectl apply -f 04-deployment.yaml

# Listar Deployments
# READY: pods prontos/desejados
# UP-TO-DATE: pods com versão atual
# AVAILABLE: pods disponíveis para uso
kubectl get deployments -n lab
# Abreviação
kubectl get deploy -n lab

# Ver ReplicaSet criado pelo Deployment
kubectl get rs -n lab

# Ver pods
kubectl get pods -n lab

# Atualizar versão (rolling update)
# Edite image para nginx:1.28.0 e aplique
kubectl apply -f 04-deployment.yaml

# Acompanhar rollout
kubectl rollout status deployment/nginx-deployment -n lab

# Ver histórico de revisões
kubectl rollout history deployment/nginx-deployment -n lab

# Rollback para versão anterior (se necessário)
kubectl rollout undo deployment/nginx-deployment -n lab
```

### Prática 5: Service

Arquivo: `n1/m1/b-b/manifests/05-service.yaml`

```yaml
# Service: abstração de rede para acessar pods
# Tipos: ClusterIP (interno), NodePort, LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: lab
spec:
  # selector: pods que receberão tráfego
  # DEVE corresponder às labels dos pods do Deployment
  selector:
    app: nginx
  # type: ClusterIP é o padrão (acesso interno)
  type: ClusterIP
  # ports: mapeamento de portas
  ports:
    # protocol: TCP ou UDP
    - protocol: TCP
      # port: porta exposta pelo Service
      port: 80
      # targetPort: porta do container
      targetPort: 80
```

```bash
# Criar Service
kubectl apply -f 05-service.yaml

# Listar Services
# CLUSTER-IP: IP interno do serviço
# PORT(S): portas expostas
kubectl get services -n lab
# Abreviação
kubectl get svc -n lab

# Acessar via port-forward no Service
# Balanceia entre os 3 pods automaticamente
kubectl port-forward svc/nginx-service 8080:80 -n lab

# Testar acesso
curl http://localhost:8080

# Ver endpoints (IPs dos pods)
kubectl get endpoints nginx-service -n lab
```

---

## Resumo de Comandos

### Kind

| Comando | Descrição |
|---------|-----------|
| `kind create cluster --config <file>` | Criar cluster |
| `kind get clusters` | Listar clusters |
| `kind delete cluster --name <name>` | Deletar cluster |

### kubectl - Recursos

| Comando | Descrição |
|---------|-----------|
| `kubectl apply -f <file>` | Criar/atualizar recurso |
| `kubectl delete -f <file>` | Deletar recurso |
| `kubectl get <resource> -n <ns>` | Listar recursos |
| `kubectl describe <resource> <name>` | Detalhes do recurso |

### kubectl - Pods

| Comando | Descrição |
|---------|-----------|
| `kubectl logs <pod>` | Ver logs |
| `kubectl exec -it <pod> -- /bin/sh` | Acessar shell |
| `kubectl port-forward <pod> <local>:<container>` | Encaminhar porta |

### kubectl - Deployments

| Comando | Descrição |
|---------|-----------|
| `kubectl rollout status deploy/<name>` | Status do rollout |
| `kubectl rollout history deploy/<name>` | Histórico |
| `kubectl rollout undo deploy/<name>` | Rollback |

---

## Hierarquia de Objetos

```txt
Deployment
    │
    ├── gerencia ──► ReplicaSet (v1)
    │                    │
    │                    └── gerencia ──► Pod 1, Pod 2, Pod 3
    │
    └── gerencia ──► ReplicaSet (v2) [após update]
                         │
                         └── gerencia ──► Pod 1, Pod 2, Pod 3

Service
    │
    └── roteia tráfego para ──► Pods (via selector/labels)
```

---

## Checklist de Validação

### Bloco A

- [ ] Cluster Kind criado com 1 control-plane + 1 worker
- [ ] `kubectl get nodes` mostra 2 nós `Ready`
- [ ] Lens conectado ao cluster

### Bloco B

- [ ] Namespace `lab` criado
- [ ] Pod criado e acessível via port-forward
- [ ] Pod deletado manualmente não é recriado
- [ ] ReplicaSet mantém 3 réplicas
- [ ] Deployment criado e funcionando
- [ ] Rolling update executado com sucesso
- [ ] Service expondo os pods
- [ ] Acesso via Service balanceia entre pods
