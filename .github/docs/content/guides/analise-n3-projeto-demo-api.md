# Análise de Suficiência do Projeto demo-api para o Nível 3

## Sumário Executivo

Este documento analisa se o projeto `demo-api` existente é suficiente para cobrir todos os conceitos práticos abordados no Nível 3 do curso de Kubernetes, que foca em **Auto Escala de Nós** (Cluster Autoscaler e Karpenter). A análise considera as ferramentas, infraestrutura e funcionalidades necessárias para implementar os cenários didáticos descritos nos resumos das aulas.

## Contexto do Nível 3

### Módulo 1 - Explorando a Auto Escala de Nós

Tópicos abordados:

- Configuração de HPA (Horizontal Pod Autoscaler)
- Métricas de CPU e memória
- Stress testing de aplicações
- EKS Node Groups (configuração via Terraform)
- Cluster Autoscaler (instalação, IAM, Service Account)
- Auto-discovery com tags AWS
- Scaling e descaling de nós

### Módulo 2 - Karpenter

Tópicos abordados:

- Transição de Cluster Autoscaler para Karpenter
- Configuração de IAM Roles (Node Role, Cluster Role)
- Identity Provider e Service Account
- VPCs, Subnets e Security Groups
- Instalação via Helm
- NodeClass e NodePool (configuração de recursos)
- Topology Spread Constraints
- Node Affinity e Pod Anti-Affinity
- Bottlerocket (imagem otimizada de segurança)
- Distribuição multi-zona (high availability)

## Análise do Projeto demo-api Atual

### Funcionalidades Existentes

O projeto `demo-api` (NestJS + Fastify) possui os seguintes recursos:

| Categoria | Endpoints | Status | Uso no N3 |
|-----------|-----------|--------|-----------|
| Health Checks | `/health`, `/ready`, `/health/unstable`, `/health/slow` | Implementado | Útil |
| Stress Testing | `/stress/cpu`, `/stress/memory`, `/stress/write` | Implementado | Essencial |
| Environment | `/env` | Implementado | Útil |
| File Operations | `/files/*` | Implementado | Não crítico |
| Crash Simulation | `POST /crash` | Implementado | Útil |

### Pontos Positivos

1. **Endpoints de Stress**: Permite simular carga de CPU e memória, essencial para acionar o HPA
2. **Health Probes**: Já possui endpoints configurados para Liveness e Readiness
3. **Dockerfile otimizado**: Multi-stage build com usuário não-root
4. **Configuração de recursos**: Já possui especificações de CPU/memory em manifestos do N1

### Limitações Identificadas

1. **Ausência de variação de carga realista**: Os endpoints de stress são síncronos e bloqueantes
2. **Métricas customizadas**: Não há exposição de métricas Prometheus (apenas métricas nativas do K8s)
3. **Falta de simulação de workloads específicos**: Não há endpoints que simulem padrões de uso do mundo real
4. **Ausência de endpoints que consomem recursos gradualmente**: Útil para demonstrar scaling progressivo

## Ferramentas e Infraestrutura Necessárias para o Nível 3

### 1. Infraestrutura AWS (Obrigatório)

| Componente | Status | Necessidade | Justificativa |
|------------|--------|-------------|---------------|
| AWS Account | Necessário | Obrigatória | Todo o N3 usa EKS |
| EKS Cluster | Não implementado | Obrigatória | Base para todo o N3 |
| Terraform | Não implementado | Obrigatória | Provisionamento de infra |
| IAM Roles/Policies | Não implementado | Obrigatória | Permissões para autoscaling |
| VPC/Subnets | Não implementado | Obrigatória | Configuração de rede |

#### Estrutura Terraform Recomendada

```plaintext
n3/
├── terraform/
│   ├── main.tf                    # Configuração principal
│   ├── variables.tf               # Variáveis do projeto
│   ├── outputs.tf                 # Outputs úteis
│   ├── versions.tf                # Versões de providers
│   ├── modules/
│   │   ├── vpc/                   # Módulo de VPC
│   │   ├── eks/                   # Módulo EKS
│   │   ├── iam/                   # Módulo IAM (roles, policies)
│   │   ├── node-groups/           # Módulo NodeGroups
│   │   └── karpenter/             # Módulo Karpenter
│   └── environments/
│       └── dev/
│           ├── terraform.tfvars   # Valores específicos do ambiente
│           └── backend.tf         # Configuração de state
```

### 2. Kubernetes Add-ons e Ferramentas

| Ferramenta | Status | Instalação | Finalidade |
|------------|--------|------------|------------|
| Metrics Server | Implementado (N1) | kubectl/manifest | Métricas de CPU/mem |
| Cluster Autoscaler | Não implementado | Helm/manifest | Autoscaling de nós (M1) |
| Karpenter | Não implementado | Helm | Autoscaling avançado (M2) |
| Helm | Requerido | CLI local | Gerenciamento de charts |
| kubectl | Implementado | CLI local | Interação com cluster |

#### Instalação via Helm

```bash
# Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=<CLUSTER_NAME>

# Karpenter
helm repo add karpenter https://charts.karpenter.sh
helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<ROLE_ARN>
```

### 3. Ferramentas de Load Testing

| Ferramenta | Status | Recomendação | Justificativa |
|------------|--------|--------------|---------------|
| K6 | Não implementado | Altamente recomendada | Ferramenta moderna, script em JS |
| Fortio | Usado no N1 | Opcional | Alternativa mais simples |
| Locust | Não implementado | Opcional | Python-based, flexível |
| Apache Bench (ab) | Não mencionado | Não recomendado | Muito básico |

#### Por que K6?

Conforme mencionado nos resumos das aulas (N3-M1, aula 8), o K6 é citado como ferramenta de teste de carga. Principais vantagens:

- **Scripts em JavaScript**: Mesma linguagem da demo-api (TypeScript/JavaScript)
- **Suporte a métricas customizadas**: Integração com Prometheus/Grafana
- **Scenarios avançados**: Ramping, soak tests, spike tests
- **Execução distribuída**: k6-operator no Kubernetes
- **Thresholds e checks**: Validação automática de SLOs

#### Exemplo de script K6

```javascript
// k6/stress-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp-up
    { duration: '5m', target: 50 },   // Sustained load
    { duration: '2m', target: 100 },  // Spike
    { duration: '3m', target: 0 },    // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% das requests < 500ms
  },
};

export default function () {
  const res = http.get('http://demo-api.demo.svc.cluster.local/stress/cpu?duration=2');
  check(res, { 'status was 200': (r) => r.status === 200 });
  sleep(1);
}
```

### 4. Ferramentas de Observabilidade (Opcional mas Recomendado)

| Ferramenta | Finalidade | Instalação |
|------------|------------|------------|
| Prometheus | Coleta de métricas | Helm (kube-prometheus-stack) |
| Grafana | Visualização | Incluído no stack acima |
| Lens Desktop | Interface gráfica K8s | Download local |
| k9s | TUI para Kubernetes | CLI local |

### 5. AWS CLI e Ferramentas Auxiliares

| CLI | Finalidade | Instalação |
|-----|------------|------------|
| aws-cli | Interação com AWS | Instalador oficial |
| eksctl | Simplificação de operações EKS | Binário standalone |
| terraform | IaC para AWS | Instalador oficial |
| kubectl | Controle do cluster | Incluído no Docker Desktop |

## Recursos Adicionais Necessários no demo-api

### 1. Endpoints de Stress Melhorados

#### Problema Atual

Os endpoints de stress atuais são síncronos e bloqueiam a thread principal do Node.js, o que pode não simular adequadamente cenários de carga distribuída.

#### Melhorias Sugeridas

```typescript
// Endpoint que mantém carga de CPU constante por período
GET /stress/sustained?cpu=50&duration=300
// Responde imediatamente, mas mantém CPU em 50% por 5 minutos

// Endpoint que aloca memória gradualmente
GET /stress/memory-leak?rate=10
// Aloca 10MB/s progressivamente
```

### 2. Endpoints de Métricas Customizadas

```typescript
// Expor métricas no formato Prometheus
GET /metrics
// Content-Type: text/plain
// Exemplo:
// http_requests_total{method="GET",status="200"} 42
// app_memory_usage_bytes 536870912
```

### 3. Simulação de Padrões de Tráfego

```typescript
// Endpoint que simula processamento de filas
POST /queue/process
// Simula workload realista com variação de latência

// Endpoint que simula cache miss
GET /cache/:key
// 20% cache hit, 80% miss (CPU intensivo)
```

## Estrutura de Diretórios Proposta para o Nível 3

```plaintext
k8s/
├── apps/
│   └── demo-api/              # Aplicação já existente (sem alterações)
├── n3/
│   ├── m1/                    # Módulo 1 - Cluster Autoscaler
│   │   ├── terraform/         # Infraestrutura AWS
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── eks.tf         # Configuração do EKS
│   │   │   ├── node-groups.tf # Auto Scaling Groups
│   │   │   ├── iam.tf         # Roles e Policies
│   │   │   └── outputs.tf
│   │   ├── manifests/
│   │   │   ├── 01-namespace.yaml
│   │   │   ├── 02-deployment.yaml
│   │   │   ├── 03-service.yaml
│   │   │   ├── 04-hpa.yaml
│   │   │   ├── 05-cluster-autoscaler.yaml
│   │   │   └── 06-service-account.yaml
│   │   ├── k6/
│   │   │   ├── stress-test.js
│   │   │   ├── spike-test.js
│   │   │   └── soak-test.js
│   │   └── docs/
│   │       ├── README.md
│   │       └── passo-a-passo.md
│   └── m2/                    # Módulo 2 - Karpenter
│       ├── terraform/         # Configurações adicionais
│       │   ├── karpenter.tf   # Recursos do Karpenter
│       │   └── iam-karpenter.tf
│       ├── manifests/
│       │   ├── 01-karpenter-namespace.yaml
│       │   ├── 02-node-class.yaml
│       │   ├── 03-node-pool.yaml
│       │   ├── 04-node-pool-bottlerocket.yaml
│       │   ├── 05-deployment-affinity.yaml
│       │   └── 06-deployment-anti-affinity.yaml
│       ├── helm/
│       │   └── karpenter-values.yaml
│       └── docs/
│           ├── README.md
│           └── passo-a-passo.md
└── .github/
    └── docs/
        └── content/
            ├── resumes/       # Resumos já existentes
            └── guides/
                └── analise-n3-projeto-demo-api.md  # Este documento
```

## Checklist de Ferramentas e Recursos

### Obrigatórios

- [ ] AWS Account ativa
- [ ] Terraform instalado (>= 1.5.0)
- [ ] kubectl instalado
- [ ] Helm instalado (>= 3.0)
- [ ] AWS CLI configurado
- [ ] Docker Desktop (com Kubernetes habilitado para testes locais)
- [ ] Manifests do Cluster Autoscaler
- [ ] Manifests do Karpenter
- [ ] Scripts Terraform para EKS + Node Groups
- [ ] Scripts Terraform para IAM (Cluster Autoscaler e Karpenter)

### Altamente Recomendados

- [ ] K6 instalado localmente
- [ ] K6 Operator no Kubernetes
- [ ] Scripts K6 para stress testing
- [ ] Lens Desktop para visualização
- [ ] eksctl para operações rápidas
- [ ] Prometheus + Grafana (observabilidade)

### Opcionais

- [ ] Chaos Mesh (testes de resiliência)
- [ ] ArgoCD (GitOps)
- [ ] Metrics Server dashboard
- [ ] Custom Grafana dashboards

## Conclusão e Recomendações

### O projeto demo-api é suficiente?

**Parcialmente**. O projeto possui:

- Endpoints de stress básicos que funcionam
- Health checks adequados
- Dockerfile otimizado

Porém, o Nível 3 **não trata apenas da aplicação**, mas principalmente de:

1. Infraestrutura AWS (EKS, Node Groups, IAM)
2. Ferramentas de autoscaling (Cluster Autoscaler, Karpenter)
3. Observabilidade e métricas
4. Load testing realista

### Ferramentas Mínimas para Implementação Completa

#### Essenciais

1. **Terraform**: Provisionar EKS, VPC, Node Groups, IAM
2. **Helm**: Instalar Cluster Autoscaler e Karpenter
3. **K6**: Load testing moderno e flexível
4. **kubectl**: Gerenciar recursos K8s
5. **AWS CLI**: Interagir com recursos AWS

#### Desejáveis

1. **Lens/k9s**: Visualização e debug
2. **Prometheus + Grafana**: Observabilidade
3. **eksctl**: Simplificar operações EKS

### Roadmap de Implementação

#### Fase 1: Infraestrutura Base

1. Criar módulo Terraform para VPC
2. Criar módulo Terraform para EKS
3. Configurar Node Groups iniciais
4. Configurar IAM Roles e Policies

#### Fase 2: Cluster Autoscaler (Módulo 1)

1. Instalar Metrics Server (se não estiver)
2. Configurar Service Account com IAM Role
3. Instalar Cluster Autoscaler via Helm
4. Criar manifestos com HPA configurado
5. Desenvolver scripts K6 para stress testing
6. Documentar passo a passo

#### Fase 3: Karpenter (Módulo 2)

1. Criar IAM Roles específicas para Karpenter
2. Configurar Identity Provider
3. Instalar Karpenter via Helm
4. Criar NodeClass e NodePool
5. Testar provisioning de nós
6. Configurar Topology Spread e Affinity
7. Documentar configurações avançadas

### Próximos Passos Recomendados

1. **Imediato**: Instalar Terraform e criar estrutura de diretórios
2. **Curto prazo**: Provisionar cluster EKS básico
3. **Médio prazo**: Implementar Cluster Autoscaler com K6
4. **Longo prazo**: Migrar para Karpenter e explorar recursos avançados

### Considerações de Custos

AWS cobra por:

- Horas de EC2 dos worker nodes
- EKS Control Plane (USD 0.10/hora)
- Transfer de dados
- Elastic Load Balancers

**Recomendação**: Usar clusters efêmeros (criar, testar, destruir) para minimizar custos.

#### Estimativa de Custos (região us-east-1)

| Recurso | Custo Estimado/hora | Custo Estimado/mês |
|---------|---------------------|-------------------|
| EKS Control Plane | USD 0.10 | USD 73 |
| 3x t3.medium nodes | USD 0.126 | USD 92 |
| Load Balancer | USD 0.025 | USD 18 |
| **Total** | **USD 0.251** | **USD 183** |

Uso didático (8h/dia, 20 dias/mês): **USD 40-50/mês**

## Referências

### Documentação Oficial

- [Kubernetes Cluster Autoscaling](https://kubernetes.io/docs/concepts/cluster-administration/cluster-autoscaling)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Karpenter Documentation](https://karpenter.sh/)
- [K6 Load Testing](https://k6.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Repositórios Relevantes

- [kubernetes/autoscaler](https://github.com/kubernetes/autoscaler)
- [aws/karpenter-provider-aws](https://github.com/aws/karpenter-provider-aws)
- [grafana/k6](https://github.com/grafana/k6)
- [terraform-aws-modules/terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks)

### Melhores Práticas

- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Production Best Practices](https://learnk8s.io/production-best-practices)

## Anexos

### Anexo A: Comandos Úteis

```bash
# Verificar versão de ferramentas
terraform version
kubectl version --client
helm version
k6 version

# Configurar AWS CLI
aws configure

# Listar clusters EKS
aws eks list-clusters --region us-east-1

# Obter kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-east-1

# Verificar nodes e capacidade
kubectl get nodes
kubectl top nodes

# Verificar HPA
kubectl get hpa -A

# Logs do Cluster Autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler

# Logs do Karpenter
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Executar K6 localmente
k6 run k6/stress-test.js

# Executar K6 no cluster
kubectl apply -f k6/test-run.yaml
```

### Anexo B: Variáveis de Ambiente Recomendadas

```bash
# AWS
export AWS_REGION=us-east-1
export AWS_PROFILE=default

# Terraform
export TF_VAR_cluster_name=demo-eks
export TF_VAR_region=us-east-1

# Kubernetes
export KUBECONFIG=~/.kube/config

# Demo API
export DEMO_API_NAMESPACE=demo
export DEMO_API_IMAGE=demo-api:latest
```

### Anexo C: Recursos Adicionais de Aprendizado

- [Full Cycle - Kubernetes](https://fullcycle.com.br/)
- [KodeKloud - Kubernetes for Beginners](https://kodekloud.com/)
- [A Cloud Guru - AWS Certified Solutions Architect](https://acloudguru.com/)
- [Pluralsight - Kubernetes Path](https://www.pluralsight.com/)
