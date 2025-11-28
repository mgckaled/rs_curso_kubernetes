# Monitoramento com Prometheus e Grafana

## Visao Geral

Este diretorio contem configuracoes para instalar stack de monitoramento completo usando **kube-prometheus-stack**, que inclui:

- **Prometheus**: Coleta e armazenamento de metricas time-series
- **Grafana**: Visualizacao de dashboards
- **AlertManager**: Gerenciamento e roteamento de alertas
- **Node Exporter**: Metricas de hardware e OS dos nodes
- **Kube-State-Metrics**: Metricas dos objetos Kubernetes

---

## Pre-requisitos

### 1. Helm instalado

```bash
# Verificar instalacao
helm version

# Se nao estiver instalado:
# Windows (com Chocolatey)
choco install kubernetes-helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Mac
brew install helm
```

### 2. Cluster Kind rodando

```bash
# Verificar
kubectl cluster-info

# Se necessario, criar cluster
kind create cluster --config ../00-kind-cluster.yaml --name cloud-sim
```

---

## Instalacao

### Passo 1: Adicionar repositorio Helm

```bash
# Adicionar repo do Prometheus Community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Atualizar repos
helm repo update

# Verificar
helm search repo prometheus-community/kube-prometheus-stack
```

### Passo 2: Instalar kube-prometheus-stack

```bash
# Navegar ate o diretorio do projeto
cd n2/m1/b-a/manifests/07-monitoring

# Instalar com values customizados
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values-prometheus.yaml

# Aguardar pods ficarem prontos (pode levar 2-3 minutos)
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=300s
```

### Passo 3: Verificar instalacao

```bash
# Ver todos os pods do monitoring
kubectl get pods -n monitoring

# Saida esperada (pode variar):
# NAME                                                     READY   STATUS
# kube-prometheus-grafana-xxx                              3/3     Running
# kube-prometheus-kube-prome-operator-xxx                  1/1     Running
# kube-prometheus-kube-state-metrics-xxx                   1/1     Running
# kube-prometheus-prometheus-node-exporter-xxx             1/1     Running
# prometheus-kube-prometheus-kube-prome-prometheus-0       2/2     Running
# alertmanager-kube-prometheus-kube-prome-alertmanager-0   2/2     Running

# Ver Services
kubectl get svc -n monitoring
```

---

## Acessando as Ferramentas

### Grafana (Dashboards)

```bash
# Port-forward para Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3001:80

# Acessar no navegador:
# URL: http://localhost:3001
# Usuario: admin
# Senha: prom-operator (definida em values-prometheus.yaml)
```

#### Dashboards Pre-configurados

Apos login, explore os dashboards em:

1. **Dashboards > Browse**
2. Pastas disponiveis:
   - **General**: Overview geral do cluster
   - **Kubernetes / Compute Resources**: Metricas de CPU/memoria por namespace/pod
   - **Kubernetes / Networking**: Metricas de rede
   - **Node Exporter**: Metricas detalhadas dos nodes

#### Dashboards Recomendados

| Dashboard | Descricao |
|-----------|-----------|
| **Kubernetes / Compute Resources / Namespace (Pods)** | CPU e memoria por namespace |
| **Kubernetes / Compute Resources / Pod** | Detalhes de um pod especifico |
| **Node Exporter / Nodes** | CPU, memoria, disco, rede dos nodes |
| **Kubernetes / Networking / Pod** | Trafego de rede dos pods |

### Prometheus (Metricas)

```bash
# Port-forward para Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090

# Acessar no navegador:
# URL: http://localhost:9090
```

#### Queries Uteis no Prometheus

Acesse **Graph** e execute queries PromQL:

```promql
# CPU usage por pod
rate(container_cpu_usage_seconds_total{namespace="demo-cloud"}[5m])

# Memoria usage por pod
container_memory_usage_bytes{namespace="demo-cloud"}

# Request rate por segundo (demo-api)
rate(http_requests_total{namespace="demo-cloud"}[5m])

# Latencia p95 de requests
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Pods por namespace
count(kube_pod_info) by (namespace)

# Nodes disponiveis
kube_node_status_condition{condition="Ready",status="true"}
```

### AlertManager (Alertas)

```bash
# Port-forward para AlertManager
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-alertmanager 9093:9093

# Acessar no navegador:
# URL: http://localhost:9093
```

---

## Monitorando a Demo API

### Passo 1: Verificar metricas da demo-api

```bash
# A demo-api expoe metricas em /metrics
# Se a demo-api estiver rodando com Service LoadBalancer:

# Obter IP do Service
DEMO_API_IP=$(kubectl get svc demo-api-lb -n demo-cloud -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Acessar metricas
curl http://$DEMO_API_IP:3000/metrics

# Ou via Ingress
curl -H "Host: demo-api.local" http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/metrics
```

### Passo 2: Criar ServiceMonitor (opcional)

O Prometheus pode descobrir automaticamente metricas de Services com labels especificas. Crie um ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: demo-api-metrics
  namespace: demo-cloud
  labels:
    app.kubernetes.io/name: demo-api
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: demo-api
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

```bash
# Aplicar
kubectl apply -f servicemonitor-demo-api.yaml

# Verificar no Prometheus: Status > Targets
# Deve aparecer "demo-cloud/demo-api-metrics/0"
```

---

## Dashboards Customizados

### Criando Dashboard para Demo API

1. Acessar Grafana (http://localhost:3001)
2. Login: admin / prom-operator
3. **Dashboards > Create > New Dashboard**
4. **Add > Visualization**
5. Selecionar datasource: **Prometheus**
6. Adicionar query PromQL:

```promql
# CPU Usage
rate(container_cpu_usage_seconds_total{namespace="demo-cloud",pod=~"demo-api.*"}[5m])

# Memoria Usage
container_memory_usage_bytes{namespace="demo-cloud",pod=~"demo-api.*"}

# Request Rate
rate(http_requests_total{namespace="demo-cloud"}[5m])

# Request Duration p95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="demo-cloud"}[5m]))
```

7. Configurar visualizacao (Time series, Gauge, etc)
8. **Save dashboard**

---

## Limpeza

### Desinstalar kube-prometheus-stack

```bash
# Desinstalar release
helm uninstall kube-prometheus -n monitoring

# Deletar namespace (remove tudo)
kubectl delete namespace monitoring

# Verificar CRDs (opcional: remover se nao for usar mais Prometheus)
kubectl get crd | grep monitoring.coreos.com

# Remover CRDs (CUIDADO: remove definicoes de ServiceMonitor, PodMonitor, etc)
kubectl delete crd \
  alertmanagerconfigs.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  podmonitors.monitoring.coreos.com \
  probes.monitoring.coreos.com \
  prometheusagents.monitoring.coreos.com \
  prometheuses.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com \
  scrapeconfigs.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  thanosrulers.monitoring.coreos.com
```

---

## Troubleshooting

### Pods nao iniciam

```bash
# Ver status dos pods
kubectl get pods -n monitoring

# Ver eventos
kubectl describe pod <pod-name> -n monitoring

# Ver logs
kubectl logs <pod-name> -n monitoring

# Problemas comuns:
# - Recursos insuficientes: aumentar resources em values-prometheus.yaml
# - ImagePullBackOff: problema de rede ou registry
```

### Grafana nao carrega dashboards

```bash
# Verificar se Grafana esta rodando
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Ver logs do Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f

# Restartar Grafana
kubectl rollout restart deployment kube-prometheus-grafana -n monitoring
```

### Prometheus nao coleta metricas

```bash
# Acessar Prometheus UI
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090

# Verificar targets: Status > Targets
# Targets devem estar "UP"

# Se target esta "DOWN":
# - Verificar se o pod/service existe
# - Verificar se porta esta correta
# - Verificar NetworkPolicies
# - Ver logs do Prometheus
kubectl logs -n monitoring prometheus-kube-prometheus-kube-prome-prometheus-0 -c prometheus
```

---

## Recursos Adicionais

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Kube-Prometheus-Stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
