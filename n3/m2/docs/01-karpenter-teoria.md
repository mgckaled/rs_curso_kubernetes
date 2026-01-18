<!-- markdownlint-disable -->

# Karpenter: Teoria e Fundamentos

## Índice

- [O que é o Karpenter](#o-que-é-o-karpenter)
- [Cluster Autoscaler vs Karpenter](#cluster-autoscaler-vs-karpenter)
- [Arquitetura do Karpenter](#arquitetura-do-karpenter)
- [Componentes Principais](#componentes-principais)
- [Como o Karpenter Funciona](#como-o-karpenter-funciona)
- [Vantagens e Casos de Uso](#vantagens-e-casos-de-uso)

## O que é o Karpenter

O Karpenter é um **auto-scaler de nós open-source** para Kubernetes, desenvolvido originalmente pela AWS e posteriormente doado à Cloud Native Computing Foundation (CNCF). Ele automatiza o provisionamento de nós (nodes) de forma inteligente e eficiente, observando pods não agendáveis e criando nós adequados para executá-los.

### Características Principais

- **Provisionamento Just-in-Time:** Cria nós sob demanda quando há pods pendentes
- **Bin Packing Inteligente:** Otimiza o uso de recursos consolidando workloads
- **Consolidação Automática:** Remove ou substitui nós subutilizados
- **Suporte Multi-Cloud:** AWS (nativo), Azure, Oracle Cloud, e outros via providers
- **Custom Resource Definitions (CRDs):** Configuração declarativa via manifests Kubernetes

### Contexto Histórico

Antes do Karpenter, o **Cluster Autoscaler (CAS)** era a solução padrão para auto-scaling de nós. O Karpenter surgiu para resolver limitações específicas do CAS, especialmente em ambientes AWS.

## Cluster Autoscaler vs Karpenter

### Cluster Autoscaler (CAS)

#### Como Funciona

O CAS opera sobre **Auto Scaling Groups (ASG)** da AWS:

1. Monitora pods em estado `Pending` (não agendáveis)
2. Identifica qual ASG pode acomodar esses pods
3. Aumenta o tamanho desejado do ASG
4. Aguarda a EC2 criar e registrar a instância
5. Aguarda o nó se tornar `Ready` no Kubernetes

#### Limitações

- **Dependência de ASGs:** Requer pré-configuração de múltiplos ASGs
- **Granularidade Limitada:** Cada ASG tem tipo de instância fixo
- **Latência Alta:** Processo de scaling é lento (ASG → EC2 → Node)
- **Overhead de Gerenciamento:** Múltiplos ASGs para múltiplos tipos de instância
- **Bin Packing Subótimo:** Não otimiza o empacotamento de recursos

### Karpenter

#### Como Funciona

O Karpenter interage **diretamente com a API EC2**:

1. Monitora pods em estado `Pending`
2. Analisa os requisitos de recursos (CPU, memória, GPU, etc.)
3. Calcula o tipo de instância EC2 ideal
4. Provisiona a instância diretamente via API EC2
5. Registra o nó no cluster Kubernetes

#### Vantagens

- **Sem ASGs:** Provisiona instâncias diretamente
- **Seleção Inteligente:** Escolhe o tipo de instância ideal automaticamente
- **Bin Packing Otimizado:** Maximiza utilização de recursos
- **Latência Reduzida:** Provisionamento mais rápido
- **Consolidação Automática:** Substitui nós subutilizados por menores
- **Configuração Simplificada:** NodePools ao invés de múltiplos ASGs

## Arquitetura do Karpenter

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Karpenter Controller                     │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │  │
│  │  │ Provisioner│  │Consolidator│  │  Disruption│     │  │
│  │  └────────────┘  └────────────┘  └────────────┘     │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Kubernetes API Server                       │  │
│  │  - Watches Pending Pods                               │  │
│  │  - Manages Node Registration                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────────┐
         │          AWS Cloud API                │
         │  ┌─────────────────────────────────┐ │
         │  │  EC2 API (Launch Instances)     │ │
         │  └─────────────────────────────────┘ │
         │  ┌─────────────────────────────────┐ │
         │  │  IAM (Roles & Permissions)      │ │
         │  └─────────────────────────────────┘ │
         │  ┌─────────────────────────────────┐ │
         │  │  VPC (Subnets & Security Groups)│ │
         │  └─────────────────────────────────┘ │
         └──────────────────────────────────────┘
```

### Fluxo de Operação

1. **Detecção:** Karpenter observa pods `Pending` via Kubernetes API
2. **Análise:** Calcula requisitos agregados (CPU, memória, labels, taints)
3. **Seleção:** Escolhe tipo(s) de instância EC2 adequados
4. **Provisionamento:** Cria instância EC2 via API (com user data para join)
5. **Registro:** Aguarda nó aparecer no cluster como `Ready`
6. **Agendamento:** Kubernetes scheduler agenda os pods pendentes
7. **Consolidação:** Continuamente avalia se nós podem ser otimizados

## Componentes Principais

### 1. Karpenter Controller

Aplicação central executando como Deployment no cluster.

**Responsabilidades:**

- Observar eventos de pods e nós
- Calcular decisões de provisionamento
- Gerenciar ciclo de vida de nós
- Executar consolidação e disruption

### 2. NodePool (Custom Resource)

Define **como** e **quais** nós podem ser criados.

**Configurações Principais:**

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        name: default
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
  limits:
    cpu: "1000"
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
```

### 3. NodeClass (EC2NodeClass para AWS)

Define a **configuração específica da cloud** para instâncias.

**Configurações Principais:**

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  role: KarpenterNodeRole
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
  userData: |
    #!/bin/bash
    echo "Custom user data"
```

### 4. IAM Roles (AWS)

#### Controller Role

Permite o Karpenter gerenciar recursos AWS.

**Permissões Necessárias:**

- `ec2:RunInstances`
- `ec2:TerminateInstances`
- `ec2:DescribeInstances`
- `ec2:DescribeInstanceTypes`
- `ec2:DescribeSubnets`
- `ec2:DescribeSecurityGroups`
- `iam:PassRole`

#### Node Role (Instance Profile)

Permite nós EC2 se registrarem no cluster.

**Permissões Necessárias:**

- `ecr:GetAuthorizationToken`
- `ecr:BatchGetImage`
- `eks:DescribeCluster`
- Políticas gerenciadas AWS: `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`

## Como o Karpenter Funciona

### Processo de Provisionamento

#### 1. Detecção de Pods Pendentes

```bash
# Karpenter observa pods como este:
kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
demo-api-6d8f7b9-abc12   0/1     Pending   0          10s
```

#### 2. Análise de Requisitos

Karpenter examina o pod spec:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
nodeSelector:
  topology.kubernetes.io/zone: us-east-1a
tolerations:
  - key: workload-type
    value: api
    effect: NoSchedule
```

#### 3. Cálculo de Bin Packing

Karpenter agrupa múltiplos pods pendentes e calcula:

- Total de CPU necessária
- Total de memória necessária
- Labels e taints compatíveis
- Restrições de zona e topologia

#### 4. Seleção de Tipo de Instância

Karpenter escolhe a instância mais econômica que atende aos requisitos:

```
Pods pendentes: 3x (500m CPU, 512Mi RAM)
Total agregado: 1.5 CPU, 1.5Gi RAM

Opções consideradas:
- t3.medium (2 vCPU, 4Gi) → Escolhida (mais econômica)
- t3.large (2 vCPU, 8Gi) → Rejeitada (oversized)
- c5.large (2 vCPU, 4Gi) → Rejeitada (mais cara)
```

#### 5. Provisionamento via EC2 API

```bash
# Karpenter executa algo equivalente a:
aws ec2 run-instances \
  --image-id ami-0abcd1234 \
  --instance-type t3.medium \
  --subnet-id subnet-xyz \
  --security-group-ids sg-abc \
  --iam-instance-profile Name=KarpenterNodeInstanceProfile \
  --user-data-file bootstrap.sh
```

#### 6. Registro no Cluster

O nó inicializado executa:

```bash
# User data script
#!/bin/bash
/etc/eks/bootstrap.sh my-cluster-name
```

#### 7. Nó Pronto e Pods Agendados

```bash
kubectl get nodes
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-1-100.ec2.internal   Ready    <none>   2m    v1.34.0

kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
demo-api-6d8f7b9-abc12   1/1     Running   0          3m
```

### Processo de Consolidação

#### Cenário: Nós Subutilizados

```
Node A: 10% CPU usado (2 pods pequenos)
Node B: 15% CPU usado (3 pods pequenos)
Node C: 80% CPU usado (muitos pods)
```

#### Ação do Karpenter

1. **Identifica oportunidade:** Pods de A e B cabem em um único nó menor
2. **Provisiona novo nó:** Cria instância t3.small
3. **Drena pods:** Move pods de A e B para o novo nó
4. **Termina nós antigos:** Exclui Node A e Node B
5. **Resultado:** Economia de custos (2 nós → 1 nó menor)

### Processo de Disruption

Karpenter gerencia **interrupções controladas** de nós:

#### Tipos de Disruption

1. **Consolidation:** Otimização de custos (nós subutilizados)
2. **Expiration:** Nós antigos além do TTL
3. **Drift:** Nós que não atendem mais o NodePool spec
4. **Spot Interruption:** Instâncias spot sendo reclamadas pela AWS

#### Políticas de Disruption

```yaml
disruption:
  consolidationPolicy: WhenUnderutilized
  consolidateAfter: 30s
  expireAfter: 720h
  budgets:
    - nodes: 10%
      reasons: ["Underutilized", "Empty"]
    - nodes: 5
      reasons: ["Drifted"]
```

## Vantagens e Casos de Uso

### Vantagens

#### 1. Provisionamento Rápido

- Latência reduzida em 30-50% comparado ao CAS
- Sem overhead de gerenciamento de ASGs

#### 2. Otimização de Custos

- Bin packing inteligente maximiza utilização
- Consolidação automática reduz nós ociosos
- Suporte nativo a Spot Instances

#### 3. Configuração Simplificada

- NodePools declarativos ao invés de múltiplos ASGs
- Menos recursos AWS para gerenciar

#### 4. Flexibilidade

- Seleção automática de tipos de instância
- Suporte a requisitos heterogêneos
- Políticas de disruption customizáveis

### Casos de Uso

#### Workloads Dinâmicos

Aplicações com picos de tráfego imprevisíveis que necessitam escalar rapidamente.

**Exemplo:** E-commerce durante Black Friday

#### Batch Processing

Jobs que requerem recursos massivos por curto período.

**Exemplo:** Processamento de vídeos, treinamento de ML

#### Ambientes Multi-Tenant

Clusters compartilhados com workloads de diferentes times.

**Exemplo:** Plataforma SaaS com múltiplos clientes

#### Otimização de Custos

Ambientes onde economia é prioridade.

**Exemplo:** Clusters de desenvolvimento/staging

## Limitações e Considerações

### Limitações

1. **Cloud-Specific:** Requer provider específico (AWS, Azure, etc.)
2. **Complexidade Inicial:** Curva de aprendizado para IAM roles
3. **Não é "Serverless":** Ainda gerencia instâncias EC2 reais
4. **Latência de Cold Start:** Provisionamento leva ~2-3 minutos

### Considerações

- Requer permissões IAM privilegiadas
- Necessita configuração de VPC/subnets adequada
- Recomendado usar com PodDisruptionBudgets
- Monitoramento de custos é essencial

## Comparação Final: CAS vs Karpenter

| Aspecto | Cluster Autoscaler | Karpenter |
|---------|-------------------|-----------|
| Abstração | Auto Scaling Groups | API EC2 Direta |
| Seleção de Instância | Fixo por ASG | Dinâmica e inteligente |
| Latência de Scaling | 3-5 minutos | 2-3 minutos |
| Bin Packing | Básico | Otimizado |
| Consolidação | Não | Sim (automática) |
| Configuração | Múltiplos ASGs | NodePools declarativos |
| Complexidade | Média | Média-Alta (IAM) |
| Maturidade | Estável (CNCF) | Em crescimento (CNCF) |

## Próximos Passos

Agora que você compreende a teoria do Karpenter:

1. Leia [02-nodepool-nodeclass.md](./02-nodepool-nodeclass.md) para detalhes de configuração
2. Leia [03-conceitos-k8s-local.md](./03-conceitos-k8s-local.md) para entender a implementação local
3. Explore os manifests de referência em `manifests/aws-reference/`
4. Pratique os conceitos de scheduling em `manifests/local-implementation/`

## Referências

- [Documentação Oficial Karpenter](https://karpenter.sh/)
- [Karpenter GitHub](https://github.com/aws/karpenter-provider-aws)
- [Best Practices Guide](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [CNCF Karpenter](https://www.cncf.io/projects/karpenter/)
