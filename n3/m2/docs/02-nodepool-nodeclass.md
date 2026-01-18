<!-- markdownlint-disable -->

# NodePool e NodeClass: Configuração do Karpenter

## Índice

- [Visão Geral](#visão-geral)
- [NodePool](#nodepool)
- [NodeClass (EC2NodeClass)](#nodeclass-ec2nodeclass)
- [Requisitos AWS](#requisitos-aws)
- [Exemplos Práticos](#exemplos-práticos)
- [Melhores Práticas](#melhores-práticas)

## Visão Geral

O Karpenter utiliza dois Custom Resources principais para configurar o provisionamento de nós:

1. **NodePool:** Define **políticas** de provisionamento (quais tipos, limites, disruption)
2. **NodeClass:** Define **configuração da cloud** (AMI, IAM, networking)

Essa separação permite reutilizar NodeClasses entre diferentes NodePools.

## NodePool

### O que é

O **NodePool** é um Custom Resource que define um grupo lógico de nós com características e políticas comuns. Ele especifica:

- Requisitos de recursos (CPU, memória, arquitetura)
- Limites de capacidade total
- Políticas de disruption e consolidação
- Referência à NodeClass

### Estrutura do Manifest

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  # Referência à NodeClass
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default

      # Requisitos para nós deste pool
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.medium", "t3.large", "t3.xlarge"]

      # Taints aplicados aos nós
      taints:
        - key: workload-type
          value: api
          effect: NoSchedule

      # Labels aplicados aos nós
      labels:
        team: platform
        environment: production

  # Limites de capacidade total do pool
  limits:
    cpu: "1000"
    memory: 1000Gi

  # Peso para priorização (maior = maior prioridade)
  weight: 10

  # Políticas de disruption
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
    expireAfter: 720h # 30 dias
    budgets:
      - nodes: 10%
```

### Campos Principais

#### template.spec.nodeClassRef

Referência à NodeClass que contém configurações específicas da cloud.

```yaml
nodeClassRef:
  group: karpenter.k8s.aws
  kind: EC2NodeClass
  name: default
```

#### template.spec.requirements

Define restrições e preferências para os nós. Usa operadores similares ao nodeSelector.

**Operadores disponíveis:**

- `In`: Valor deve estar na lista
- `NotIn`: Valor não deve estar na lista
- `Exists`: Chave deve existir (ignora valores)
- `DoesNotExist`: Chave não deve existir
- `Gt`: Maior que (para valores numéricos)
- `Lt`: Menor que (para valores numéricos)

**Keys comuns:**

```yaml
requirements:
  # Tipo de capacidade: on-demand ou spot
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand", "spot"]

  # Arquitetura: amd64 ou arm64
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64"]

  # Tipos de instância permitidos
  - key: node.kubernetes.io/instance-type
    operator: In
    values: ["t3.medium", "t3.large"]

  # Zona de disponibilidade
  - key: topology.kubernetes.io/zone
    operator: In
    values: ["us-east-1a", "us-east-1b"]

  # Família de instância
  - key: karpenter.k8s.aws/instance-family
    operator: In
    values: ["t3", "t3a"]

  # Geração de instância
  - key: karpenter.k8s.aws/instance-generation
    operator: Gt
    values: ["2"]
```

#### limits

Define capacidade máxima total que o NodePool pode provisionar.

```yaml
limits:
  cpu: "1000"      # 1000 CPUs totais
  memory: 1000Gi   # 1000 GiB de memória total
```

Karpenter soma os recursos de todos os nós e impede provisionamento se limites forem excedidos.

#### disruption

Controla como e quando o Karpenter pode interromper nós.

```yaml
disruption:
  # Política de consolidação
  consolidationPolicy: WhenUnderutilized

  # Tempo de espera antes de consolidar
  consolidateAfter: 30s

  # TTL do nó (tempo máximo de vida)
  expireAfter: 720h

  # Budgets de disruption
  budgets:
    - nodes: 10%
      reasons: ["Underutilized", "Empty"]
      schedule: "0 9 * * MON-FRI"
    - nodes: 5
      reasons: ["Drifted"]
```

**consolidationPolicy:**

- `WhenEmpty`: Apenas quando nó está vazio
- `WhenUnderutilized`: Quando nó está subutilizado (default)

**budgets:** Limita quantos nós podem ser disruptados simultaneamente.

## NodeClass (EC2NodeClass)

### O que é

O **EC2NodeClass** é um Custom Resource específico da AWS que define a configuração técnica das instâncias EC2:

- AMI (Amazon Machine Image)
- IAM Instance Profile
- Subnets e Security Groups
- Block Device Mappings (discos)
- User Data (script de inicialização)

### Estrutura do Manifest

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  # Família de AMI (gerenciada pelo Karpenter)
  amiFamily: AL2023

  # IAM Role para o nó
  role: KarpenterNodeRole

  # Seleção de subnets via tags
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
        tier: private

  # Seleção de security groups via tags
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
        type: node

  # Configuração de discos
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 3000
        throughput: 125
        encrypted: true
        deleteOnTermination: true

  # Tags aplicadas às instâncias EC2
  tags:
    Environment: production
    ManagedBy: karpenter
    Team: platform

  # Metadata options
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 2
    httpTokens: required

  # User data customizado
  userData: |
    #!/bin/bash
    echo "Custom initialization"
    # Configurações adicionais aqui
```

### Campos Principais

#### amiFamily

Define qual família de AMI o Karpenter deve usar.

**Opções disponíveis:**

- `AL2023`: Amazon Linux 2023 (recomendado)
- `AL2`: Amazon Linux 2
- `Bottlerocket`: Bottlerocket OS (focado em segurança)
- `Ubuntu`: Ubuntu 20.04/22.04
- `Windows2019`: Windows Server 2019
- `Windows2022`: Windows Server 2022
- `Custom`: AMI customizada (requer AMI ID)

```yaml
# Amazon Linux 2023
amiFamily: AL2023

# Bottlerocket (segurança)
amiFamily: Bottlerocket

# Ubuntu
amiFamily: Ubuntu

# Custom AMI
amiSelectorTerms:
  - id: ami-0abcd1234efgh5678
```

#### role

Nome da IAM Role (sem ARN) que será anexada como Instance Profile.

```yaml
role: KarpenterNodeRole
```

O Karpenter automaticamente cria o Instance Profile a partir desse Role.

#### subnetSelectorTerms

Define quais subnets podem ser usadas. Usa tags para seleção dinâmica.

```yaml
subnetSelectorTerms:
  # Seleção por tag de descoberta
  - tags:
      karpenter.sh/discovery: my-cluster

  # Seleção por múltiplas tags (AND)
  - tags:
      karpenter.sh/discovery: my-cluster
      tier: private
      availability: high

  # Seleção por subnet ID direta
  - id: subnet-0abcd1234
```

**Melhores práticas:**

- Use apenas subnets privadas
- Distribua entre múltiplas AZs
- Certifique-se que subnets têm espaço de IP suficiente

#### securityGroupSelectorTerms

Define quais Security Groups serão anexados aos nós.

```yaml
securityGroupSelectorTerms:
  # Seleção por tag
  - tags:
      karpenter.sh/discovery: my-cluster
      type: node

  # Seleção por ID direto
  - id: sg-0abcd1234

  # Múltiplos termos (OR)
  - tags:
      Name: eks-cluster-sg
  - tags:
      Name: eks-node-sg
```

#### blockDeviceMappings

Configura os discos EBS anexados aos nós.

```yaml
blockDeviceMappings:
  - deviceName: /dev/xvda
    ebs:
      volumeSize: 100Gi
      volumeType: gp3
      iops: 3000
      throughput: 125
      encrypted: true
      kmsKeyID: arn:aws:kms:us-east-1:123456789012:key/abc-def
      deleteOnTermination: true
```

**volumeType:**

- `gp3`: SSD de uso geral (recomendado)
- `gp2`: SSD de uso geral (legado)
- `io1`/`io2`: SSD de alta performance
- `st1`: HDD otimizado para throughput

#### userData

Script bash executado durante inicialização da instância.

```yaml
userData: |
  #!/bin/bash
  set -euo pipefail

  # Instalar pacotes adicionais
  yum install -y amazon-cloudwatch-agent

  # Configurar CloudWatch
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c ssm:AmazonCloudWatch-linux \
    -s

  # Configurações customizadas do kubelet
  echo 'KUBELET_EXTRA_ARGS="--max-pods=110"' >> /etc/sysconfig/kubelet
```

**Importante:** O Karpenter injeta automaticamente o script de bootstrap do EKS. Seu user data é executado **antes** do bootstrap.

## Requisitos AWS

### IAM Roles

#### 1. Karpenter Controller Role

Permite o controller gerenciar recursos AWS.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateFleet",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeSubnets",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "iam:PassRole",
        "iam:CreateServiceLinkedRole",
        "pricing:GetProducts",
        "ssm:GetParameter"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 2. Karpenter Node Role

Permite nós EC2 funcionarem no cluster EKS.

**Políticas gerenciadas AWS necessárias:**

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- `AmazonSSMManagedInstanceCore` (opcional, para Session Manager)

### Tagging de Recursos

#### Subnets

```bash
aws ec2 create-tags \
  --resources subnet-0abcd1234 \
  --tags Key=karpenter.sh/discovery,Value=my-cluster \
         Key=tier,Value=private
```

#### Security Groups

```bash
aws ec2 create-tags \
  --resources sg-0abcd1234 \
  --tags Key=karpenter.sh/discovery,Value=my-cluster \
         Key=type,Value=node
```

### Configuração do Cluster EKS

Adicionar o Node Role ao ConfigMap `aws-auth`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::123456789012:role/KarpenterNodeRole
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

## Exemplos Práticos

### Exemplo 1: NodePool para Workloads de Produção

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: production
spec:
  template:
    spec:
      nodeClassRef:
        name: production
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["m5.large", "m5.xlarge", "m5.2xlarge"]
      labels:
        environment: production
        tier: application
      taints:
        - key: production
          value: "true"
          effect: NoSchedule
  limits:
    cpu: "500"
    memory: 500Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 5m
    expireAfter: 720h
    budgets:
      - nodes: 5%
```

### Exemplo 2: NodePool para Spot Instances (Dev/Staging)

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot
spec:
  template:
    spec:
      nodeClassRef:
        name: spot
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ["t3", "t3a", "t4g"]
      labels:
        environment: staging
        capacity-type: spot
  limits:
    cpu: "200"
    memory: 200Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
    expireAfter: 168h # 7 dias
```

### Exemplo 3: EC2NodeClass com Bottlerocket

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: bottlerocket
spec:
  amiFamily: Bottlerocket
  role: KarpenterNodeRole
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
        tier: private
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: my-cluster
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 20Gi
        volumeType: gp3
        encrypted: true
    - deviceName: /dev/xvdb
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        encrypted: true
  tags:
    OS: bottlerocket
    Security: hardened
```

## Melhores Práticas

### 1. Separar NodePools por Workload

Crie NodePools distintos para diferentes tipos de aplicações:

- **production:** On-demand, instâncias maiores, alta disponibilidade
- **staging:** Mix de on-demand e spot
- **batch:** Spot instances, tolerante a interrupções
- **ml:** Instâncias com GPU

### 2. Usar Taints e Tolerations

Isole workloads críticos com taints:

```yaml
# NodePool
taints:
  - key: workload-type
    value: database
    effect: NoSchedule

# Pod
tolerations:
  - key: workload-type
    value: database
    effect: NoSchedule
```

### 3. Configurar Disruption Budgets

Limite interrupções simultâneas:

```yaml
disruption:
  budgets:
    - nodes: 10%
      schedule: "0 9 * * MON-FRI"  # Apenas em horário comercial
      reasons: ["Underutilized"]
    - nodes: 1
      reasons: ["Drifted", "Empty"]
```

### 4. Monitorar Custos

Use tags para rastreamento de custos:

```yaml
# EC2NodeClass
tags:
  CostCenter: engineering
  Project: api-platform
  Environment: production
  ManagedBy: karpenter
```

### 5. Testar com Spot Instances

Economize custos usando spot em ambientes não críticos:

```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot", "on-demand"]  # Fallback para on-demand
```

### 6. Limitar Tipos de Instância

Evite instâncias muito grandes ou muito pequenas:

```yaml
requirements:
  - key: karpenter.k8s.aws/instance-size
    operator: NotIn
    values: ["nano", "micro", "small"]  # Muito pequenas
  - key: karpenter.k8s.aws/instance-size
    operator: NotIn
    values: ["24xlarge", "32xlarge"]  # Muito grandes
```

### 7. Usar Subnets Privadas

Nunca use subnets públicas para nós:

```yaml
subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: my-cluster
      tier: private  # Apenas subnets privadas
```

## Próximos Passos

Agora que você compreende NodePool e NodeClass:

1. Leia [03-conceitos-k8s-local.md](./03-conceitos-k8s-local.md) para implementação local
2. Explore os exemplos completos em `manifests/aws-reference/`
3. Pratique configurando diferentes cenários
4. Estude os scripts de teste em `scripts/`

## Referências

- [NodePool API Reference](https://karpenter.sh/docs/concepts/nodepools/)
- [EC2NodeClass API Reference](https://karpenter.sh/docs/concepts/nodeclasses/)
- [AWS IAM Roles Guide](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/)
