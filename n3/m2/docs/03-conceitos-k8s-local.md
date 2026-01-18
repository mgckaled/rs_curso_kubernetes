<!-- markdownlint-disable -->

# Conceitos Kubernetes Aplicáveis Localmente

## Índice

- [Visão Geral](#visão-geral)
- [Topology Spread Constraints](#topology-spread-constraints)
- [Node Affinity](#node-affinity)
- [Pod Anti-Affinity](#pod-anti-affinity)
- [Taints e Tolerations](#taints-e-tolerations)
- [Resource Requests e Limits](#resource-requests-e-limits)
- [Priority Classes](#priority-classes)
- [PodDisruptionBudgets](#poddisruptionbudgets)
- [Simulando Ambientes Cloud no Kind](#simulando-ambientes-cloud-no-kind)

## Visão Geral

Embora o Karpenter seja específico para AWS, os conceitos de scheduling que ele utiliza são **nativos do Kubernetes** e podem ser praticados localmente. Este documento explica como implementar esses conceitos no Kind.

### Conceitos Abordados

1. **Topology Spread Constraints:** Distribuição uniforme entre zonas
2. **Node Affinity:** Preferências e restrições de nós
3. **Pod Anti-Affinity:** Evitar co-localização de pods
4. **Taints e Tolerations:** Controle de agendamento
5. **Resource Requests/Limits:** Gerenciamento de recursos
6. **Priority Classes:** Priorização de workloads
7. **PodDisruptionBudgets:** Garantia de disponibilidade

## Topology Spread Constraints

### O que é

Garante que pods sejam distribuídos uniformemente entre diferentes topologias (zonas, nós, racks).

### Por que é importante

- **Alta disponibilidade:** Evita concentração em uma única zona
- **Balanceamento de carga:** Distribui tráfego uniformemente
- **Resiliência:** Minimiza impacto de falhas de zona/nó

### Como funciona

O scheduler calcula o "skew" (desvio) entre domínios de topologia e tenta minimizá-lo.

**Exemplo:**

```
Zona A: 3 pods
Zona B: 2 pods
Zona C: 2 pods

Skew máximo: 3 - 2 = 1 (aceitável se maxSkew: 1)
```

### Manifest Básico

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api
spec:
  replicas: 6
  selector:
    matchLabels:
      app: demo-api
  template:
    metadata:
      labels:
        app: demo-api
    spec:
      topologySpreadConstraints:
        # Distribui entre zonas
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: demo-api
      containers:
        - name: demo-api
          image: demo-api:v1
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
```

### Campos Principais

#### maxSkew

Diferença máxima permitida entre domínios.

```yaml
maxSkew: 1  # Diferença máxima de 1 pod entre zonas
```

**Exemplo com maxSkew: 1 e 6 réplicas em 3 zonas:**

```
Zona A: 2 pods
Zona B: 2 pods
Zona C: 2 pods
Skew: 0 (perfeito)
```

**Exemplo com maxSkew: 2 e 7 réplicas em 3 zonas:**

```
Zona A: 3 pods
Zona B: 2 pods
Zona C: 2 pods
Skew: 1 (ok, dentro do limite)
```

#### topologyKey

Label usada para definir domínios de topologia.

```yaml
# Distribuir entre zonas
topologyKey: topology.kubernetes.io/zone

# Distribuir entre nós (1 pod por nó)
topologyKey: kubernetes.io/hostname

# Distribuir entre tipos de instância
topologyKey: node.kubernetes.io/instance-type
```

#### whenUnsatisfiable

O que fazer quando constraint não pode ser satisfeita.

```yaml
# Não agendar (rígido)
whenUnsatisfiable: DoNotSchedule

# Agendar mesmo assim (preferência)
whenUnsatisfiable: ScheduleAnyway
```

#### labelSelector

Seleciona quais pods considerar no cálculo de skew.

```yaml
labelSelector:
  matchLabels:
    app: demo-api
    version: v1
```

### Exemplo Avançado: Múltiplas Constraints

```yaml
topologySpreadConstraints:
  # Distribui entre zonas (maxSkew: 1)
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: demo-api

  # Distribui entre nós (maxSkew: 2)
  - maxSkew: 2
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: demo-api
```

### Simulação no Kind

No Kind, simulamos zonas com labels:

```bash
# Label nós como zonas diferentes
kubectl label node karpenter-demo-worker topology.kubernetes.io/zone=zone-a
kubectl label node karpenter-demo-worker2 topology.kubernetes.io/zone=zone-b
kubectl label node karpenter-demo-worker3 topology.kubernetes.io/zone=zone-c
```

## Node Affinity

### O que é

Define regras para agendar pods em nós específicos baseado em labels dos nós.

### Tipos

1. **requiredDuringSchedulingIgnoredDuringExecution:** Regra obrigatória (hard)
2. **preferredDuringSchedulingIgnoredDuringExecution:** Regra preferencial (soft)

### Manifest Básico

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-api
spec:
  affinity:
    nodeAffinity:
      # Regra obrigatória
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In
                values:
                  - t3.medium
                  - t3.large
              - key: topology.kubernetes.io/zone
                operator: NotIn
                values:
                  - zone-c

      # Regra preferencial (peso 100)
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                  - zone-a
  containers:
    - name: demo-api
      image: demo-api:v1
```

### Operadores Disponíveis

```yaml
# In: Valor deve estar na lista
operator: In
values: ["t3.medium", "t3.large"]

# NotIn: Valor NÃO deve estar na lista
operator: NotIn
values: ["zone-c"]

# Exists: Label deve existir (ignora valores)
operator: Exists

# DoesNotExist: Label NÃO deve existir
operator: DoesNotExist

# Gt: Maior que (valores numéricos)
operator: Gt
values: ["10"]

# Lt: Menor que (valores numéricos)
operator: Lt
values: ["100"]
```

### Exemplo: Preferir SSD mas aceitar HDD

```yaml
affinity:
  nodeAffinity:
    # Preferir nós com SSD (peso 80)
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
        preference:
          matchExpressions:
            - key: disk-type
              operator: In
              values:
                - ssd

      # Preferir zonas A ou B (peso 50)
      - weight: 50
        preference:
          matchExpressions:
            - key: topology.kubernetes.io/zone
              operator: In
              values:
                - zone-a
                - zone-b
```

### Simulação no Kind

```bash
# Simular tipos de instância
kubectl label node karpenter-demo-worker node.kubernetes.io/instance-type=t3.medium
kubectl label node karpenter-demo-worker2 node.kubernetes.io/instance-type=t3.large
kubectl label node karpenter-demo-worker3 node.kubernetes.io/instance-type=c5.xlarge

# Simular tipos de disco
kubectl label node karpenter-demo-worker disk-type=ssd
kubectl label node karpenter-demo-worker2 disk-type=ssd
kubectl label node karpenter-demo-worker3 disk-type=hdd
```

## Pod Anti-Affinity

### O que é

Evita que pods sejam agendados no mesmo domínio de topologia (nó, zona, rack).

### Por que usar

- **Alta disponibilidade:** Múltiplas réplicas em nós diferentes
- **Balanceamento:** Evitar sobrecarga de um único nó
- **Isolamento:** Separar workloads conflitantes

### Manifest Básico

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-api
  template:
    metadata:
      labels:
        app: demo-api
    spec:
      affinity:
        podAntiAffinity:
          # Obrigatório: 1 pod por nó
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: demo-api
              topologyKey: kubernetes.io/hostname

          # Preferencial: Evitar mesma zona
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: demo-api
                topologyKey: topology.kubernetes.io/zone
      containers:
        - name: demo-api
          image: demo-api:v1
```

### Exemplo: Evitar co-localização de Cache e Database

```yaml
# Pod de Database
apiVersion: v1
kind: Pod
metadata:
  name: postgres
  labels:
    app: postgres
    tier: database
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: tier
                operator: In
                values:
                  - cache
          topologyKey: kubernetes.io/hostname
  containers:
    - name: postgres
      image: postgres:17
```

## Taints e Tolerations

### O que são

- **Taint:** Marca no nó que repele pods
- **Toleration:** Marca no pod que tolera um taint

### Effects de Taint

```yaml
# NoSchedule: Não agenda novos pods (existentes permanecem)
effect: NoSchedule

# PreferNoSchedule: Tenta evitar mas não garante
effect: PreferNoSchedule

# NoExecute: Remove pods existentes que não toleram
effect: NoExecute
```

### Aplicar Taint no Nó

```bash
# Marcar nó como dedicado para banco de dados
kubectl taint nodes karpenter-demo-worker workload-type=database:NoSchedule

# Marcar nó como GPU
kubectl taint nodes karpenter-demo-worker2 gpu=true:NoSchedule

# Remover taint
kubectl taint nodes karpenter-demo-worker workload-type-
```

### Toleration no Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres
spec:
  tolerations:
    # Tolera taint específico
    - key: workload-type
      operator: Equal
      value: database
      effect: NoSchedule

    # Tolera qualquer valor para a key
    - key: gpu
      operator: Exists
      effect: NoSchedule
  containers:
    - name: postgres
      image: postgres:17
```

### Exemplo Prático: Isolar Workloads

```bash
# Criar taint em nó para produção
kubectl taint nodes karpenter-demo-worker environment=production:NoSchedule
```

```yaml
# Deployment de produção
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-api
      env: production
  template:
    metadata:
      labels:
        app: demo-api
        env: production
    spec:
      tolerations:
        - key: environment
          operator: Equal
          value: production
          effect: NoSchedule
      containers:
        - name: demo-api
          image: demo-api:v1
```

## Resource Requests e Limits

### O que são

- **Requests:** Recursos mínimos garantidos
- **Limits:** Recursos máximos permitidos

### Por que são importantes

- **Scheduling:** Scheduler usa requests para decidir onde alocar pods
- **QoS:** Define classe de Quality of Service
- **Bin Packing:** Permite consolidação eficiente

### Classes QoS

```yaml
# Guaranteed: requests = limits (melhor QoS)
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Burstable: requests < limits (QoS média)
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

# BestEffort: sem requests/limits (pior QoS)
# Omitir resources
```

### Manifest Completo

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-api
spec:
  containers:
    - name: demo-api
      image: demo-api:v1
      resources:
        requests:
          cpu: 250m        # 0.25 CPU core
          memory: 256Mi    # 256 MiB de RAM
        limits:
          cpu: 500m        # 0.5 CPU core (pode burst até aqui)
          memory: 512Mi    # 512 MiB de RAM (limite rígido)
```

### Boas Práticas

```yaml
# Aplicação web (burstable)
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Banco de dados (guaranteed)
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 1000m
    memory: 2Gi

# Job batch (burstable com headroom)
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 4Gi
```

## Priority Classes

### O que é

Define prioridade relativa entre pods para decisões de scheduling e preempção.

### Criar Priority Class

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "Workloads críticos de produção"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 1000
globalDefault: true
description: "Workloads padrão"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Jobs batch não críticos"
```

### Usar no Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-api
spec:
  priorityClassName: high-priority
  containers:
    - name: api
      image: api:v1
```

### Preempção

Pods de alta prioridade podem **preemptar** (remover) pods de baixa prioridade se não houver recursos.

**Exemplo:**

```
Nó tem: 2 CPUs disponíveis
Rodando: 2x pods low-priority (1 CPU cada)
Novo pod: high-priority (precisa 2 CPUs)

Resultado: Kubernetes remove os 2 pods low-priority para agendar high-priority
```

## PodDisruptionBudgets

### O que é

Garante que um número mínimo de pods permaneça disponível durante manutenções voluntárias (drains, upgrades).

### Manifest Básico

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-api-pdb
spec:
  # Mínimo de 2 pods disponíveis
  minAvailable: 2

  # OU: Máximo de 1 pod indisponível
  # maxUnavailable: 1

  selector:
    matchLabels:
      app: demo-api
```

### Tipos de Configuração

```yaml
# Número absoluto
minAvailable: 2
maxUnavailable: 1

# Porcentagem
minAvailable: 80%
maxUnavailable: 20%
```

### Exemplo Completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api
spec:
  replicas: 5
  selector:
    matchLabels:
      app: demo-api
  template:
    metadata:
      labels:
        app: demo-api
    spec:
      containers:
        - name: demo-api
          image: demo-api:v1
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-api-pdb
spec:
  minAvailable: 3  # Mínimo 3 de 5 pods disponíveis
  selector:
    matchLabels:
      app: demo-api
```

### Testando PDB

```bash
# Tentar drenar nó (respeitará PDB)
kubectl drain karpenter-demo-worker --ignore-daemonsets --delete-emptydir-data

# Ver status do PDB
kubectl get pdb
NAME             MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
demo-api-pdb     3               N/A               2                     5m
```

## Simulando Ambientes Cloud no Kind

### Estrutura do Cluster

```yaml
# manifests/00-cluster-kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
  - role: worker
```

### Labels de Simulação

```bash
# Simular zonas AWS
kubectl label node karpenter-demo-worker topology.kubernetes.io/zone=us-east-1a
kubectl label node karpenter-demo-worker2 topology.kubernetes.io/zone=us-east-1b
kubectl label node karpenter-demo-worker3 topology.kubernetes.io/zone=us-east-1c

# Simular tipos de instância
kubectl label node karpenter-demo-worker node.kubernetes.io/instance-type=t3.medium
kubectl label node karpenter-demo-worker2 node.kubernetes.io/instance-type=t3.large
kubectl label node karpenter-demo-worker3 node.kubernetes.io/instance-type=c5.xlarge

# Simular famílias de instância
kubectl label node karpenter-demo-worker karpenter.k8s.aws/instance-family=t3
kubectl label node karpenter-demo-worker2 karpenter.k8s.aws/instance-family=t3
kubectl label node karpenter-demo-worker3 karpenter.k8s.aws/instance-family=c5

# Simular tipo de capacidade
kubectl label node karpenter-demo-worker karpenter.sh/capacity-type=on-demand
kubectl label node karpenter-demo-worker2 karpenter.sh/capacity-type=on-demand
kubectl label node karpenter-demo-worker3 karpenter.sh/capacity-type=spot

# Simular tipo de disco
kubectl label node karpenter-demo-worker disk-type=ssd
kubectl label node karpenter-demo-worker2 disk-type=ssd
kubectl label node karpenter-demo-worker3 disk-type=nvme
```

### Verificar Labels

```bash
# Ver todos labels de um nó
kubectl get node karpenter-demo-worker --show-labels

# Filtrar labels específicos
kubectl get nodes -L topology.kubernetes.io/zone,node.kubernetes.io/instance-type,disk-type
```

## Combinando Conceitos

### Exemplo: Deployment Production-Ready

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api
  namespace: karpenter-demo
spec:
  replicas: 6
  selector:
    matchLabels:
      app: demo-api
      tier: application
  template:
    metadata:
      labels:
        app: demo-api
        tier: application
    spec:
      # 1. Priority Class
      priorityClassName: high-priority

      # 2. Topology Spread
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: demo-api

      # 3. Node Affinity
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: karpenter.sh/capacity-type
                    operator: In
                    values:
                      - on-demand
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              preference:
                matchExpressions:
                  - key: disk-type
                    operator: In
                    values:
                      - ssd

        # 4. Pod Anti-Affinity
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: demo-api
                topologyKey: kubernetes.io/hostname

      # 5. Tolerations
      tolerations:
        - key: production
          operator: Equal
          value: "true"
          effect: NoSchedule

      containers:
        - name: demo-api
          image: demo-api:v1
          # 6. Resources
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
# 7. PodDisruptionBudget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-api-pdb
  namespace: karpenter-demo
spec:
  minAvailable: 4
  selector:
    matchLabels:
      app: demo-api
```

## Próximos Passos

1. Explore os manifests práticos em `manifests/local-implementation/`
2. Execute os scripts de teste em `scripts/`
3. Experimente modificar parâmetros e observar comportamento
4. Combine múltiplos conceitos em cenários realistas

## Referências

- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
