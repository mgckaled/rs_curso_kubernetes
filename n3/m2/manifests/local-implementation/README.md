<!-- markdownlint-disable -->

# Implementação Local - Conceitos Kubernetes

## Visão Geral

Esta pasta contém manifests Kubernetes que demonstram conceitos de scheduling avançados, aplicáveis localmente no Kind. Estes são os mesmos conceitos que o Karpenter utiliza na AWS.

## Pré-requisitos

1. Cluster Kind criado com `00-cluster-kind.yaml`
2. kubectl configurado apontando para o cluster
3. Imagem demo-api disponível localmente ou em registry

## Arquivos

### 01-namespace.yaml

Cria namespace isolado para os recursos de demonstração.

```bash
kubectl apply -f 01-namespace.yaml
```

### 02-deployment-topology.yaml

Demonstra **Topology Spread Constraints** para distribuição uniforme entre zonas.

**Conceito:** Garante que pods sejam distribuídos uniformemente entre zonas simuladas (zone-a, zone-b, zone-c).

**Observar:**

```bash
kubectl get pods -n karpenter-demo -o wide
# Deve mostrar 2 pods por zona (6 réplicas / 3 zonas = 2 por zona)
```

### 03-deployment-affinity.yaml

Demonstra **Node Affinity** para preferir/exigir nós específicos.

**Conceito:** Pods são agendados preferencialmente em nós on-demand com disco SSD.

**Observar:**

```bash
kubectl describe pod -n karpenter-demo -l version=affinity | grep "Node:"
# Deve mostrar pods em workers com disk-type=ssd
```

### 04-deployment-anti-affinity.yaml

Demonstra **Pod Anti-Affinity** para evitar co-localização.

**Conceito:** Cada pod deve rodar em nó diferente (alta disponibilidade).

**Observar:**

```bash
kubectl get pods -n karpenter-demo -l version=anti-affinity -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
# Cada pod deve estar em nó diferente
```

### 05-priority-class.yaml

Define **Priority Classes** para priorização de workloads.

**Conceito:** Pods críticos têm prioridade sobre pods não-críticos.

**Classes:**

- `high-priority`: Aplicações críticas de produção
- `medium-priority`: Aplicações padrão (default)
- `low-priority`: Jobs batch não-críticos

```bash
kubectl apply -f 05-priority-class.yaml
kubectl get priorityclasses
```

### 06-pdb.yaml

Define **PodDisruptionBudgets** para garantir disponibilidade.

**Conceito:** Mínimo de pods deve permanecer disponível durante manutenções.

**Observar:**

```bash
kubectl get pdb -n karpenter-demo
# Mostra quantos pods podem ser disruptados simultaneamente
```

### 07-service.yaml

Cria **Service ClusterIP** para expor pods internamente.

**Conceito:** Load balancer interno para distribuir tráfego entre pods.

```bash
kubectl get svc -n karpenter-demo
kubectl describe svc demo-api -n karpenter-demo
```

## Aplicação Completa

### Ordem de Aplicação

```bash
# 1. Namespace
kubectl apply -f 01-namespace.yaml

# 2. Priority Classes
kubectl apply -f 05-priority-class.yaml

# 3. Deployments (escolha um ou aplique todos)
kubectl apply -f 02-deployment-topology.yaml
kubectl apply -f 03-deployment-affinity.yaml
kubectl apply -f 04-deployment-anti-affinity.yaml

# 4. PodDisruptionBudget
kubectl apply -f 06-pdb.yaml

# 5. Service
kubectl apply -f 07-service.yaml
```

### Aplicar Tudo de Uma Vez

```bash
kubectl apply -f .
```

## Cenários de Teste

### Cenário 1: Topology Spread

Testar distribuição uniforme entre zonas.

```bash
# Aplicar deployment
kubectl apply -f 02-deployment-topology.yaml

# Observar distribuição
kubectl get pods -n karpenter-demo -o wide

# Contar pods por zona
kubectl get pods -n karpenter-demo -o json | \
  jq -r '.items[] | .spec.nodeName' | \
  xargs -I {} kubectl get node {} -o json | \
  jq -r '.metadata.labels["topology.kubernetes.io/zone"]' | \
  sort | uniq -c
```

**Resultado esperado:** 2 pods em cada zona (6 réplicas / 3 zonas)

### Cenário 2: Node Affinity

Testar preferências de nós.

```bash
# Aplicar deployment
kubectl apply -f 03-deployment-affinity.yaml

# Ver em quais nós foram agendados
kubectl get pods -n karpenter-demo -l version=affinity -o wide

# Verificar labels dos nós
kubectl get nodes -L disk-type,karpenter.sh/capacity-type
```

**Resultado esperado:** Pods preferencialmente em nós com disk-type=ssd e capacity-type=on-demand

### Cenário 3: Pod Anti-Affinity

Testar isolamento de pods.

```bash
# Aplicar deployment
kubectl apply -f 04-deployment-anti-affinity.yaml

# Ver distribuição por nó
kubectl get pods -n karpenter-demo -l version=anti-affinity \
  -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
```

**Resultado esperado:** Cada pod em nó diferente (máximo 3 pods para 3 workers)

### Cenário 4: Priority e Preempção

Testar prioridade de pods.

```bash
# Aplicar priority classes
kubectl apply -f 05-priority-class.yaml

# Criar pod de baixa prioridade
kubectl run low-priority-pod \
  --image=nginx \
  --overrides='{"spec":{"priorityClassName":"low-priority"}}' \
  -n karpenter-demo

# Criar pod de alta prioridade (pode preemptar o anterior se recursos escassos)
kubectl run high-priority-pod \
  --image=nginx \
  --overrides='{"spec":{"priorityClassName":"high-priority"}}' \
  -n karpenter-demo

# Observar eventos
kubectl get events -n karpenter-demo --sort-by='.lastTimestamp'
```

### Cenário 5: PodDisruptionBudget

Testar proteção durante drain.

```bash
# Aplicar PDB
kubectl apply -f 06-pdb.yaml

# Ver status do PDB
kubectl get pdb -n karpenter-demo

# Tentar drenar um nó (respeitará o PDB)
kubectl drain karpenter-demo-worker --ignore-daemonsets --delete-emptydir-data

# Observar que dreno respeita minAvailable
kubectl get events -n karpenter-demo --sort-by='.lastTimestamp' | grep -i disrupt
```

## Observabilidade

### Ver Distribuição de Pods

```bash
# Por nó
kubectl get pods -n karpenter-demo -o wide

# Por zona
for zone in zone-a zone-b zone-c; do
  echo "=== $zone ==="
  kubectl get pods -n karpenter-demo -o json | \
    jq -r ".items[] | select(.spec.nodeName != null) | .spec.nodeName" | \
    xargs -I {} kubectl get node {} -o json | \
    jq -r "select(.metadata.labels[\"topology.kubernetes.io/zone\"] == \"$zone\") | .metadata.name" | \
    wc -l
done
```

### Ver Eventos de Scheduling

```bash
# Eventos recentes
kubectl get events -n karpenter-demo --sort-by='.lastTimestamp'

# Filtrar apenas scheduling
kubectl get events -n karpenter-demo \
  --field-selector reason=Scheduled,reason=FailedScheduling \
  --sort-by='.lastTimestamp'
```

### Ver Motivos de Pending

```bash
# Pods pendentes
kubectl get pods -n karpenter-demo --field-selector status.phase=Pending

# Descrever para ver motivo
kubectl describe pod <pod-name> -n karpenter-demo | grep -A 10 "Events:"
```

### Ver Resource Utilization

```bash
# Top nodes
kubectl top nodes

# Top pods
kubectl top pods -n karpenter-demo
```

## Debugging

### Pod não agenda (Pending)

```bash
# Ver eventos
kubectl describe pod <pod-name> -n karpenter-demo

# Verificar se há recursos disponíveis
kubectl describe nodes | grep -A 5 "Allocated resources"

# Verificar se constraints podem ser satisfeitas
kubectl get nodes --show-labels
```

### Distribuição desigual

```bash
# Ver topology spread constraints
kubectl get pod <pod-name> -n karpenter-demo -o yaml | grep -A 10 "topologySpreadConstraints"

# Ver labels dos nós
kubectl get nodes -L topology.kubernetes.io/zone

# Ver eventos de scheduling
kubectl get events -n karpenter-demo | grep -i spread
```

### PDB bloqueando drain

```bash
# Ver status do PDB
kubectl get pdb -n karpenter-demo -o yaml

# Ver allowed disruptions
kubectl get pdb -n karpenter-demo
```

## Limpeza

### Deletar recursos específicos

```bash
# Deletar deployments
kubectl delete deployment --all -n karpenter-demo

# Deletar PDBs
kubectl delete pdb --all -n karpenter-demo

# Deletar service
kubectl delete svc --all -n karpenter-demo
```

### Deletar tudo

```bash
# Deletar namespace (remove todos recursos)
kubectl delete namespace karpenter-demo

# Recriar namespace limpo
kubectl apply -f 01-namespace.yaml
```

## Próximos Passos

1. Execute os scripts automatizados em `../../scripts/`
2. Experimente modificar parâmetros (maxSkew, weights, etc.)
3. Combine múltiplos conceitos em um único deployment
4. Teste cenários de falha (delete pods, nodes)

## Referências

- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
