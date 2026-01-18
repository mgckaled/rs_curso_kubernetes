<!-- markdownlint-disable -->

# Nivel 3 - Modulo 1: Explorando a Auto Escala dos Nos

Projeto didatico para demonstrar conceitos de auto scaling no Kubernetes, incluindo HPA (Horizontal Pod Autoscaler) e Cluster Autoscaler.

## Objetivos de Aprendizado

Apos completar este projeto, voce sera capaz de:

- Configurar e usar HPA (Horizontal Pod Autoscaler)
- Entender resource requests e limits
- Implementar PodDisruptionBudgets para alta disponibilidade
- Gerenciar nodes com taints, tolerations e affinity
- Compreender como Cluster Autoscaler funciona (teoria)
- Simular comportamentos de auto scaling localmente

## Arquitetura do Projeto

```plaintext
┌─────────────────────────────────────────────────────────────────┐
│                     Kind Cluster (Local)                        │
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  Control Plane   │         │  Worker Node 1   │              │
│  │                  │         │  (zone-a)        │              │
│  │  - API Server    │         │                  │              │
│  │  - Scheduler     │         │  - Demo API pods │              │
│  │  - Controller    │         │  - Metrics       │              │
│  └──────────────────┘         └──────────────────┘              │
│                                                                 │
│                               ┌──────────────────┐              │
│                               │  Worker Node 2   │              │
│                               │  (zone-b)        │              │
│                               │                  │              │
│                               │  - Demo API pods │              │
│                               │  - Metrics       │              │
│                               └──────────────────┘              │
│                                                                 │     
│  ┌──────────────────────────────────────────────┐               │
│  │            Metrics Server (kube-system)      │               │
│  │  - Coleta metricas de CPU/memoria            │               │
│  └──────────────────────────────────────────────┘               │
│                                                                 │
│  ┌──────────────────────────────────────────────┐               │
│  │                    HPA                       │               │
│  │  - Escala pods baseado em metricas           │               │
│  │  - Min: 2, Max: 10                           │               │
│  │  - Target: CPU 50%, Memory 100Mi             │               │
│  └──────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

## Recursos Implementados

| Recurso | Status | Descricao |
|---------|--------|-----------|
| HPA | 100% funcional | Escala pods automaticamente |
| Metrics Server | 100% funcional | Prove metricas para HPA |
| Resource Requests/Limits | 100% funcional | Gerenciamento de recursos |
| PodDisruptionBudget | 100% funcional | Protege disponibilidade |
| Topology Spread | Simulado | Distribui pods entre zonas |
| Node Affinity | 100% funcional | Controla agendamento |
| Taints/Tolerations | 100% funcional | Controla onde pods rodam |
| Cluster Autoscaler | Conceitual | Documentacao + simulacao |

## Requisitos

### Software

- **Docker Desktop**: 4.0+ (Windows/Mac) ou Docker Engine 20+ (Linux)
- **Kind**: v0.20.0+
- **kubectl**: v1.28.0+
- **Bash**: Para executar scripts (Git Bash no Windows)

### Hardware

| Componente | Minimo | Recomendado |
|------------|---------|-------------|
| RAM | 4 GB | 8 GB |
| CPU | 2 cores | 4 cores |
| Disco | 10 GB | 20 GB |
| Memoria disponivel | 2.5 GB | 4 GB |

### Estimativa de Uso de Memoria

| Componente | Memoria |
|------------|---------|
| Kind control-plane | 500-700 MB |
| Kind worker-1 | 300-400 MB |
| Kind worker-2 | 300-400 MB |
| Metrics Server | 50-100 MB |
| Demo API (2-10 pods) | 256-1280 MB |
| **Total estimado** | **1.4-2.9 GB** |

## Estrutura do Projeto

```plaintext
n3/m1/b-auto-scale/
├── README.md                    # Este arquivo
├── manifests/                   # Manifests Kubernetes
│   ├── 00-kind-cluster.yaml         # Configuracao do cluster
│   ├── 01-metrics-server.yaml       # Metrics Server
│   ├── 02-namespace.yaml            # Namespace
│   ├── 03-configmap.yaml            # ConfigMap
│   ├── 04-secret.yaml               # Secret
│   ├── 05-deployment.yaml           # Deployment da demo-api
│   ├── 06-service.yaml              # Service
│   ├── 07-hpa.yaml                  # HorizontalPodAutoscaler
│   ├── 08-pdb.yaml                  # PodDisruptionBudget
│   └── 09-node-management-examples.yaml # Exemplos didaticos
├── scripts/                     # Scripts utilitarios
│   ├── stress-test.sh               # Stress test para HPA
│   ├── simulate-node-scale-down.sh  # Simula scale down
│   └── monitor-scaling.sh           # Monitor em tempo real
└── docs/                        # Documentacao
    ├── 01-cluster-autoscaler-theory.md # Teoria
    ├── 02-local-vs-cloud.md            # Comparacao
    └── 03-simulation-guide.md          # Guia de simulacao
```

## Guia Passo a Passo

### Passo 1: Preparar Ambiente

#### 1.1. Verificar instalacoes

```bash
# Verificar Docker
docker --version
# Docker version 24.0.0+

# Verificar Kind
kind --version
# kind v0.20.0+

# Verificar kubectl
kubectl version --client
# Client Version: v1.28.0+
```

#### 1.2. Buildar imagem da demo-api

```bash
# Navegar para o diretorio da demo-api
cd apps/demo-api

# Build da imagem
docker build -t demo-api:v1 .

# Verificar imagem
docker images | grep demo-api

# Voltar para diretorio do projeto
cd ../../n3/m1/b-auto-scale
```

### Passo 2: Criar Cluster Kind

```bash
# Criar cluster com configuracao customizada
kind create cluster --config manifests/00-kind-cluster.yaml

# Verificar nodes
kubectl get nodes

# Output esperado:
# NAME                          STATUS   ROLES           AGE   VERSION
# n3-m1-autoscale-control-plane Ready    control-plane   1m    v1.30.0
# n3-m1-autoscale-worker        Ready    <none>          1m    v1.30.0
# n3-m1-autoscale-worker2       Ready    <none>          1m    v1.30.0

# Verificar labels dos nodes
kubectl get nodes --show-labels | grep zone

# Output esperado:
# ...topology.kubernetes.io/zone=zone-a...
# ...topology.kubernetes.io/zone=zone-b...
```

### Passo 3: Carregar Imagem no Kind

```bash
# Carregar imagem da demo-api no Kind
kind load docker-image demo-api:v1 --name n3-m1-autoscale

# Verificar que imagem foi carregada
docker exec -it n3-m1-autoscale-worker crictl images | grep demo-api
```

### Passo 4: Instalar Metrics Server

```bash
# Aplicar manifest do Metrics Server
kubectl apply -f manifests/01-metrics-server.yaml

# Aguardar Metrics Server ficar pronto (pode levar 30-60 segundos)
kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system

# Verificar se esta funcionando
kubectl top nodes

# Output esperado:
# NAME                          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# n3-m1-autoscale-control-plane 100m         5%     500Mi           25%
# n3-m1-autoscale-worker        50m          2%     300Mi           15%
# n3-m1-autoscale-worker2       50m          2%     300Mi           15%
```

**Troubleshooting:** Se `kubectl top nodes` retornar erro, aguarde mais 30 segundos e tente novamente. Metrics Server precisa de tempo para coletar dados iniciais.

### Passo 5: Deploy da Aplicacao

```bash
# Aplicar todos manifests da aplicacao
kubectl apply -f manifests/02-namespace.yaml
kubectl apply -f manifests/03-configmap.yaml
kubectl apply -f manifests/04-secret.yaml
kubectl apply -f manifests/05-deployment.yaml
kubectl apply -f manifests/06-service.yaml
kubectl apply -f manifests/07-hpa.yaml
kubectl apply -f manifests/08-pdb.yaml

# Aguardar pods ficarem prontos
kubectl wait --for=condition=ready --timeout=120s pod -l app=demo-api -n n3-m1-autoscale

# Verificar deploy
kubectl get all -n n3-m1-autoscale

# Output esperado:
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/demo-api-xxxxx              1/1     Running   0          1m
# pod/demo-api-yyyyy              1/1     Running   0          1m
#
# NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# service/demo-api     ClusterIP   10.96.xxx.xxx   <none>        80/TCP    1m
#
# NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/demo-api   2/2     2            2           1m
```

### Passo 6: Verificar Distribuicao de Pods

```bash
# Ver pods com nodes e zonas
kubectl get pods -n n3-m1-autoscale -o wide

# Ver distribuicao por zona
kubectl get pods -n n3-m1-autoscale -o custom-columns=\
NAME:.metadata.name,\
NODE:.spec.nodeName,\
ZONE:.spec.nodeSelector

# Verificar HPA
kubectl get hpa -n n3-m1-autoscale

# Output esperado:
# NAME            REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# demo-api-hpa    Deployment/demo-api   0%/50%, 0Mi/100Mi   2         10        2          1m
```

### Passo 7: Testar HPA (Scale Up)

#### 7.1. Iniciar monitoramento

```bash
# Em uma janela separada, iniciar monitor
cd n3/m1/b-auto-scale
bash scripts/monitor-scaling.sh
```

#### 7.2. Gerar carga

```bash
# Em outra janela, iniciar stress test
cd n3/m1/b-auto-scale
bash scripts/stress-test.sh cpu 120
```

#### 7.3. Observar comportamento

No monitor, voce devera ver:

1. **0-15s:** CPU utilizacao aumenta (0% → 50% → 80%)
2. **15-30s:** HPA detecta alta utilizacao
3. **30-45s:** HPA aumenta replicas (2 → 4)
4. **45-60s:** Novos pods sao criados
5. **60-90s:** CPU normaliza (distribuido entre mais pods)
6. **90-120s:** HPA pode escalar mais se necessario

```bash
# Ver metricas em tempo real
kubectl top pods -n n3-m1-autoscale

# Ver eventos do HPA
kubectl describe hpa demo-api-hpa -n n3-m1-autoscale
```

### Passo 8: Observar Scale Down

#### 8.1. Parar stress test

```bash
# Parar stress test (Ctrl+C na janela do stress-test.sh)
```

#### 8.2. Aguardar stabilization window

HPA tem **stabilizationWindow de 300 segundos (5 minutos)** para scale down. Isso evita thrashing (escala rapida demais).

```bash
# Monitorar HPA
watch -n 10 'kubectl get hpa,pods -n n3-m1-autoscale'

# Apos 5 minutos, replicas comecam a diminuir: 8 → 6 → 4 → 2
```

**Por que 5 minutos?** Evitar scale down prematuro. Imagine um spike de trafego temporario: sem stabilization window, HPA escalaria up e down rapidamente (thrashing), desperdicando recursos.

### Passo 9: Testar PodDisruptionBudget

#### 9.1. Verificar PDB

```bash
# Ver status do PDB
kubectl get pdb -n n3-m1-autoscale
kubectl describe pdb demo-api-pdb -n n3-m1-autoscale

# Output:
# Min Available:     1
# Current:          2
# Desired:          2
# Allowed Disruptions:  1
```

#### 9.2. Drenar node respeitando PDB

```bash
# Identificar um node com pods
NODE_NAME=$(kubectl get pods -n n3-m1-autoscale -o wide | grep demo-api | head -n 1 | awk '{print $7}')

echo "Drenando node: $NODE_NAME"

# Drenar node
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data

# Observe que:
# 1. Pod do node e evicted
# 2. Novo pod e criado em outro node ANTES do anterior ser removido
# 3. PDB garante minAvailable=1 sempre
# 4. Sem downtime!

# Uncordon node apos teste
kubectl uncordon $NODE_NAME
```

### Passo 10: Simular Cluster Autoscaler Scale Down

```bash
# Usar script automatizado
bash scripts/simulate-node-scale-down.sh

# O script ira:
# 1. Listar nodes disponiveis
# 2. Permitir escolher qual node "remover"
# 3. Adicionar taint (simula CA marcando node)
# 4. Drenar node (evict pods)
# 5. Opcional: deletar node do cluster
# 6. Mostrar status final

# Siga as instrucoes interativas do script
```

### Passo 11: Testar Pods Pending (Falta de Recursos)

#### 11.1. Forcar scale up agressivo

```bash
# Aumentar maxReplicas temporariamente
kubectl patch hpa demo-api-hpa -n n3-m1-autoscale -p '{"spec":{"maxReplicas":20}}'

# Gerar carga intensa
bash scripts/stress-test.sh both 180
```

#### 11.2. Observar pods Pending

```bash
# Ver pods
kubectl get pods -n n3-m1-autoscale

# Alguns pods poderao ficar Pending:
# NAME                        READY   STATUS    RESTARTS   AGE
# demo-api-xxxxx              1/1     Running   0          2m
# demo-api-yyyyy              0/1     Pending   0          10s

# Descrever por que esta Pending
kubectl describe pod <pod-pending> -n n3-m1-autoscale | grep -A 10 Events

# Output:
# Events:
#   Type     Reason            Message
#   ----     ------            -------
#   Warning  FailedScheduling  0/2 nodes are available:
#                              2 Insufficient cpu.
```

#### 11.3. Entender o problema

```bash
# Ver capacidade dos nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Calcular necessidade:
# - Cada pod pede 100m CPU (request)
# - Cada node tem ~2 CPU (2000m)
# - Maximo ~20 pods por node (considerando outras cargas)
# - Com 2 workers, maximo ~40 pods
# - HPA maxReplicas=20 deve caber, mas se requests forem altos...
```

**Nota:** Este e o ponto onde Cluster Autoscaler adicionaria nodes automaticamente no cloud. No Kind, precisamos resolver manualmente (diminuir requests ou maxReplicas).

#### 11.4. Resolver

```bash
# Voltar maxReplicas para valor original
kubectl patch hpa demo-api-hpa -n n3-m1-autoscale -p '{"spec":{"maxReplicas":10}}'

# Ou diminuir requests no deployment
# kubectl edit deployment demo-api -n n3-m1-autoscale
```

## Testes e Validacao

### Checklist de Validacao

- [ ] Cluster Kind criado com 1 control-plane + 2 workers
- [ ] Nodes tem labels de zona (zone-a, zone-b)
- [ ] Metrics Server funcionando (`kubectl top nodes`)
- [ ] Demo-api com 2 replicas rodando
- [ ] Pods distribuidos entre nodes
- [ ] HPA criado e monitorando metricas
- [ ] Stress test escala pods (2 → 4+)
- [ ] Scale down funciona apos 5 minutos
- [ ] PDB protege durante drain
- [ ] Pods Pending aparecem com recursos insuficientes

### Comandos de Troubleshooting

```bash
# Ver logs da demo-api
kubectl logs -n n3-m1-autoscale -l app=demo-api --tail=50

# Ver logs do Metrics Server
kubectl logs -n kube-system -l k8s-app=metrics-server --tail=50

# Ver eventos do cluster
kubectl get events -n n3-m1-autoscale --sort-by='.lastTimestamp'

# Ver eventos do HPA
kubectl describe hpa demo-api-hpa -n n3-m1-autoscale

# Verificar metricas do HPA
kubectl get hpa demo-api-hpa -n n3-m1-autoscale -o yaml

# Ver distribuicao de pods
kubectl get pods -n n3-m1-autoscale -o wide | awk '{print $7}' | sort | uniq -c
```

## Limpeza

```bash
# Deletar namespace (remove todos recursos)
kubectl delete namespace n3-m1-autoscale

# Deletar cluster Kind
kind delete cluster --name n3-m1-autoscale

# Verificar que cluster foi removido
kind get clusters
```

## Conceitos Aprendidos

### 1. HPA (Horizontal Pod Autoscaler)

- Escala pods automaticamente baseado em metricas
- Usa Metrics Server para coletar CPU/memoria
- Calculo: `desiredReplicas = ceil[currentReplicas * (currentMetric / targetMetric)]`
- Behavior policies controlam velocidade de escala

### 2. Resource Management

- **Requests:** Garantidos pelo scheduler (usado para placement)
- **Limits:** Maximo que pod pode usar (enforced pelo kernel)
- CPU throttled quando excede limit
- Memoria OOM kill quando excede limit

### 3. PodDisruptionBudget

- Protege contra interrupcoes voluntarias (drain, scale down)
- NAO protege contra interrupcoes involuntarias (crash)
- `minAvailable` ou `maxUnavailable`
- Cluster Autoscaler respeita PDB

### 4. Topology Spread

- Distribui pods entre zonas/nodes
- `maxSkew`: diferenca maxima permitida
- `whenUnsatisfiable`: DoNotSchedule (hard) ou ScheduleAnyway (soft)
- Importante para alta disponibilidade

### 5. Node Management

- **Taints:** Marcas que repelem pods
- **Tolerations:** Permissoes para tolerar taints
- **Affinity:** Atrai pods para nodes especificos
- **Cordon/Drain:** Gerenciamento manual de nodes

### 6. Cluster Autoscaler (Teoria)

- Automatiza adicao/remocao de nodes
- Requer cloud provider (AWS, GCP, Azure)
- Scale up: 2-5 minutos (boot VM)
- Scale down: 10-15 minutos (evitar thrashing)
- Complementa HPA (HPA escala pods, CA escala nodes)

## Documentacao Adicional

- [Teoria do Cluster Autoscaler](./docs/01-cluster-autoscaler-theory.md)
- [Comparacao Local vs Cloud](./docs/02-local-vs-cloud.md)
- [Guia de Simulacao](./docs/03-simulation-guide.md)

## Proximos Passos

1. **Modulo 2:** Karpenter (alternativa moderna ao Cluster Autoscaler)
2. **Modulo 3:** Spot Instances e otimizacao de custos
3. **Pratica em cloud:** Experimentar com Cluster Autoscaler real (AWS EKS)

## Referencias

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Autoscaler GitHub](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [PodDisruptionBudget Documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

## Licenca

Este projeto educacional e parte do Curso de Formacao em Kubernetes da Rocketseat.
