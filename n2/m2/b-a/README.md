<!-- markdownlint-disable -->

# Bloco A - StatefulSet e DaemonSet

## Objetivos

- Entender StatefulSets e suas diferencas para Deployments
- Implementar PostgreSQL com StatefulSet
- Conhecer PostgreSQL Operators (CloudNativePG)
- Configurar Headless Services
- Implementar DaemonSets para monitoramento
- Conectar demo-api ao PostgreSQL

---

## Contexto

Este bloco aborda **aplicacoes stateful** no Kubernetes, focando em:

- **StatefulSet**: gerenciamento de aplicacoes com estado (databases)
- **PostgreSQL**: banco de dados relacional em K8s
- **Operators**: automacao de operacoes complexas (CloudNativePG)
- **DaemonSet**: agentes em todos os nodes (monitoramento)

---

## Estrutura

```txt
manifests/
├── statefulset/
│   ├── 01-namespace.yaml
│   ├── 02-storageclass.yaml
│   ├── 03-postgres-statefulset.yaml
│   └── 04-postgres-service.yaml
├── postgres-operator/
│   ├── 01-cnpg-operator.yaml
│   ├── 02-postgres-cluster.yaml
│   └── 03-demo-api-deployment.yaml
└── daemonset/
    ├── 01-node-exporter-daemonset.yaml
    └── 02-node-exporter-service.yaml
```

---

## Parte 1: StatefulSet com PostgreSQL

### Conceitos

| Deployment | StatefulSet |
|------------|-------------|
| Pods intercambiaveis | Identidade estavel (web-0, web-1) |
| Ordem arbitraria | Deploy/delete sequencial |
| Nome aleatorio | Nome previsivel |
| Stateless | Stateful (databases) |

### Passos

```bash
# Aplicar namespace
kubectl apply -f n2/m2/b-a/manifests/statefulset/01-namespace.yaml

# Aplicar StatefulSet PostgreSQL
kubectl apply -f n2/m2/b-a/manifests/statefulset/03-postgres-statefulset.yaml

# Aplicar Headless Service
kubectl apply -f n2/m2/b-a/manifests/statefulset/04-postgres-service.yaml

# Verificar pods (criados sequencialmente)
kubectl get pods -n database -w

# Conectar ao PostgreSQL
kubectl exec -it postgres-0 -n database -- psql -U admin -d testdb
```

---

## Parte 2: PostgreSQL Operator (CloudNativePG)

### Vantagens do Operator

- Alta disponibilidade automatica
- Failover automatico
- Backups gerenciados
- Replicacao streaming
- CRDs declarativos

### Passos

```bash
# Instalar operator
kubectl apply -f n2/m2/b-a/manifests/postgres-operator/01-cnpg-operator.yaml

# Aguardar operator
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=120s

# Criar cluster PostgreSQL (3 replicas com HA)
kubectl apply -f n2/m2/b-a/manifests/postgres-operator/02-postgres-cluster.yaml

# Verificar cluster
kubectl get cluster -n database
kubectl get pods -n database

# Ver secrets criados automaticamente
kubectl get secrets -n database
```

---

## Parte 3: Conectar Demo-API ao PostgreSQL

```bash
# Deploy demo-api com variaveis de ambiente para PostgreSQL
kubectl apply -f n2/m2/b-a/manifests/postgres-operator/03-demo-api-deployment.yaml

# Verificar conexao
kubectl logs -n database -l app=demo-api-db -f
```

---

## Parte 4: DaemonSet (Node Exporter)

### Conceito

DaemonSet garante que **todos os nodes** executem uma copia do Pod.
Uso comum: monitoring, logging, networking

### Passos

```bash
# Aplicar Node Exporter DaemonSet
kubectl apply -f n2/m2/b-a/manifests/daemonset/01-node-exporter-daemonset.yaml

# Aplicar Service
kubectl apply -f n2/m2/b-a/manifests/daemonset/02-node-exporter-service.yaml

# Verificar (1 pod por node)
kubectl get pods -n monitoring -o wide

# Testar metricas
kubectl port-forward -n monitoring svc/node-exporter 9100:9100
curl http://localhost:9100/metrics
```

---

## Comandos Uteis

```bash
# StatefulSet
kubectl get statefulset -n database
kubectl describe statefulset postgres -n database
kubectl scale statefulset postgres --replicas=3 -n database

# PVCs
kubectl get pvc -n database
kubectl describe pvc data-postgres-0 -n database

# DaemonSet
kubectl get daemonset -A
kubectl describe daemonset node-exporter -n monitoring

# PostgreSQL Operator
kubectl get cluster -n database
kubectl describe cluster postgres-cluster -n database
```

---

## Limpeza

```bash
kubectl delete -f n2/m2/b-a/manifests/
kubectl delete namespace database monitoring cnpg-system
```

---

## Checklist

- [ ] StatefulSet PostgreSQL criado
- [ ] Pods criados sequencialmente (postgres-0, postgres-1, ...)
- [ ] PVCs criados automaticamente
- [ ] Headless Service funcionando
- [ ] PostgreSQL Operator instalado
- [ ] Cluster PostgreSQL com 3 replicas
- [ ] Demo-API conectada ao banco
- [ ] DaemonSet rodando em todos nodes
- [ ] Node Exporter expondo metricas

---

## Proximos Passos

Bloco B: CI/CD com GitHub Actions
