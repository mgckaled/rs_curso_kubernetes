<!-- markdownlint-disable -->

# Cluster Autoscaler - Teoria e Conceitos

## O que e o Cluster Autoscaler?

O Cluster Autoscaler e um componente do Kubernetes que **automaticamente ajusta o numero de nodes** em um cluster baseado na demanda de recursos dos pods.

### Problema que resolve

Imagine o seguinte cenario:

1. **HPA escala pods de 2 para 10** (alta demanda)
2. **Nodes atuais nao tem recursos suficientes** (CPU/memoria esgotados)
3. **Pods ficam em estado Pending** (aguardando recursos)
4. **Aplicacao fica indisponivel** (downtime)

**Solucao:** Cluster Autoscaler detecta pods pending e **adiciona nodes automaticamente** ao cluster.

---

## Como funciona?

### Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                      │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │     HPA      │────────▶│  Deployment  │                 │
│  │  (Pods)      │         │   (Pods)     │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                          │
│         │                         ▼                          │
│         │                  ┌──────────────┐                 │
│         │                  │ Pods Pending │                 │
│         │                  │ (sem recursos)│                 │
│         │                  └──────────────┘                 │
│         │                         │                          │
│         │                         ▼                          │
│         │              ┌─────────────────────┐              │
│         └─────────────▶│ Cluster Autoscaler  │              │
│                        │  (Adiciona Nodes)   │              │
│                        └─────────────────────┘              │
│                                 │                            │
│                                 ▼                            │
│                        ┌─────────────────────┐              │
│                        │   Cloud Provider    │              │
│                        │  (AWS, GCP, Azure)  │              │
│                        └─────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### Processo de Scale Up (Adicionar Nodes)

1. **Deteccao:** Cluster Autoscaler detecta pods em estado Pending
2. **Analise:** Verifica se adicionar um node resolveria o problema
3. **Calculo:** Decide o tipo/tamanho de node necessario
4. **Provisao:** Solicita ao cloud provider criacao de uma VM
5. **Registro:** Node e adicionado ao cluster (kubelet se registra)
6. **Agendamento:** Scheduler agenda pods pending no novo node

**Tempo total:** Geralmente 2-5 minutos (dependendo do cloud provider)

### Processo de Scale Down (Remover Nodes)

1. **Analise:** Cluster Autoscaler identifica nodes subutilizados
2. **Criterios:** Node esta abaixo de 50% de uso por 10+ minutos
3. **Simulacao:** Verifica se pods podem ser movidos para outros nodes
4. **Taint:** Adiciona taint `ToBeDeletedByClusterAutoscaler` no node
5. **Drain:** Remove pods do node (respeitando PodDisruptionBudgets)
6. **Remocao:** Solicita ao cloud provider terminar a VM

**Tempo total:** Geralmente 10-15 minutos (delay intencional para evitar thrashing)

---

## Node Groups (AWS EKS)

No AWS EKS, nodes sao organizados em **Node Groups** (Auto Scaling Groups):

### Configuracao Tipica

```hcl
# Terraform - EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "standard-workers"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  # Configuracao de Auto Scaling
  scaling_config {
    min_size     = 2   # Minimo de nodes
    max_size     = 10  # Maximo de nodes
    desired_size = 3   # Tamanho inicial
  }

  # Tipo de instancia
  instance_types = ["t3.medium"]

  # Labels (usadas pelo Cluster Autoscaler)
  labels = {
    role = "workers"
  }

  # Tags (necessarias para auto-discovery)
  tags = {
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/my-cluster" = "owned"
  }
}
```

### Auto-Discovery

Cluster Autoscaler usa **tags** para descobrir Node Groups automaticamente:

```yaml
# Tags necessarias nos Node Groups
k8s.io/cluster-autoscaler/enabled: "true"
k8s.io/cluster-autoscaler/<cluster-name>: "owned"
```

Alternativamente, pode especificar manualmente:

```yaml
# Deployment do Cluster Autoscaler
command:
  - ./cluster-autoscaler
  - --cloud-provider=aws
  - --nodes=2:10:my-node-group-name
  - --skip-nodes-with-local-storage=false
```

---

## Configuracao e Deployment

### 1. Permissoes IAM (AWS)

Cluster Autoscaler precisa de permissoes para gerenciar Auto Scaling Groups:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"],
      "Condition": {
        "StringEquals": {
          "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/<cluster-name>": "owned"
        }
      }
    }
  ]
}
```

### 2. Service Account (IRSA - IAM Roles for Service Accounts)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    # ARN da IAM Role (IRSA)
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler-role
```

### 3. Deployment do Cluster Autoscaler

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
        - name: cluster-autoscaler
          image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.0
          command:
            - ./cluster-autoscaler
            - --cloud-provider=aws
            - --namespace=kube-system
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/my-cluster
            - --balance-similar-node-groups
            - --skip-nodes-with-local-storage=false
          resources:
            requests:
              cpu: 100m
              memory: 300Mi
            limits:
              cpu: 100m
              memory: 300Mi
```

---

## Metricas e Criterios

### Scale Up Triggers

| Criterio | Descricao |
|----------|-----------|
| Pods Pending | Pods nao podem ser agendados por falta de recursos |
| Resource Requests | Soma de requests excede capacidade disponivel |
| Node Affinity | Pods com affinity nao conseguem ser agendados |

### Scale Down Triggers

| Criterio | Descricao | Valor Padrao |
|----------|-----------|--------------|
| Node Utilization | Uso de CPU/memoria abaixo do limiar | < 50% |
| Unneeded Time | Tempo que node esta subutilizado | 10 minutos |
| Empty Node | Node sem pods (exceto daemonsets) | Imediato |

### Protecoes contra Scale Down

Cluster Autoscaler **NAO remove nodes** se:

- Pods com PDB que nao permite eviction
- Pods com `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"`
- Pods com local storage (volumes emptyDir)
- Pods que nao podem ser movidos (sem ReplicaSet/Deployment)
- Node com annotation `cluster-autoscaler.kubernetes.io/scale-down-disabled: "true"`

---

## Boas Praticas

### 1. Resource Requests

**SEMPRE defina requests** - Cluster Autoscaler usa requests para calcular necessidade de nodes:

```yaml
resources:
  requests:
    cpu: 100m      # OBRIGATORIO
    memory: 128Mi  # OBRIGATORIO
  limits:
    cpu: 500m
    memory: 256Mi
```

### 2. PodDisruptionBudgets

Proteja aplicacoes criticas durante scale down:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

### 3. Node Groups Multiplos

Use multiplos node groups para diferentes tipos de workload:

```yaml
# Node Group 1: Workloads gerais
instance_types = ["t3.medium"]
labels = { workload = "general" }

# Node Group 2: Workloads memoria-intensivos
instance_types = ["r5.large"]
labels = { workload = "memory-intensive" }

# Node Group 3: Workloads com GPU
instance_types = ["p3.2xlarge"]
labels = { workload = "gpu" }
taints = [{ key = "nvidia.com/gpu", value = "true", effect = "NoSchedule" }]
```

### 4. Limits de Escala

Defina limites sensatos para evitar custos excessivos:

```yaml
scaling_config {
  min_size = 2    # Sempre 2 nodes para HA
  max_size = 20   # Maximo de 20 nodes (protecao de custo)
  desired_size = 3
}
```

### 5. Monitoramento

Monitore metricas do Cluster Autoscaler:

```bash
# Logs do Cluster Autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Eventos de scaling
kubectl get events -n kube-system --sort-by='.lastTimestamp' | grep cluster-autoscaler

# Status dos nodes
kubectl get nodes -o wide
kubectl top nodes
```

---

## Comparacao: Cluster Autoscaler vs HPA

| Aspecto | HPA (Horizontal Pod Autoscaler) | Cluster Autoscaler |
|---------|--------------------------------|-------------------|
| **Escala** | Pods (replicas) | Nodes (VMs) |
| **Trigger** | Metricas (CPU, memoria, custom) | Pods pending |
| **Tempo** | 15-30 segundos | 2-5 minutos |
| **Custo** | Sem custo adicional | Custo de VMs adicionais |
| **Requisitos** | Metrics Server | Cloud provider |
| **Uso** | Escala aplicacao | Escala infraestrutura |

### Trabalhando Juntos

HPA e Cluster Autoscaler **sao complementares**:

1. **HPA escala pods** quando CPU/memoria aumenta
2. **Pods ficam Pending** se nao houver recursos
3. **Cluster Autoscaler adiciona nodes** para acomodar pods
4. **Pods sao agendados** nos novos nodes
5. **Aplicacao escala com sucesso**

```
Alta demanda → HPA ↑ pods → Pending → CA ↑ nodes → Pods scheduled
Baixa demanda → HPA ↓ pods → Nodes vazios → CA ↓ nodes → Economia
```

---

## Limitacoes e Consideracoes

### 1. Tempo de Provisionamento

- **Scale up:** 2-5 minutos (tempo de boot da VM)
- **Solucao:** Mantenha buffer de nodes (min_size > 0)

### 2. Custos

- Nodes adicionais = custos adicionais
- **Solucao:** Configure max_size e monitore gastos

### 3. Zona de Disponibilidade

- Cluster Autoscaler pode criar nodes em zonas diferentes
- **Solucao:** Configure node groups por zona ou use topology spread

### 4. Stateful Workloads

- Pods com volumes podem nao ser movidos facilmente
- **Solucao:** Use annotation `cluster-autoscaler.kubernetes.io/safe-to-evict: "true"`

### 5. Spot Instances

- Spot instances podem ser terminadas a qualquer momento
- **Solucao:** Combine com on-demand nodes e use tolerations

---

## Alternativas

### Karpenter (AWS)

Alternativa moderna ao Cluster Autoscaler para AWS:

**Vantagens:**
- Provisiona nodes em ~30 segundos (vs 2-5 minutos)
- Mais flexivel (mix de instance types automatico)
- Consolidacao automatica (bin-packing)

**Desvantagens:**
- Apenas AWS (por enquanto)
- Mais complexo de configurar

### GKE Cluster Autoscaler

Google Kubernetes Engine tem autoscaler nativo integrado.

### AKS Cluster Autoscaler

Azure Kubernetes Service tem autoscaler nativo integrado.

---

## Recursos Adicionais

- [Documentacao oficial do Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [AWS EKS Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html)
- [FAQ do Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)
- [Karpenter](https://karpenter.sh/)
