# Bloco A - Conhecendo o Kubernetes

## Objetivos

- Entender o que é Kubernetes e seus trade-offs
- Compreender a arquitetura de um cluster (Control Plane + Workers)
- Conhecer os componentes principais
- Configurar ambiente local com Kind

---

## Arquitetura do Cluster

```txt
┌─────────────────────────────────────────────────────────────┐
│                      CONTROL PLANE                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │ kube-api    │ │ kube-       │ │ kube-controller     │   │
│  │ server      │ │ scheduler   │ │ manager             │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      etcd                            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      WORKER NODE                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │ kubelet     │ │ kube-proxy  │ │ container runtime   │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Pods (containers)                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Componentes do Control Plane

| Componente | Função |
|------------|--------|
| **kube-apiserver** | Ponto de entrada para todas as operações do cluster |
| **kube-scheduler** | Decide em qual nó um pod será executado |
| **kube-controller-manager** | Executa controladores (ReplicaSet, Deployment, etc.) |
| **etcd** | Banco de dados chave-valor que armazena o estado do cluster |

### Componentes do Worker Node

| Componente | Função |
|------------|--------|
| **kubelet** | Agente que garante que os containers estão rodando |
| **kube-proxy** | Gerencia regras de rede para comunicação dos pods |
| **container runtime** | Executa os containers (containerd, Docker, etc.) |

---

## Prática

### Pré-requisitos

- Docker Desktop instalado e rodando
- Kind instalado (`kind version`)
- kubectl instalado (`kubectl version --client`)

### 1. Criar o Cluster

```bash
# Navegar até a pasta do bloco
cd n1/m1/b-a/cluster

# Criar cluster com configuração personalizada
kind create cluster --name k8s-lab --config kind-config.yaml
```

### 2. Verificar o Cluster

```bash
# Listar clusters Kind
kind get clusters

# Verificar nós do cluster
kubectl get nodes

# Saída esperada:
# NAME                    STATUS   ROLES           AGE   VERSION
# k8s-lab-control-plane   Ready    control-plane   1m    v1.x.x
# k8s-lab-worker          Ready    <none>          1m    v1.x.x
```

### 3. Explorar o Cluster

```bash
# Ver detalhes do control plane
kubectl describe node k8s-lab-control-plane

# Ver detalhes do worker
kubectl describe node k8s-lab-worker

# Ver todos os pods do sistema
kubectl get pods -n kube-system
```

### 4. Conectar o Lens (opcional)

1. Abra o Lens
2. O cluster `k8s-lab` deve aparecer automaticamente
3. Clique para conectar e explorar visualmente

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `kind create cluster --config <file>` | Criar cluster com configuração |
| `kind get clusters` | Listar clusters |
| `kind delete cluster --name <name>` | Deletar cluster |
| `kubectl get nodes` | Listar nós |
| `kubectl describe node <name>` | Detalhes do nó |
| `kubectl cluster-info` | Informações do cluster |

---

## Limpeza

```bash
# Deletar o cluster quando não precisar mais
kind delete cluster --name k8s-lab
```

---

## Checklist

- [ ] Docker Desktop rodando
- [ ] Cluster criado com sucesso
- [ ] 2 nós visíveis (1 control-plane + 1 worker)
- [ ] Ambos os nós com status `Ready`
- [ ] Lens conectado ao cluster (opcional)
