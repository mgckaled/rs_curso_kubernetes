<!-- markdownlint-disable -->

# Local (Kind) vs Cloud (EKS/GKE/AKS) - Comparacao

## Visao Geral

Este projeto educacional usa **Kind (Kubernetes in Docker)** para simular conceitos de auto scaling que normalmente requerem cloud providers. Esta abordagem permite aprender os fundamentos **sem custos** e **localmente**.

---

## Comparacao Feature por Feature

| Feature | Kind (Local) | Cloud (EKS/GKE/AKS) | Observacoes |
|---------|--------------|---------------------|-------------|
| **HPA** | ✅ 100% funcional | ✅ 100% funcional | Identico |
| **Metrics Server** | ✅ Com ajustes | ✅ Nativo | Requer flag `--kubelet-insecure-tls` no Kind |
| **Resource Requests/Limits** | ✅ 100% funcional | ✅ 100% funcional | Identico |
| **PodDisruptionBudgets** | ✅ 100% funcional | ✅ 100% funcional | Identico |
| **Topology Spread** | ✅ Simulado com labels | ✅ Real (multi-AZ) | Kind usa labels para simular zonas |
| **Node Affinity/Taints** | ✅ 100% funcional | ✅ 100% funcional | Identico |
| **Cluster Autoscaler** | ❌ Nao funcional | ✅ 100% funcional | Requer cloud provider |
| **Node Provisioning** | ⚠️ Manual | ✅ Automatico | Kind nao pode criar VMs |
| **LoadBalancer Service** | ❌ Sem MetalLB | ✅ Nativo | Requer MetalLB no Kind |
| **Persistent Volumes** | ✅ hostPath | ✅ EBS/Persistent Disk | Kind usa volumes locais |
| **Custo** | ✅ Zero | ❌ Pago por hora | Kind e gratuito |

---

## O Que e 100% Funcional no Kind

### 1. HPA (Horizontal Pod Autoscaler)

**Funciona identicamente** ao cloud. Escala pods baseado em CPU/memoria.

```yaml
# Este manifest funciona igual no Kind e EKS/GKE/AKS
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-api-hpa
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

**Teste:** Stress test de CPU escala pods automaticamente.

---

### 2. Resource Management

**Funciona identicamente** ao cloud. Scheduler usa requests/limits para decidir onde agendar pods.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

**Teste:** Criar pods que excedem capacidade do node resulta em Pending.

---

### 3. PodDisruptionBudgets

**Funciona identicamente** ao cloud. Protege contra interrupcoes voluntarias.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: demo-api
```

**Teste:** Drain de node respeita PDB e nao remove todos pods simultaneamente.

---

### 4. Node Management

**Funciona identicamente** ao cloud. Taints, tolerations, affinity, cordoning, draining.

```bash
# Adicionar taint
kubectl taint nodes worker-1 key=value:NoSchedule

# Cordon (impedir novos pods)
kubectl cordon worker-1

# Drain (remover pods)
kubectl drain worker-1 --ignore-daemonsets
```

**Teste:** Pods respeitam taints e affinity rules.

---

## O Que NAO Funciona no Kind

### 1. Cluster Autoscaler

**Nao funciona** porque requer cloud provider para provisionar VMs.

**Por que nao funciona:**
- Cluster Autoscaler faz chamadas API ao cloud provider (AWS, GCP, Azure)
- Kind roda em containers Docker, nao pode criar VMs
- Nao ha Auto Scaling Groups ou Managed Instance Groups

**Simulacao:** Use script `simulate-node-scale-down.sh` para demonstrar o conceito.

---

### 2. Load Balancer Nativo

Kind nao tem load balancer nativo (requer MetalLB ou alternativa).

**Cloud:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer  # Cria ELB/ALB automaticamente
```

**Kind:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: NodePort  # Ou ClusterIP com port-forward
  ports:
    - port: 80
      nodePort: 30000
```

**Solucao:** Use MetalLB (adiciona ~100-150MB de memoria).

---

### 3. Persistent Volumes Reais

Kind usa `hostPath` (volumes locais) ao inves de EBS/Persistent Disk.

**Cloud (EKS):**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: gp3  # AWS EBS gp3
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Kind:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: standard  # hostPath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Limitacao:** Volumes nao sobrevivem a delecao do cluster Kind.

---

## Simulando Cluster Autoscaler no Kind

Como Cluster Autoscaler nao funciona no Kind, podemos **simular o conceito** manualmente:

### Cenario 1: Scale Up (Adicionar Node)

**Cloud (Automatico):**
1. HPA escala de 2 para 10 pods
2. Pods ficam Pending (sem recursos)
3. Cluster Autoscaler detecta Pending
4. Cloud provider cria nova VM
5. VM se registra como node
6. Pods sao agendados no novo node

**Kind (Manual - Simulacao):**
```bash
# 1. Ver pods pending
kubectl get pods -n n3-m1-autoscale

# 2. Adicionar worker node ao cluster (requer recriar cluster)
# Edite 00-kind-cluster.yaml, adicione um worker
# kind create cluster --config manifests/00-kind-cluster.yaml

# 3. Pods sao agendados no novo node
kubectl get pods -n n3-m1-autoscale -o wide
```

**Limitacao:** Kind requer recriar o cluster para adicionar nodes.

---

### Cenario 2: Scale Down (Remover Node)

**Cloud (Automatico):**
1. Node subutilizado por 10+ minutos
2. Cluster Autoscaler decide remover node
3. Node recebe taint `ToBeDeletedByClusterAutoscaler`
4. Pods sao evicted (drain)
5. Cloud provider termina VM

**Kind (Manual - Simulacao):**
```bash
# Use o script que criamos
./scripts/simulate-node-scale-down.sh

# Ou manual:
# 1. Adicionar taint (simula CA)
kubectl taint nodes worker-2 node.kubernetes.io/scale-down=scheduled:NoSchedule

# 2. Drain node
kubectl drain worker-2 --ignore-daemonsets --delete-emptydir-data

# 3. Opcional: remover node
kubectl delete node worker-2
```

**Nota:** PodDisruptionBudgets sao respeitados durante drain.

---

## Topologia: Simulando Multi-AZ

### Cloud (Real)

Nodes em diferentes zonas de disponibilidade:

```plaintext
┌─────────────────────────────────────────┐
│          AWS Region (us-east-1)         │
│                                         │
│  ┌─────────────┐  ┌─────────────┐       │
│  │  us-east-1a │  │  us-east-1b │       │
│  │             │  │             │       │
│  │  Node 1     │  │  Node 2     │       │
│  │  Node 3     │  │  Node 4     │       │
│  └─────────────┘  └─────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

### Kind (Simulado)

Usamos **labels** para simular zonas:

```yaml
# 00-kind-cluster.yaml
nodes:
  - role: worker
    labels:
      topology.kubernetes.io/zone: zone-a
  - role: worker
    labels:
      topology.kubernetes.io/zone: zone-b
```

**Topology Spread Constraints** funcionam identicamente:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
```

Resultado: Pods distribuidos entre `zone-a` e `zone-b` (mesmo sendo no mesmo host fisico).

---

## Custo: Kind vs Cloud

### Kind (Local)

| Item | Custo |
|------|-------|
| Cluster | $0 |
| Nodes | $0 |
| Storage | $0 |
| Network | $0 |
| **Total/mes** | **$0** |

**Requisitos:**
- Docker Desktop (gratuito)
- 4GB RAM (minimo)
- 10GB disco

---

### Cloud (EKS - exemplo)

| Item | Configuracao | Custo/mes (estimado) |
|------|--------------|----------------------|
| EKS Control Plane | - | $72 |
| Worker Nodes | 3x t3.medium | $90 |
| EBS Volumes | 30GB gp3 | $2.40 |
| Data Transfer | 10GB/mes | $0.90 |
| **Total/mes** | | **~$165** |

**Nota:** Custos variam por regiao e uso.

---

## Quando Usar Cada Ambiente

### Use Kind Para:

✅ Aprender fundamentos do Kubernetes
✅ Testar manifests localmente
✅ Desenvolver e debugar aplicacoes
✅ CI/CD pipelines (testes rapidos)
✅ Demos e apresentacoes
✅ Estudar para certificacoes (CKA/CKAD)

### Use Cloud Para:

✅ Producao
✅ Alta disponibilidade real (multi-AZ)
✅ Escala automatica de nodes (Cluster Autoscaler)
✅ Load balancers gerenciados
✅ Integracao com servicos cloud (RDS, S3, etc)
✅ Persistent volumes duraveisAmbientes de staging/QA

---

## Migrando de Kind para Cloud

### Passo 1: Testar Localmente

```bash
# Aplicar manifests no Kind
kubectl apply -f manifests/

# Testar HPA
./scripts/stress-test.sh cpu 60

# Verificar PDB
kubectl describe pdb -n n3-m1-autoscale
```

### Passo 2: Adaptar para Cloud

**Mudancas necessarias:**

1. **Metrics Server:** Remover flag `--kubelet-insecure-tls`
2. **Service:** Mudar de `ClusterIP` para `LoadBalancer`
3. **StorageClass:** Mudar de `standard` para `gp3` (EKS) ou `pd-standard` (GKE)
4. **Cluster Autoscaler:** Instalar e configurar IAM/RBAC

### Passo 3: Deploy no Cloud

```bash
# Conectar ao cluster cloud
aws eks update-kubeconfig --name my-cluster

# Aplicar manifests (mesmos!)
kubectl apply -f manifests/

# Configurar Cluster Autoscaler
kubectl apply -f cloud/cluster-autoscaler.yaml
```

**A maioria dos manifests funciona sem alteracao!**

---

## Resumo

| Aspecto | Kind | Cloud |
|---------|------|-------|
| **Aprendizado** | ✅ Excelente | ⚠️ Caro |
| **Custo** | ✅ Zero | ❌ Alto |
| **HPA** | ✅ Funciona | ✅ Funciona |
| **Cluster Autoscaler** | ❌ Nao funciona | ✅ Funciona |
| **HA Real** | ❌ Single host | ✅ Multi-AZ |
| **Producao** | ❌ Nao recomendado | ✅ Recomendado |

**Recomendacao:**

1. **Aprenda com Kind** (este projeto)
2. **Pratique conceitos** sem custos
3. **Migre para cloud** quando necessario
4. **Aplique conhecimento** em producao

---

## Proximos Passos

- [ ] Completar este projeto no Kind
- [ ] Entender todos os conceitos
- [ ] Criar conta free tier AWS/GCP (opcional)
- [ ] Experimentar Cluster Autoscaler em cloud
- [ ] Comparar comportamento real vs simulado
- [ ] Estudar Karpenter (alternativa moderna)
