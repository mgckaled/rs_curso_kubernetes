# Entendendo os Pods do kube-system

## Contexto

Este documento explica o resultado do comando `kubectl get pods -n kube-system` e o papel de cada componente do sistema Kubernetes.

---

## Exemplo de Saída

```bash
kubectl get pods -n kube-system
```

```txt
NAME                                            READY   STATUS    RESTARTS   AGE
coredns-66bc5c9577-77k97                        1/1     Running   0          19m
coredns-66bc5c9577-hbzqt                        1/1     Running   0          19m
etcd-k8s-lab-control-plane                      1/1     Running   0          20m
kindnet-9qvk9                                   1/1     Running   0          19m
kindnet-q2dtf                                   1/1     Running   0          20m
kube-apiserver-k8s-lab-control-plane            1/1     Running   0          20m
kube-controller-manager-k8s-lab-control-plane   1/1     Running   0          20m
kube-proxy-bhbqc                                1/1     Running   0          19m
kube-proxy-thfvp                                1/1     Running   0          20m
kube-scheduler-k8s-lab-control-plane            1/1     Running   0          20m
```

---

## Estrutura das Colunas

| Coluna | Descrição |
|--------|-----------|
| **NAME** | Nome único do pod |
| **READY** | Containers prontos/total (formato: X/Y) |
| **STATUS** | Estado atual do pod (Running, Pending, Error, etc.) |
| **RESTARTS** | Número de vezes que o pod foi reiniciado |
| **AGE** | Tempo desde a criação do pod |

---

## Pods do Control Plane

Esses pods rodam no nó control-plane e gerenciam o cluster:

### 1. etcd

```txt
etcd-<cluster-name>-control-plane
```

- **Função**: Banco de dados chave-valor distribuído
- **Responsabilidade**: Armazena TODO o estado do cluster
  - Configurações
  - Secrets
  - Deployments
  - Services
  - Estado dos nós e pods
- **Importância**: É o "cérebro" do cluster - se ele cair, o cluster perde memória
- **Tipo**: Pod estático (gerenciado pelo kubelet)

### 2. kube-apiserver

```txt
kube-apiserver-<cluster-name>-control-plane
```

- **Função**: Ponto de entrada para TODAS as operações do cluster
- **Responsabilidade**:
  - Recebe comandos do `kubectl`
  - Valida requisições
  - Processa operações CRUD no etcd
  - Autentica e autoriza usuários
- **Importância**: Sem ele, você não consegue se comunicar com o cluster
- **Tipo**: Pod estático

### 3. kube-controller-manager

```txt
kube-controller-manager-<cluster-name>-control-plane
```

- **Função**: Executa controladores que gerenciam o estado desejado
- **Responsabilidade**: Garante que o estado atual corresponda ao estado declarado
- **Exemplos de controladores**:
  - ReplicaSet Controller: Mantém número correto de réplicas
  - Deployment Controller: Gerencia atualizações de deployments
  - Node Controller: Monitora saúde dos nós
  - Service Controller: Cria e gerencia endpoints
- **Tipo**: Pod estático

### 4. kube-scheduler

```txt
kube-scheduler-<cluster-name>-control-plane
```

- **Função**: Decide em qual nó cada pod será executado
- **Responsabilidade**:
  - Analisa recursos disponíveis (CPU, memória)
  - Verifica restrições e afinidades
  - Seleciona o melhor nó para cada pod
- **Importância**: Sem ele, novos pods ficam em estado "Pending"
- **Tipo**: Pod estático

---

## Pods de Rede (DaemonSets)

Esses pods rodam em TODOS os nós do cluster:

### 5. kindnet

```txt
kindnet-xxxxx (múltiplos pods)
```

- **Função**: Plugin CNI (Container Network Interface) do Kind
- **Responsabilidade**:
  - Configura a rede overlay entre pods
  - Gerencia roteamento de pacotes
  - Permite comunicação pod-to-pod entre nós diferentes
- **Por que vários?**: Um pod roda em cada nó (DaemonSet)
- **Tipo**: DaemonSet

### 6. kube-proxy

```txt
kube-proxy-xxxxx (múltiplos pods)
```

- **Função**: Gerencia regras de rede para Services
- **Responsabilidade**:
  - Configura regras iptables/IPVS
  - Roteia tráfego para pods corretos
  - Faz load balancing entre réplicas
  - Implementa Services do tipo ClusterIP, NodePort, etc.
- **Por que vários?**: Um pod roda em cada nó (DaemonSet)
- **Tipo**: DaemonSet

---

## Pods de DNS

### 7. CoreDNS

```txt
coredns-xxxxxxxxxx-xxxxx (2 réplicas por padrão)
```

- **Função**: Servidor DNS interno do cluster
- **Responsabilidade**:
  - Resolve nomes de Services para IPs
  - Formato: `<service-name>.<namespace>.svc.cluster.local`
  - Exemplo: `my-app.default.svc.cluster.local` → `10.96.0.10`
- **Por que 2?**: Alta disponibilidade - se um cair, o outro continua
- **Importante**: Sem DNS, pods não conseguem se comunicar por nome
- **Tipo**: Deployment

---

## Indicadores de Saúde

### Status Ideal

| Coluna | Valor Esperado | Significado |
|--------|----------------|-------------|
| **READY** | `1/1` (ou X/X) | Todos os containers do pod estão prontos |
| **STATUS** | `Running` | Pod está executando normalmente |
| **RESTARTS** | `0` ou baixo | Pod está estável, sem crashes |

### Problemas Comuns

| Status | Possível Causa |
|--------|----------------|
| `Pending` | Aguardando recursos ou scheduler |
| `CrashLoopBackOff` | Container está crashando repetidamente |
| `Error` | Container teve erro fatal |
| `ImagePullBackOff` | Não conseguiu baixar a imagem |
| RESTARTS alto | Pod está instável e reiniciando |

---

## Distribuição dos Pods

### Por Tipo de Nó

```plaintext
Control Plane:
├── etcd
├── kube-apiserver
├── kube-controller-manager
├── kube-scheduler
├── kindnet (1 pod)
└── kube-proxy (1 pod)

Worker Nodes (cada um):
├── kindnet (1 pod)
└── kube-proxy (1 pod)

Qualquer Nó:
└── coredns (distribuído conforme necessário)
```

### Por Categoria

- **Control Plane**: 4 pods (etcd, apiserver, controller-manager, scheduler)
- **Networking**: 2 DaemonSets (kindnet e kube-proxy)
- **DNS**: 1 Deployment (CoreDNS, geralmente 2 réplicas)

---

## Relacionamento com Arquitetura

Comparando com o diagrama de arquitetura:

| Componente Teórico | Pod Real |
|--------------------|----------|
| kube-apiserver | `kube-apiserver-<cluster>-control-plane` |
| kube-scheduler | `kube-scheduler-<cluster>-control-plane` |
| kube-controller-manager | `kube-controller-manager-<cluster>-control-plane` |
| etcd | `etcd-<cluster>-control-plane` |
| kubelet | (Não aparece - roda fora do Kubernetes) |
| kube-proxy | `kube-proxy-xxxxx` (DaemonSet) |
| container runtime | (Não aparece - roda fora do Kubernetes) |
| CNI (rede) | `kindnet-xxxxx` (DaemonSet) |

**Nota**: kubelet e container runtime não aparecem como pods porque eles rodam diretamente no sistema operacional do nó, não dentro do Kubernetes.

---

## Comandos Úteis

### Ver detalhes de um pod

```bash
kubectl describe pod <pod-name> -n kube-system
```

### Ver logs de um componente

```bash
kubectl logs <pod-name> -n kube-system
```

### Ver logs em tempo real

```bash
kubectl logs -f <pod-name> -n kube-system
```

### Ver recursos consumidos (requer metrics-server)

```bash
kubectl top pods -n kube-system
```

### Ver eventos do sistema

```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

### Ver pods de todos os namespaces

```bash
kubectl get pods --all-namespaces
```

---

## Análise da Ordem de Criação

Observando os valores de **AGE**, você pode ver a ordem de inicialização:

```txt
20m → Control Plane (etcd, apiserver, controller, scheduler)
20m → Primeiro nó (kindnet, kube-proxy)
19m → Worker nodes adicionados (kindnet, kube-proxy)
19m → CoreDNS iniciado
```

Esta sequência mostra:

1. Control plane sobe primeiro
2. Componentes de rede do primeiro nó
3. Workers são adicionados
4. DNS é configurado por último

---

## Tipos de Pods no kube-system

### Pods Estáticos (Static Pods)

- Gerenciados diretamente pelo kubelet
- Definidos em arquivos no filesystem do nó
- Não podem ser deletados via `kubectl delete`
- Exemplos: etcd, apiserver, controller-manager, scheduler

### DaemonSets

- Garantem 1 pod por nó
- Automaticamente adicionados em novos nós
- Exemplos: kindnet, kube-proxy

### Deployments

- Pods replicados para alta disponibilidade
- Gerenciados por ReplicaSets
- Exemplo: CoreDNS

---

## Troubleshooting

### Verificar se todos os componentes estão saudáveis

```bash
kubectl get componentstatuses
```

ou

```bash
kubectl get cs
```

### Se um pod estiver com problema

```bash
# Ver eventos do pod
kubectl describe pod <pod-name> -n kube-system

# Ver logs
kubectl logs <pod-name> -n kube-system

# Ver logs anteriores (se reiniciou)
kubectl logs <pod-name> -n kube-system --previous
```

### Reiniciar um componente (DaemonSet ou Deployment)

```bash
kubectl rollout restart daemonset <name> -n kube-system
kubectl rollout restart deployment <name> -n kube-system
```

**Atenção**: Não tente reiniciar pods estáticos com kubectl. Eles são gerenciados pelo kubelet.
