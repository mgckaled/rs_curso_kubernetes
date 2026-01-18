<!-- markdownlint-disable -->

# Guia de Simulacao - Cluster Autoscaler Concepts

Este guia demonstra **como simular** o comportamento do Cluster Autoscaler usando Kind localmente. Embora o Cluster Autoscaler real nao funcione no Kind, podemos simular os conceitos manualmente para fins educacionais.

---

## Cenarios de Simulacao

### Cenario 1: Scale Up - Pods Pending

**Objetivo:** Demonstrar o que acontece quando nao ha recursos suficientes para agendar pods.

#### Passos:

1. **Deploy inicial com recursos limitados**

```bash
# Aplicar todos manifests
kubectl apply -f manifests/02-namespace.yaml
kubectl apply -f manifests/03-configmap.yaml
kubectl apply -f manifests/04-secret.yaml
kubectl apply -f manifests/05-deployment.yaml
kubectl apply -f manifests/06-service.yaml
kubectl apply -f manifests/07-hpa.yaml
kubectl apply -f manifests/08-pdb.yaml

# Verificar pods
kubectl get pods -n n3-m1-autoscale -o wide
```

2. **Aumentar requests para forcar Pending**

```bash
# Editar deployment aumentando requests
kubectl edit deployment demo-api -n n3-m1-autoscale

# Alterar:
resources:
  requests:
    cpu: 1000m      # De 100m para 1000m (1 core inteiro)
    memory: 1Gi     # De 128Mi para 1Gi
```

3. **Escalar manualmente para forcar Pending**

```bash
# Escalar para 10 replicas
kubectl scale deployment demo-api -n n3-m1-autoscale --replicas=10

# Verificar status dos pods
kubectl get pods -n n3-m1-autoscale

# Alguns pods estarao Pending:
# NAME                        READY   STATUS    RESTARTS   AGE
# demo-api-xxxxx              1/1     Running   0          2m
# demo-api-yyyyy              0/1     Pending   0          10s
```

4. **Analisar por que estao Pending**

```bash
# Descrever pod pending
kubectl describe pod <pod-pending> -n n3-m1-autoscale

# Output mostrara:
# Events:
#   Type     Reason            Message
#   ----     ------            -------
#   Warning  FailedScheduling  0/2 nodes are available:
#                              2 Insufficient cpu.
```

5. **Solucao no Cloud (Cluster Autoscaler)**

No cloud, Cluster Autoscaler automaticamente:
- Detectaria pods Pending
- Verificaria que novos nodes resolveriam o problema
- Adicionaria nodes ao cluster (2-5 minutos)
- Pods seriam agendados nos novos nodes

6. **Solucao no Kind (Manual)**

Como Kind nao pode adicionar nodes automaticamente, podemos:

**Opcao A:** Diminuir requests dos pods

```bash
kubectl edit deployment demo-api -n n3-m1-autoscale

# Voltar para valores originais
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

**Opcao B:** Adicionar node ao cluster (requer recriar)

```bash
# Parar cluster
kind delete cluster --name n3-m1-autoscale

# Editar manifests/00-kind-cluster.yaml
# Adicionar mais um worker node

# Recriar cluster
kind create cluster --config manifests/00-kind-cluster.yaml

# Reaplicar manifests
kubectl apply -f manifests/
```

---

### Cenario 2: Scale Down - Node Subutilizado

**Objetivo:** Demonstrar como Cluster Autoscaler remove nodes subutilizados.

#### Passos:

1. **Verificar estado inicial**

```bash
# Ver nodes e pods
kubectl get nodes
kubectl get pods -n n3-m1-autoscale -o wide

# Ver uso de recursos dos nodes
kubectl top nodes
```

2. **Diminuir carga (scale down de pods)**

```bash
# Reduzir replicas
kubectl scale deployment demo-api -n n3-m1-autoscale --replicas=1

# Verificar distribuicao
kubectl get pods -n n3-m1-autoscale -o wide

# Um node ficara sem pods (ou com poucos)
```

3. **Simular Cluster Autoscaler marcando node**

```bash
# Identificar node com menos pods
NODE_NAME=$(kubectl get pods -n n3-m1-autoscale -o wide | tail -n 1 | awk '{print $7}')

# Adicionar taint (simula CA marcando node para remocao)
kubectl taint nodes $NODE_NAME node.kubernetes.io/scale-down=scheduled:NoSchedule

# Verificar taint
kubectl describe node $NODE_NAME | grep -i taint
```

4. **Drenar node (remover pods)**

```bash
# Usar script automatizado
./scripts/simulate-node-scale-down.sh $NODE_NAME

# Ou manual:
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data --force
```

5. **Observar PDB em acao**

Durante drain, o PDB garante disponibilidade:

```bash
# Em outra janela, monitorar pods
watch -n 1 'kubectl get pods -n n3-m1-autoscale'

# PDB garante que minAvailable=1 sempre
# Se tentar remover o ultimo pod, drain aguardara
```

6. **Comportamento no Cloud**

No cloud, Cluster Autoscaler:
- Aguardaria 10 minutos com node subutilizado
- Verificaria se pods podem ser movidos
- Respeitaria PDB durante eviction
- Terminaria a VM apos drain bem-sucedido

---

### Cenario 3: HPA + Cluster Autoscaler (Simulado)

**Objetivo:** Demonstrar interacao entre HPA e Cluster Autoscaler.

#### Passos:

1. **Setup inicial**

```bash
# Garantir que HPA esta ativo
kubectl get hpa -n n3-m1-autoscale

# Verificar replicas atuais
kubectl get deployment demo-api -n n3-m1-autoscale
```

2. **Iniciar monitoramento**

```bash
# Em uma janela separada
./scripts/monitor-scaling.sh
```

3. **Gerar carga (HPA scale up)**

```bash
# Em outra janela
./scripts/stress-test.sh cpu 120
```

4. **Observar HPA escalando**

No monitor, voce vera:
- CPU utilizacao aumentando (50% → 80% → 100%)
- HPA aumentando replicas (2 → 4 → 6 → 8)
- Pods sendo criados

5. **Simular falta de recursos**

Se escalar muito, alguns pods ficarao Pending:

```bash
# Forcar scale up agressivo
kubectl patch hpa demo-api-hpa -n n3-m1-autoscale -p '{"spec":{"maxReplicas":20}}'

# Aguardar HPA escalar ate limite do cluster
```

6. **Ponto onde Cluster Autoscaler agiria**

```bash
# Ver pods pending
kubectl get pods -n n3-m1-autoscale | grep Pending

# No cloud, CA adicionaria nodes automaticamente
# No Kind, precisamos resolver manualmente (cenario 1)
```

7. **Scale down natural**

```bash
# Parar stress test (Ctrl+C)

# HPA escala down apos 5 minutos (stabilizationWindow)
# Monitorar:
watch -n 5 'kubectl get hpa,pods -n n3-m1-autoscale'

# Replicas diminuem: 8 → 6 → 4 → 2

# No cloud, CA removeria nodes subutilizados apos 10 minutos
```

---

### Cenario 4: PodDisruptionBudget Protegendo

**Objetivo:** Demonstrar como PDB impede downtime durante drain.

#### Passos:

1. **Setup: Deployment com 2 replicas e PDB minAvailable=1**

```bash
# Verificar deployment
kubectl get deployment demo-api -n n3-m1-autoscale

# Verificar PDB
kubectl get pdb -n n3-m1-autoscale
kubectl describe pdb demo-api-pdb -n n3-m1-autoscale
```

2. **Forcar pods em nodes diferentes**

```bash
# Deletar pods para serem recriados com distribuicao
kubectl delete pods -n n3-m1-autoscale --all

# Aguardar recreacao
kubectl wait --for=condition=ready pod -l app=demo-api -n n3-m1-autoscale --timeout=60s

# Verificar distribuicao
kubectl get pods -n n3-m1-autoscale -o wide
```

3. **Tentar drenar node COM PDB**

```bash
# Identificar node com 1 pod
NODE_WITH_POD=$(kubectl get pods -n n3-m1-autoscale -o wide | grep demo-api | head -n 1 | awk '{print $7}')

# Tentar drain
kubectl drain $NODE_WITH_POD --ignore-daemonsets --delete-emptydir-data

# Observe que:
# 1. PDB permite eviction (temos 2 replicas, minAvailable=1)
# 2. Pod e removido
# 3. Novo pod e criado em outro node
# 4. Disponibilidade mantida (sempre >= 1 pod rodando)
```

4. **Cenario critico: Drain com replicas=minAvailable**

```bash
# Reduzir para 1 replica (= minAvailable)
kubectl scale deployment demo-api -n n3-m1-autoscale --replicas=1

# Aguardar
sleep 10

# Tentar drenar node com o unico pod
NODE_NAME=$(kubectl get pods -n n3-m1-autoscale -o wide | grep demo-api | awk '{print $7}')

kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data --timeout=60s

# O que acontece:
# - Drain tentara evict o pod
# - PDB BLOQUEIA eviction (minAvailable=1 nao seria satisfeito)
# - Drain fica travado
# - DOWNTIME EVITADO!
```

5. **Solucao: Aumentar replicas ou ajustar PDB**

```bash
# Opcao A: Aumentar replicas
kubectl scale deployment demo-api -n n3-m1-autoscale --replicas=2

# Aguardar novo pod
sleep 15

# Agora drain funciona
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data
```

6. **Comportamento no Cloud com CA**

No cloud:
- CA tenta remover node
- Verifica PDB antes de drenar
- Se PDB bloquear, CA NAO remove o node
- Node e mantido ate haver mais replicas

---

### Cenario 5: Taints e Tolerations

**Objetivo:** Demonstrar como taints controlam onde pods podem ser agendados.

#### Passos:

1. **Adicionar taint em um node**

```bash
# Adicionar taint dedicated=api:NoSchedule
kubectl taint nodes n3-m1-autoscale-worker dedicated=api:NoSchedule

# Verificar
kubectl describe node n3-m1-autoscale-worker | grep -i taint
```

2. **Tentar agendar pod SEM toleration**

```bash
# Deletar pods para forcar reagendamento
kubectl delete pods -n n3-m1-autoscale --all

# Pods evitarao node com taint
kubectl get pods -n n3-m1-autoscale -o wide
```

3. **Adicionar toleration ao deployment**

```yaml
# kubectl edit deployment demo-api -n n3-m1-autoscale
spec:
  template:
    spec:
      tolerations:
        - key: dedicated
          operator: Equal
          value: api
          effect: NoSchedule
```

4. **Pods agora podem ser agendados no node com taint**

```bash
# Forcar recreacao
kubectl rollout restart deployment demo-api -n n3-m1-autoscale

# Verificar distribuicao
kubectl get pods -n n3-m1-autoscale -o wide
```

5. **Remover taint**

```bash
# Remover taint (sufixo -)
kubectl taint nodes n3-m1-autoscale-worker dedicated=api:NoSchedule-
```

---

## Diferenca: Simulacao vs Real

| Aspecto | Simulacao (Kind) | Real (Cloud + CA) |
|---------|------------------|-------------------|
| **Scale Up** | Manual (editar cluster ou requests) | Automatico (2-5 min) |
| **Scale Down** | Manual (drain + delete node) | Automatico (10-15 min) |
| **Deteccao** | Manual (observar Pending) | Automatico (CA monitora) |
| **Tempo** | Imediato (quando executar) | Delay intencional (evitar thrashing) |
| **Custo** | Zero | Por hora (VMs adicionais) |
| **Aprendizado** | ✅ Conceitos claros | ⚠️ "Caixa preta" |

---

## Exercicios Praticos

### Exercicio 1: Forcar Pending

1. Escalar deployment para 20 replicas
2. Observar pods Pending
3. Calcular quantos nodes adicionais seriam necessarios
4. Explicar por que estao Pending (CPU ou memoria?)

### Exercicio 2: Simular CA Scale Down

1. Reduzir replicas para 1
2. Identificar node subutilizado
3. Simular CA adicionando taint
4. Drenar node respeitando PDB
5. Verificar que pod foi recriado

### Exercicio 3: PDB Edge Case

1. Configurar replicas=1 e minAvailable=1
2. Tentar drenar node
3. Observar que drain fica bloqueado
4. Explicar por que (e como resolver)

### Exercicio 4: Topology Spread

1. Verificar distribuicao de pods entre zonas
2. Deletar todos pods
3. Observar que sao recriados distribuidos
4. Explicar como topologySpreadConstraints funciona

### Exercicio 5: HPA + Recursos

1. Iniciar stress test de CPU
2. Monitorar HPA escalando
3. Observar se pods ficam Pending
4. Calcular se cluster tem recursos suficientes

---

## Comandos Uteis para Simulacao

```bash
# Ver eventos em tempo real
kubectl get events -n n3-m1-autoscale -w

# Monitorar pods continuamente
watch -n 2 'kubectl get pods -n n3-m1-autoscale -o wide'

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n n3-m1-autoscale

# Descrever por que pod esta Pending
kubectl describe pod <pod-pending> -n n3-m1-autoscale | grep -A 10 Events

# Ver distribuicao de pods por node
kubectl get pods -n n3-m1-autoscale -o wide | awk '{print $7}' | sort | uniq -c

# Ver capacidade dos nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Simular CA marcando node
kubectl taint nodes <node> node.kubernetes.io/scale-down=scheduled:NoSchedule

# Simular CA removendo node
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <node>
```

---

## Conclusao

Embora nao possamos usar o Cluster Autoscaler real no Kind, **os conceitos sao os mesmos**:

1. ✅ **Pods Pending:** Trigger para scale up
2. ✅ **Resource Requests:** Base para calculo de necessidade
3. ✅ **Node Drain:** Processo de remocao de pods
4. ✅ **PDB:** Protecao durante interrupcoes
5. ✅ **Taints:** Marcacao de nodes para remocao
6. ⚠️ **Provisionamento:** Manual no Kind, automatico no cloud

Ao praticar estas simulacoes, voce desenvolve a intuicao necessaria para trabalhar com Cluster Autoscaler real em producao!
