# Guia Prático Nível 3 - Versão Custo ZERO

## Sumário Executivo

Este documento apresenta uma estratégia completa para aprender e praticar os conceitos do Nível 3 (Auto Escala de Nós e Karpenter) **sem custos com infraestrutura cloud**. Embora os conceitos originais sejam específicos de AWS EKS, é possível simular e compreender os fundamentos usando ferramentas locais gratuitas.

## Limitações e Realismo

### O que NÃO é possível simular localmente

1. **Cluster Autoscaler Real**: Requer integração com Auto Scaling Groups da AWS
2. **Karpenter Real**: Projetado especificamente para AWS (EC2, IAM, VPC)
3. **Provisionamento Real de Nós**: Não há criação dinâmica de VMs/containers como nós
4. **Custos e Billing**: Não há economia de recursos reais

### O que É possível aprender localmente

1. **Conceitos de HPA**: Horizontal Pod Autoscaler funciona perfeitamente
2. **Métricas e Observabilidade**: Metrics Server, Prometheus, Grafana
3. **Pod Scheduling**: Node Affinity, Taints, Tolerations, Topology Spread
4. **Load Testing**: K6, Fortio funcionam normalmente
5. **Simulação de Cenários**: Adicionar/remover nós manualmente para entender o fluxo
6. **Manifestos YAML**: Todos os manifestos podem ser criados e testados

## Stack de Ferramentas Gratuitas

### Cluster Kubernetes Local

| Ferramenta | Vantagens | Desvantagens | Recomendação |
|------------|-----------|--------------|--------------|
| **Kind** | Multi-node, rápido, leve | Apenas containers Docker | **Recomendado** |
| **k3d** | Multi-node, k3s leve | Menos documentação | Alternativa |
| **Minikube** | Bem documentado, addons | Single-node por padrão | Para iniciantes |
| **Docker Desktop** | Simples, integrado | Single-node, pesado | Não recomendado |

**Escolha: Kind** - Melhor equilíbrio entre funcionalidades e recursos

### Ferramentas de Desenvolvimento

| Categoria | Ferramenta | Custo | Instalação |
|-----------|-----------|-------|------------|
| Container Runtime | Docker Desktop | Gratuito | Download oficial |
| Cluster Local | Kind | Gratuito | Binary/Go |
| CLI Kubernetes | kubectl | Gratuito | Incluído no Docker Desktop |
| Package Manager | Helm | Gratuito | Binary standalone |
| Load Testing | K6 | Gratuito | Binary standalone |
| Observability | Lens Desktop | Gratuito (Personal) | Download oficial |
| Terminal UI | k9s | Gratuito | Binary standalone |
| Metrics | Metrics Server | Gratuito | Helm/manifest |

## Estratégia de Aprendizado Adaptada

### Módulo 1 - Conceitos de Auto Escala (Adaptado)

#### Aula 1-2: HPA e Stress Testing

**Objetivo Original**: Configurar HPA e testar escalabilidade de pods

**Abordagem Custo ZERO**: Totalmente viável, sem adaptações

```bash
# Criar cluster multi-node com Kind
kind create cluster --name n3-demo --config kind-config.yaml

# Instalar Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch para funcionar com Kind (certificados self-signed)
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Deploy da demo-api com HPA
kubectl apply -f manifests/

# Executar K6 para stress testing
k6 run k6/stress-test.js
```

**Resultado Esperado**: HPA funcionará normalmente, escalando pods de 1 para 10+ réplicas

#### Aula 3-4: Node Groups e Cluster Autoscaler

**Objetivo Original**: Configurar Node Groups e Cluster Autoscaler na AWS

**Abordagem Custo ZERO**: Simulação manual + compreensão conceitual

##### Simulação de Cenário

```bash
# 1. Criar cluster com 2 workers
kind create cluster --name n3-ca --config kind-2-workers.yaml

# 2. Deploy de aplicação que demanda muitos recursos
kubectl apply -f manifests/resource-intensive-deployment.yaml

# 3. Observar pods em Pending (falta de recursos)
kubectl get pods -w

# 4. SIMULAR adição de nó (manualmente)
docker run -d --name n3-ca-worker3 \
  --privileged --network kind \
  kindest/node:v1.34.0

kind get nodes --name n3-ca  # Verificar novo nó

# 5. Observar pods sendo agendados no novo nó
kubectl get pods -o wide
```

**Diferença da AWS**: No EKS, o Cluster Autoscaler faria isso automaticamente

**Aprendizado**: Entender o ciclo de vida:
1. Pods ficam Pending por falta de recursos
2. Autoscaler detecta e provisiona novos nós
3. Scheduler aloca pods nos novos nós
4. Quando carga diminui, nós são removidos (drain + terminate)

##### Estudo de Caso Teórico

**Criar documento de análise** com:

1. Fluxo do Cluster Autoscaler
2. Arquitetura de componentes
3. Integração com AWS Auto Scaling Groups
4. Políticas de scale-up e scale-down
5. Exemplos de configuração (sem aplicar)

#### Aula 5-7: IAM, Service Accounts, IRSA

**Objetivo Original**: Configurar permissões AWS para Cluster Autoscaler

**Abordagem Custo ZERO**: Estudo teórico + documentação

##### Exercício Prático Alternativo

1. Criar manifestos YAML completos (sem aplicar)
2. Documentar cada campo e sua função
3. Desenhar diagrama de arquitetura
4. Simular troubleshooting de erros comuns

```yaml
# Exemplo: service-account.yaml (para estudo)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    # No EKS, isso vincularia a uma IAM Role
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ClusterAutoscalerRole
---
# Manifesto do Cluster Autoscaler (para estudo)
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
        image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.28.0
        command:
          - ./cluster-autoscaler
          - --v=4
          - --stderrthreshold=info
          - --cloud-provider=aws  # Específico da AWS
          - --skip-nodes-with-local-storage=false
          - --expander=least-waste
          - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/n3-demo
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
```

**Exercício**: Ler a documentação oficial e criar um guia explicando:
- O que é IRSA (IAM Roles for Service Accounts)
- Como funciona a integração EKS + IAM
- Qual a vantagem sobre credenciais estáticas
- Quais permissões são necessárias

#### Aula 8-9: Scaling e Descaling

**Objetivo Original**: Observar Cluster Autoscaler em ação

**Abordagem Custo ZERO**: Simulação manual com documentação detalhada

##### Roteiro de Simulação

```bash
# Etapa 1: Estado Inicial
# Cluster: 1 control-plane + 2 workers
# Recursos totais: ~4 CPU, ~8GB RAM (exemplo)

# Etapa 2: Deploy de alta demanda
kubectl apply -f high-demand-deployment.yaml
# Solicita: 20 replicas x 500m CPU = 10 CPU total

# Etapa 3: Pods ficam Pending
kubectl get pods | grep Pending
# Saída esperada: 10-15 pods Pending

# Etapa 4: SIMULAÇÃO - Adicionar worker manualmente
# Documentar: "Aqui o Cluster Autoscaler adicionaria automaticamente um nó"
kind create cluster --name temp-worker
# OU
docker exec -it n3-ca-control-plane kubectl get nodes

# Etapa 5: Reduzir demanda
kubectl scale deployment high-demand --replicas=2

# Etapa 6: SIMULAÇÃO - Remover worker
# Documentar: "Aqui o Cluster Autoscaler removeria o nó após ~10min"
```

**Documentar cada etapa com**:
- Screenshots do `kubectl get nodes`
- Screenshots do `kubectl top nodes`
- Logs simulados do Cluster Autoscaler
- Explicação do que aconteceria no EKS

### Módulo 2 - Karpenter (Adaptado)

#### Aula 1-3: Introdução e IAM Setup

**Objetivo Original**: Instalar Karpenter e configurar IAM

**Abordagem Custo ZERO**: Estudo profundo + lab teórico

##### Exercício Comparativo

Criar tabela comparativa:

| Aspecto | Cluster Autoscaler | Karpenter |
|---------|-------------------|-----------|
| Provisionamento | Via Auto Scaling Groups | Direto via EC2 API |
| Velocidade | Minutos | Segundos |
| Flexibilidade | Node Groups predefinidos | Qualquer tipo de instância |
| Bin Packing | Básico | Avançado |
| Custo | Pode desperdiçar | Otimizado |

##### Manifesto de Estudo

```yaml
# NodePool - Recurso customizado do Karpenter
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  # Limites de recursos que o Karpenter pode provisionar
  limits:
    cpu: "100"
    memory: 200Gi

  # Template de nó
  template:
    metadata:
      labels:
        provisioner: karpenter
    spec:
      # Requerimentos de instância
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

      # NodeClass reference (AWS specific)
      nodeClassRef:
        name: default

---
# EC2NodeClass - Configurações específicas da AWS
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: KarpenterNodeRole
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: n3-demo
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: n3-demo
```

**Exercício**: Anotar cada campo explicando:
- O que ele faz
- Por que é necessário
- Qual o equivalente no Cluster Autoscaler
- Como debugar problemas

#### Aula 4-6: NodePools, Topology Spread, Affinity

**Objetivo Original**: Configurar NodePools e testar distribuição

**Abordagem Custo ZERO**: Totalmente viável com Kind

##### Simulação de Multi-AZ com Kind

```yaml
# kind-multi-zone.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1a
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1b
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1c
```

##### Deployment com Topology Spread

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api-ha
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
      # Distribuir pods uniformemente entre zonas
      topologySpreadConstraints:
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

**Teste Prático**:

```bash
# Criar cluster
kind create cluster --config kind-multi-zone.yaml

# Deploy
kubectl apply -f deployment-ha.yaml

# Verificar distribuição
kubectl get pods -o wide -l app=demo-api

# Resultado esperado: 2 pods em cada zona
# NAME              NODE                       ZONE
# demo-api-xxx      n3-demo-worker             us-east-1a
# demo-api-yyy      n3-demo-worker             us-east-1a
# demo-api-zzz      n3-demo-worker2            us-east-1b
# demo-api-aaa      n3-demo-worker2            us-east-1b
# demo-api-bbb      n3-demo-worker3            us-east-1c
# demo-api-ccc      n3-demo-worker3            us-east-1c
```

##### Pod Anti-Affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-api-anti-affinity
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
      # Evitar co-location de pods no mesmo nó
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - demo-api
            topologyKey: kubernetes.io/hostname
      containers:
      - name: demo-api
        image: demo-api:v1
```

**Teste**:

```bash
kubectl apply -f deployment-anti-affinity.yaml
kubectl get pods -o wide

# Cada pod estará em um nó diferente
# Se houver apenas 2 workers, o 3º pod ficará Pending
```

**Aprendizado**: Mesmo sem Karpenter, os conceitos de scheduling funcionam

## Estrutura de Projeto Custo ZERO

```plaintext
k8s/
├── apps/
│   └── demo-api/              # Aplicação existente
├── n3/
│   ├── local/                 # Versão local/gratuita
│   │   ├── docs/
│   │   │   ├── README.md
│   │   │   ├── conceitos-cluster-autoscaler.md
│   │   │   ├── conceitos-karpenter.md
│   │   │   ├── comparacao-ca-vs-karpenter.md
│   │   │   ├── simulacao-autoscaling.md
│   │   │   └── iam-irsa-explicacao.md
│   │   ├── kind/
│   │   │   ├── cluster-2-workers.yaml
│   │   │   ├── cluster-3-workers.yaml
│   │   │   ├── cluster-multi-zone.yaml
│   │   │   └── scripts/
│   │   │       ├── create-cluster.sh
│   │   │       ├── add-worker.sh
│   │   │       └── remove-worker.sh
│   │   ├── manifests/
│   │   │   ├── m1-hpa/
│   │   │   │   ├── 01-namespace.yaml
│   │   │   │   ├── 02-deployment.yaml
│   │   │   │   ├── 03-service.yaml
│   │   │   │   ├── 04-hpa.yaml
│   │   │   │   └── 05-resource-intensive.yaml
│   │   │   ├── m1-ca-study/
│   │   │   │   ├── cluster-autoscaler.yaml  # Para estudo
│   │   │   │   ├── service-account.yaml
│   │   │   │   └── rbac.yaml
│   │   │   └── m2-karpenter-study/
│   │   │       ├── nodepool.yaml
│   │   │       ├── ec2nodeclass.yaml
│   │   │       └── deployment-affinity.yaml
│   │   ├── k6/
│   │   │   ├── stress-cpu.js
│   │   │   ├── stress-memory.js
│   │   │   ├── spike-test.js
│   │   │   ├── soak-test.js
│   │   │   └── ramp-up-down.js
│   │   ├── observability/
│   │   │   ├── metrics-server.yaml
│   │   │   ├── prometheus-values.yaml  # Helm
│   │   │   └── grafana-dashboards/
│   │   │       └── hpa-dashboard.json
│   │   └── labs/
│   │       ├── lab-01-hpa.md
│   │       ├── lab-02-simulacao-ca.md
│   │       ├── lab-03-topology-spread.md
│   │       ├── lab-04-affinity.md
│   │       └── lab-05-anti-affinity.md
│   └── aws/                   # Versão AWS (para referência futura)
│       └── ...
└── .github/
    └── docs/
        └── content/
            └── guides/
                ├── analise-n3-projeto-demo-api.md
                └── n3-guia-custo-zero.md  # Este documento
```

## Roteiro de Estudos Completo

### Semana 1: HPA e Métricas

**Dia 1-2: Setup do Ambiente**

```bash
# Instalar ferramentas
brew install kind kubectl helm k6 k9s  # macOS
# OU
choco install kind kubernetes-cli kubernetes-helm k6 k9s  # Windows
# OU
# Downloads manuais dos binários

# Criar cluster
kind create cluster --name n3-study --config kind/cluster-2-workers.yaml

# Verificar
kubectl cluster-info
kubectl get nodes
```

**Dia 3-4: HPA na Prática**

```bash
# Instalar Metrics Server
kubectl apply -f manifests/observability/metrics-server.yaml

# Deploy demo-api
kubectl apply -f manifests/m1-hpa/

# Verificar HPA
kubectl get hpa -w

# Executar K6
k6 run k6/stress-cpu.js

# Observar scaling
watch kubectl get pods
```

**Dia 5: Documentação e Análise**

- Ler documentação oficial do HPA
- Criar resumo dos conceitos
- Documentar testes realizados
- Tirar screenshots

### Semana 2: Simulação de Cluster Autoscaler

**Dia 1-2: Estudo Teórico**

- Ler documentação do Cluster Autoscaler
- Assistir vídeos explicativos
- Criar diagrama de arquitetura
- Documentar fluxo de scale-up/down

**Dia 3-4: Simulação Prática**

```bash
# Deploy de aplicação resource-intensive
kubectl apply -f manifests/m1-hpa/resource-intensive.yaml

# Observar pods Pending
kubectl get pods -w

# SIMULAR: Adicionar worker
# Documentar: "Cluster Autoscaler adicionaria nó aqui"

# Escalar down
kubectl scale deployment resource-intensive --replicas=1

# SIMULAR: Remover worker após 10min
# Documentar: "Cluster Autoscaler removeria nó aqui"
```

**Dia 5: IAM e IRSA (Teórico)**

- Estudar AWS IAM
- Entender IRSA (IAM Roles for Service Accounts)
- Criar documento explicando integração
- Analisar manifestos de exemplo

### Semana 3: Conceitos Karpenter

**Dia 1-2: Estudo Comparativo**

- Ler documentação do Karpenter
- Comparar com Cluster Autoscaler
- Criar tabela de diferenças
- Entender vantagens/desvantagens

**Dia 3-4: NodePools e NodeClass (Teórico)**

- Estudar arquitetura do Karpenter
- Analisar manifestos de exemplo
- Documentar cada configuração
- Entender bin packing

**Dia 5: Provisioning Strategy**

- Estudar diferentes estratégias
- On-Demand vs Spot
- Consolidation
- Drift (atualizações)

### Semana 4: Scheduling Avançado

**Dia 1-2: Topology Spread**

```bash
# Criar cluster multi-zona
kind create cluster --config kind/cluster-multi-zone.yaml

# Deploy com topology spread
kubectl apply -f manifests/m2-karpenter-study/deployment-topology.yaml

# Verificar distribuição
kubectl get pods -o wide -L topology.kubernetes.io/zone
```

**Dia 3: Node Affinity**

```bash
# Label nodes
kubectl label node n3-study-worker node-type=compute
kubectl label node n3-study-worker2 node-type=memory

# Deploy com node affinity
kubectl apply -f manifests/m2-karpenter-study/deployment-affinity.yaml

# Verificar agendamento
kubectl get pods -o wide
```

**Dia 4: Pod Anti-Affinity**

```bash
# Deploy com anti-affinity
kubectl apply -f manifests/m2-karpenter-study/deployment-anti-affinity.yaml

# Verificar que pods estão em nós diferentes
kubectl get pods -o wide
```

**Dia 5: Revisão e Labs**

- Completar todos os labs
- Revisar conceitos
- Criar resumo pessoal
- Preparar para prática com AWS (futuro)

## Scripts Auxiliares

### create-cluster.sh

```bash
#!/bin/bash
# Script para criar cluster Kind multi-zone

CLUSTER_NAME=${1:-n3-demo}

cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1a
    node-type: compute
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1b
    node-type: compute
- role: worker
  labels:
    topology.kubernetes.io/zone: us-east-1c
    node-type: memory
EOF

# Instalar Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch para Kind
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Cluster ${CLUSTER_NAME} criado com sucesso!"
echo "Nodes:"
kubectl get nodes -L topology.kubernetes.io/zone,node-type
```

### simulate-scale-up.sh

```bash
#!/bin/bash
# Simula comportamento de scale-up do Cluster Autoscaler

echo "=== SIMULAÇÃO DE SCALE-UP ==="
echo ""
echo "1. Deploy de aplicação com alta demanda de recursos"
kubectl apply -f manifests/m1-hpa/resource-intensive.yaml

echo ""
echo "2. Aguardando pods ficarem Pending..."
sleep 10

echo ""
echo "3. Status atual:"
kubectl get pods | grep -E "NAME|Pending"

echo ""
echo "4. SIMULAÇÃO: Cluster Autoscaler detectaria pods Pending"
echo "   e adicionaria automaticamente um novo nó"
echo ""
echo "   No EKS, isso aconteceria via Auto Scaling Group"
echo "   Tempo médio: 2-5 minutos"
echo ""
read -p "Pressione ENTER para simular adição de nó..."

# Aqui você poderia adicionar um nó real se quisesse
# kind get nodes --name n3-demo
# docker run -d --name extra-worker ...

echo ""
echo "5. Nó adicionado (simulado)"
echo "6. Pods seriam agendados no novo nó"
echo ""
kubectl get nodes
```

### k6/stress-cpu.js

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Ramp-up para 5 VUs
    { duration: '2m', target: 20 },   // Ramp-up para 20 VUs
    { duration: '3m', target: 50 },   // Pico de 50 VUs
    { duration: '2m', target: 20 },   // Reduzir para 20
    { duration: '1m', target: 0 },    // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% das requests < 2s
    http_req_failed: ['rate<0.1'],     // < 10% de falhas
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  // Stressar CPU por 2 segundos
  const res = http.get(`${BASE_URL}/stress/cpu?duration=2`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 3s': (r) => r.timings.duration < 3000,
  });

  sleep(1);
}
```

## Ferramentas de Observabilidade (Opcional)

### Instalar Prometheus + Grafana

```bash
# Adicionar repo Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar stack completo
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Acessar: http://localhost:3000
# User: admin
# Pass: prom-operator
```

### Dashboards Úteis

- **Kubernetes / Compute Resources / Cluster**: Visão geral do cluster
- **Kubernetes / Compute Resources / Namespace (Pods)**: Uso por namespace
- **HPA**: Criar custom dashboard para HPA metrics

## Checklist de Aprendizado

### Módulo 1 - Cluster Autoscaler

- [ ] Entender o que é HPA e como configurar
- [ ] Executar stress tests com K6
- [ ] Observar scaling de pods em tempo real
- [ ] Documentar conceitos de Cluster Autoscaler
- [ ] Criar diagrama de arquitetura CA
- [ ] Entender integração com Auto Scaling Groups
- [ ] Estudar IAM Roles e IRSA
- [ ] Simular cenários de scale-up/down
- [ ] Documentar troubleshooting comum
- [ ] Criar resumo pessoal do módulo

### Módulo 2 - Karpenter

- [ ] Entender diferenças entre CA e Karpenter
- [ ] Estudar arquitetura do Karpenter
- [ ] Analisar manifestos de NodePool
- [ ] Analisar manifestos de EC2NodeClass
- [ ] Entender bin packing
- [ ] Praticar Topology Spread Constraints
- [ ] Praticar Node Affinity
- [ ] Praticar Pod Anti-Affinity
- [ ] Simular distribuição multi-zona
- [ ] Estudar estratégias de consolidation
- [ ] Entender On-Demand vs Spot
- [ ] Criar resumo pessoal do módulo

## Próximos Passos (Quando tiver orçamento)

### AWS Free Tier

A AWS oferece alguns recursos gratuitos:

- 750 horas/mês de t2.micro ou t3.micro (12 meses)
- EKS Control Plane: USD 0.10/hora (não incluso no free tier)

**Estratégia de Custo Mínimo**:

1. Criar conta AWS (free tier)
2. Usar eksctl para criar cluster pequeno
3. Testar rapidamente (2-4 horas)
4. Destruir recursos imediatamente
5. Custo total: ~USD 0.40 por sessão

### Alternativas Cloud Gratuitas

| Provider | Oferta | Limitações |
|----------|--------|------------|
| Google Cloud | USD 300 créditos (90 dias) | Requer cartão |
| Azure | USD 200 créditos (30 dias) | Requer cartão |
| Oracle Cloud | Always Free tier (VMs) | Recursos limitados |
| Civo | USD 250 créditos | Para Kubernetes |

## Recursos Adicionais

### Documentação Oficial

- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Autoscaler FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)
- [Karpenter Docs](https://karpenter.sh/)
- [Kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [K6 Documentation](https://k6.io/docs/)

### Vídeos Recomendados

- "Kubernetes Autoscaling Deep Dive" - KubeCon talks
- "Karpenter vs Cluster Autoscaler" - AWS re:Invent
- "HPA in Production" - CNCF webinars

### Livros

- "Kubernetes Patterns" - Bilgin Ibryam & Roland Huß
- "Kubernetes Best Practices" - Brendan Burns et al.
- "Production Kubernetes" - Josh Rosso et al.

### Comunidades

- Kubernetes Slack (#sig-autoscaling)
- Reddit r/kubernetes
- Stack Overflow [kubernetes] tag
- CNCF Slack

## Conclusão

Embora não seja possível executar Cluster Autoscaler e Karpenter localmente de forma funcional, é totalmente viável:

1. **Aprender 90% dos conceitos** usando Kind + HPA + scheduling
2. **Simular cenários** adicionando/removendo nós manualmente
3. **Estudar profundamente** a teoria e arquitetura
4. **Praticar manifestos** e configurações YAML
5. **Preparar-se** para aplicar em ambientes AWS reais no futuro

**Custo total**: ZERO

**Conhecimento adquirido**: 80-90% do necessário para trabalhar com autoscaling em produção

**Diferencial**: Quando tiver acesso à AWS, você já saberá exatamente o que fazer e como debugar problemas.
