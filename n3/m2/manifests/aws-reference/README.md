<!-- markdownlint-disable -->

# Manifests de Referência AWS - Karpenter

## Aviso Importante

Os manifests nesta pasta são **exemplos de referência** para uso futuro em ambiente AWS real (EKS). Eles **NÃO FUNCIONAM** no Kind local pois requerem:

- Cluster AWS EKS
- IAM Roles configuradas
- VPC, Subnets e Security Groups
- API EC2 disponível

## Propósito

Esta pasta contém exemplos completos e documentados de:

1. **Instalação do Karpenter via Helm**
2. **Configuração de NodePools**
3. **Configuração de EC2NodeClass**

Use estes manifests como referência para quando tiver acesso a um cluster EKS.

## Arquivos

### 1. karpenter-helm-values.yaml

Valores para instalação do Karpenter via Helm Chart.

**Como usar:**

```bash
# Adicionar repositório Helm
helm repo add karpenter https://charts.karpenter.sh
helm repo update

# Instalar Karpenter
helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --values karpenter-helm-values.yaml
```

### 2. karpenter-nodepool.yaml

Define diferentes NodePools para workloads diversos.

**Contém:**

- `production`: On-demand, alta prioridade
- `spot`: Instâncias Spot para economia
- `batch`: Jobs batch com auto-scaling agressivo

**Como aplicar:**

```bash
kubectl apply -f karpenter-nodepool.yaml
```

### 3. karpenter-nodeclass.yaml

Define EC2NodeClasses para diferentes configurações.

**Contém:**

- `default`: Amazon Linux 2023
- `bottlerocket`: Bottlerocket OS (segurança)
- `gpu`: Instâncias com GPU

**Como aplicar:**

```bash
kubectl apply -f karpenter-nodeclass.yaml
```

## Pré-requisitos AWS

### 1. IAM Roles

#### Karpenter Controller Role

```bash
# ARN: arn:aws:iam::123456789012:role/KarpenterControllerRole
# Trust Policy: Permite EKS OIDC provider
# Policies: Ver documentação completa
```

#### Karpenter Node Role

```bash
# ARN: arn:aws:iam::123456789012:role/KarpenterNodeRole
# Policies:
# - AmazonEKSWorkerNodePolicy
# - AmazonEKS_CNI_Policy
# - AmazonEC2ContainerRegistryReadOnly
```

### 2. Tagging de Recursos

#### Subnets (privadas apenas)

```bash
aws ec2 create-tags \
  --resources subnet-0abcd1234 subnet-0efgh5678 \
  --tags \
    Key=karpenter.sh/discovery,Value=my-cluster \
    Key=tier,Value=private
```

#### Security Groups

```bash
aws ec2 create-tags \
  --resources sg-0abcd1234 \
  --tags \
    Key=karpenter.sh/discovery,Value=my-cluster \
    Key=type,Value=node
```

### 3. ConfigMap aws-auth

Adicionar Node Role ao ConfigMap:

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

## Fluxo de Instalação Completo

### Passo 1: Criar IAM Roles

Use Terraform, CloudFormation ou console AWS para criar:

- KarpenterControllerRole (com IRSA)
- KarpenterNodeRole

### Passo 2: Configurar OIDC Provider

```bash
# Obter OIDC provider do cluster
aws eks describe-cluster --name my-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text

# Criar OIDC provider se não existir
eksctl utils associate-iam-oidc-provider \
  --cluster my-cluster \
  --approve
```

### Passo 3: Tag Recursos

Tag subnets e security groups conforme acima.

### Passo 4: Instalar Karpenter

```bash
helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --values karpenter-helm-values.yaml
```

### Passo 5: Aplicar NodePools e NodeClasses

```bash
kubectl apply -f karpenter-nodeclass.yaml
kubectl apply -f karpenter-nodepool.yaml
```

### Passo 6: Verificar Instalação

```bash
# Ver pods do Karpenter
kubectl get pods -n karpenter

# Ver NodePools
kubectl get nodepools

# Ver NodeClasses
kubectl get ec2nodeclasses
```

## Testando o Karpenter

### Teste 1: Escalar Deployment

```bash
# Criar deployment de teste
kubectl create deployment inflate --image=public.ecr.aws/eks-distro/kubernetes/pause:3.9
kubectl scale deployment inflate --replicas=10

# Observar provisionamento de nós
kubectl get nodes --watch
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f
```

### Teste 2: Consolidação

```bash
# Reduzir réplicas
kubectl scale deployment inflate --replicas=2

# Observar consolidação (após ~30s)
kubectl get nodes --watch
```

## Monitoramento

### Logs do Karpenter

```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f
```

### Métricas (Prometheus)

O Karpenter expõe métricas Prometheus em `:8000/metrics`:

```yaml
# ServiceMonitor para Prometheus Operator
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: karpenter
  namespace: karpenter
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: karpenter
  endpoints:
    - port: http-metrics
```

### Eventos

```bash
kubectl get events -n karpenter --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pods não são provisionados

```bash
# Verificar logs do controller
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Verificar NodePools
kubectl describe nodepool default

# Verificar permissões IAM
aws sts assume-role --role-arn arn:aws:iam::123456789012:role/KarpenterControllerRole
```

### Nós não se registram no cluster

```bash
# Verificar user data
kubectl describe ec2nodeclass default

# Verificar ConfigMap aws-auth
kubectl get configmap aws-auth -n kube-system -o yaml

# Ver logs EC2 (via Systems Manager)
aws ssm start-session --target i-0abcd1234
journalctl -u kubelet
```

### Consolidação não funciona

```bash
# Verificar disruption budget
kubectl describe nodepool default | grep -A 10 disruption

# Verificar PodDisruptionBudgets
kubectl get pdb --all-namespaces
```

## Custos

### Estimativa Mensal (us-east-1)

Assumindo 10 nós t3.medium rodando 24/7:

- **On-demand:** 10 × $0.0416/hora × 730h = ~$304/mês
- **Spot (média 70% desconto):** ~$91/mês

### Otimização de Custos

1. **Use Spot instances** para workloads tolerantes
2. **Configure consolidação** agressiva (consolidateAfter: 30s)
3. **Defina limites** nos NodePools
4. **Monitore métricas** de utilização
5. **Use expireAfter** para rotacionar nós regularmente

## Próximos Passos

1. Estude a documentação teórica em `../../docs/`
2. Pratique os conceitos localmente em `../local-implementation/`
3. Quando tiver acesso a EKS, volte a estes manifests
4. Adapte os valores conforme seu caso de uso

## Referências

- [Karpenter Getting Started](https://karpenter.sh/docs/getting-started/)
- [EKS Best Practices - Karpenter](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [Karpenter Helm Chart](https://github.com/aws/karpenter/tree/main/charts/karpenter)
