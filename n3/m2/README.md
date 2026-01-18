<!-- markdownlint-disable -->

# Nível 3 - Módulo 2: Karpenter e Conceitos Avançados de Scheduling

## Visão Geral

Este módulo explora o Karpenter, uma ferramenta avançada de auto-scaling de nós desenvolvida pela AWS, além de conceitos fundamentais de scheduling no Kubernetes que podem ser aplicados em qualquer ambiente.

## Estrutura do Módulo

### Abordagem Híbrida: Teoria + Prática

Este projeto adota uma abordagem educacional híbrida que combina:

1. **Documentação Teórica Completa do Karpenter**
   - Explicação detalhada de arquitetura e funcionamento
   - Exemplos de manifests prontos para AWS
   - Comparação com Cluster Autoscaler (CAS)
   - Preparação para uso futuro em ambientes cloud

2. **Implementação Prática Local**
   - Conceitos de scheduling aplicáveis no Kind
   - Cluster multi-node com simulação de zonas
   - Demonstração com demo-api
   - Custo zero e execução local

## Por que essa Abordagem?

O Karpenter é uma ferramenta específica para AWS que requer:

- AWS IAM Roles (IRSA)
- API EC2 para provisionar instâncias reais
- VPC, Security Groups, Subnets
- Infraestrutura cloud com custos associados

**Solução:** Documentamos o Karpenter completamente (teoria + exemplos prontos) e implementamos localmente os conceitos Kubernetes subjacentes que o Karpenter utiliza.

## Conceitos Abordados

### Conceitos do Karpenter (Documentação Teórica)

- NodePool: definição de pools de nós
- NodeClass: configuração de tipos de instâncias
- Bin Packing: otimização de alocação de recursos
- Consolidation: otimização de custos
- Disruption Budgets: controle de disrupções
- Spot Instances: economia com instâncias spot

### Conceitos Kubernetes (Implementação Prática)

- **Topology Spread Constraints:** distribuição uniforme de pods entre zonas
- **Node Affinity:** preferências e restrições de nós
- **Pod Anti-Affinity:** evitar co-localização de pods
- **Taints e Tolerations:** controle de agendamento
- **Resource Requests/Limits:** gerenciamento de recursos
- **Priority Classes:** priorização de workloads
- **PodDisruptionBudgets:** garantia de disponibilidade

## Estrutura de Arquivos

``` plaintext
n3/m2/
├── README.md                           # Este arquivo
├── docs/
│   ├── 01-karpenter-teoria.md         # Teoria completa do Karpenter
│   ├── 02-nodepool-nodeclass.md       # NodePool e NodeClass (AWS)
│   └── 03-conceitos-k8s-local.md      # Conceitos aplicáveis localmente
├── manifests/
│   ├── 00-cluster-kind.yaml           # Cluster Kind com 3 workers
│   ├── aws-reference/                 # Manifests Karpenter (AWS)
│   │   ├── README.md
│   │   ├── karpenter-helm-values.yaml
│   │   ├── karpenter-nodepool.yaml
│   │   └── karpenter-nodeclass.yaml
│   └── local-implementation/          # Implementação local (Kind)
│       ├── README.md
│       ├── 01-namespace.yaml
│       ├── 02-deployment-topology.yaml
│       ├── 03-deployment-affinity.yaml
│       ├── 04-deployment-anti-affinity.yaml
│       ├── 05-priority-class.yaml
│       ├── 06-pdb.yaml
│       └── 07-service.yaml
└── scripts/
    ├── 01-setup-cluster.sh            # Criar cluster + labels
    ├── 02-apply-manifests.sh          # Aplicar recursos
    ├── 03-test-topology.sh            # Testar distribuição
    └── 04-cleanup.sh                  # Limpar ambiente
```

## Requisitos

### Software

- Docker Desktop 4.52.0+
- Kind v0.30.0+
- kubectl v1.34.2+
- Helm v3.14.3+ (para referência AWS)

### Recursos

- Memória disponível: mínimo 2.5GB
- CPU: 4 cores recomendados
- Disco: 5GB livres

## Guia de Uso

### 1. Estudar a Documentação Teórica

Leia os documentos na pasta `docs/` na ordem:

```bash
# 1. Entenda o que é o Karpenter e como funciona
cat docs/01-karpenter-teoria.md

# 2. Aprenda sobre NodePool e NodeClass
cat docs/02-nodepool-nodeclass.md

# 3. Compreenda os conceitos K8s aplicáveis localmente
cat docs/03-conceitos-k8s-local.md
```

### 2. Criar o Cluster Kind

```bash
# Criar cluster com 1 control-plane + 3 workers
cd scripts
chmod +x *.sh
./01-setup-cluster.sh
```

### 3. Aplicar os Manifests

```bash
# Aplicar recursos Kubernetes
./02-apply-manifests.sh
```

### 4. Testar e Observar

```bash
# Testar distribuição de pods
./03-test-topology.sh

# Verificar distribuição de pods por nó
kubectl get pods -n karpenter-demo -o wide

# Verificar labels dos nós
kubectl get nodes --show-labels

# Verificar distribuição por zona
kubectl get pods -n karpenter-demo -o json | \
  jq -r '.items[] | "\(.metadata.name) -> \(.spec.nodeName)"'
```

### 5. Limpar o Ambiente

```bash
# Deletar cluster
./04-cleanup.sh
```

## Mapeamento: Conceitos do Curso vs Implementação

| Conceito do Curso (AWS) | Implementação Local (Kind) |
|-------------------------|----------------------------|
| Karpenter NodePool | Deployment com node selectors |
| Karpenter NodeClass | Node labels customizados |
| EC2 Auto Scaling | Simulação com múltiplos workers |
| Zonas de disponibilidade AWS | Labels `topology.kubernetes.io/zone` |
| Tipos de instância EC2 | Labels `node.kubernetes.io/instance-type` |
| Bin packing do Karpenter | Topology spread constraints |
| Spot instances | Priority classes (baixa prioridade) |
| Consolidation | PodDisruptionBudgets |

## Cenários de Teste

### Cenário 1: Distribuição Uniforme (Topology Spread)

Demonstra como distribuir pods uniformemente entre zonas simuladas.

```bash
kubectl apply -f manifests/local-implementation/02-deployment-topology.yaml
kubectl get pods -n karpenter-demo -o wide
```

### Cenário 2: Afinidade de Nós (Node Affinity)

Demonstra como preferir ou exigir nós específicos.

```bash
kubectl apply -f manifests/local-implementation/03-deployment-affinity.yaml
kubectl describe pod -n karpenter-demo | grep "Node-Selectors\|Tolerations"
```

### Cenário 3: Anti-Afinidade de Pods

Demonstra como evitar co-localização de pods.

```bash
kubectl apply -f manifests/local-implementation/04-deployment-anti-affinity.yaml
kubectl get pods -n karpenter-demo -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
```

## Observabilidade

### Verificar Eventos de Scheduling

```bash
kubectl get events -n karpenter-demo --sort-by='.lastTimestamp'
```

### Analisar Decisões do Scheduler

```bash
kubectl describe pod <pod-name> -n karpenter-demo | grep -A 10 "Events:"
```

### Verificar Resource Utilization

```bash
kubectl top nodes
kubectl top pods -n karpenter-demo
```

## Correlação com Resumos das Aulas

### Bloco A - Explorando o Karpenter e definindo Roles

- **Aula 1:** Documentado em `docs/01-karpenter-teoria.md`
- **Aula 2:** Exemplos em `manifests/aws-reference/`
- **Aula 3:** Conceitos de VPC/SG aplicados aos node selectors

### Bloco B - Instalação do Karpenter e prática

- **Aula 1:** Helm values em `manifests/aws-reference/karpenter-helm-values.yaml`
- **Aula 2:** NodeClass em `manifests/aws-reference/karpenter-nodeclass.yaml`
- **Aula 3:** NodePool em `manifests/aws-reference/karpenter-nodepool.yaml`
- **Aula 4:** Topology spread em `manifests/local-implementation/02-deployment-topology.yaml`
- **Aula 5:** Pod anti-affinity em `manifests/local-implementation/04-deployment-anti-affinity.yaml`
- **Aula 6:** Priority classes e PDB nos manifests locais

## Próximos Passos

### Para Uso Futuro em AWS

Quando tiver acesso a um cluster EKS:

1. Consulte os manifests em `manifests/aws-reference/`
2. Configure IAM Roles conforme `docs/02-nodepool-nodeclass.md`
3. Instale o Karpenter via Helm
4. Aplique os NodePools e NodeClasses
5. Teste com workloads reais

### Aprofundamento

- Experimente combinar múltiplos conceitos (topology + affinity)
- Teste cenários de falha (delete nodes, pods)
- Implemente PodDisruptionBudgets mais complexos
- Explore diferentes priority classes

## Recursos Adicionais

- [Documentação Oficial Karpenter](https://karpenter.sh/)
- [Kubernetes Scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

## Estimativa de Recursos

### Cluster Kind (1 CP + 3 Workers)

- Control Plane: 500-700MB
- Worker 1: 400-500MB
- Worker 2: 400-500MB
- Worker 3: 400-500MB
- **Total estimado:** 1.7-2.2GB

### Demo API Pods (6 réplicas)

- Cada pod: ~50MB
- **Total estimado:** 300MB

### Total Geral

- **Consumo estimado:** 2.0-2.5GB (dentro do limite de 2.5GB disponível)

## Troubleshooting

### Pods em estado Pending

```bash
# Verificar eventos
kubectl describe pod <pod-name> -n karpenter-demo

# Verificar recursos disponíveis
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Distribuição desigual

```bash
# Verificar topology spread constraints
kubectl get pod <pod-name> -n karpenter-demo -o yaml | grep -A 10 "topologySpreadConstraints"

# Verificar labels dos nós
kubectl get nodes --show-labels | grep topology
```

### Cluster Kind não inicia

```bash
# Verificar logs do Docker
docker ps -a

# Deletar e recriar
kind delete cluster --name karpenter-demo
./scripts/01-setup-cluster.sh
```

## Contribuindo

Este é um projeto educacional. Sinta-se livre para:

- Adicionar novos cenários de teste
- Melhorar a documentação
- Reportar issues ou sugestões

## Licença

MIT - Projeto educacional para fins de aprendizado.
