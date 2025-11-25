# Metrics Server no Kubernetes

## O que é o Metrics Server?

O Metrics Server é um componente oficial do Kubernetes que coleta métricas de recursos (CPU e memória) dos nodes e pods em tempo real. Ele é essencial para o funcionamento do HPA (Horizontal Pod Autoscaler) e de comandos como `kubectl top`.

## Arquitetura

```txt
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐        ┌──────────────────┐                   │
│  │   HPA    │───────>│  Metrics Server  │                   │
│  └──────────┘        └────────┬─────────┘                   │
│                               │                             │
│                               │ Coleta métricas (15s)       │
│                               ↓                             │
│                      ┌─────────────────┐                    │
│                      │  Kubelet (API)  │                    │
│                      └────────┬────────┘                    │
│                               │                             │
│                               ↓                             │
│                      ┌─────────────────┐                    │
│                      │   cAdvisor      │                    │
│                      └────────┬────────┘                    │
│                               │                             │
│                               ↓                             │
│                      ┌─────────────────┐                    │
│                      │   Containers    │                    │
│                      └─────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Fluxo de Coleta de Métricas

1. **cAdvisor**: Container Advisor embutido no kubelet, coleta métricas de containers
2. **Kubelet**: Expõe API de métricas (porta 10250) agregando dados do cAdvisor
3. **Metrics Server**: Consulta todos os kubelets a cada 15s (configurável)
4. **API Aggregation**: Registra API `metrics.k8s.io` no kube-apiserver
5. **Consumidores**: HPA, VPA, kubectl top consomem via API

## Instalação para Kind/Minikube

```bash
# Aplicar manifesto do Metrics Server
kubectl apply -f manifests/01-metrics-server.yaml

# Aguardar pod ficar pronto (pode levar 1-2 minutos)
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

# Verificar status
kubectl get pods -n kube-system | grep metrics-server
```

## Verificação da Instalação

```bash
# Verificar se o APIService está disponível
kubectl get apiservice v1beta1.metrics.k8s.io

# Resultado esperado:
# NAME                     SERVICE                      AVAILABLE
# v1beta1.metrics.k8s.io   kube-system/metrics-server   True

# Aguardar ~60 segundos para primeira coleta de métricas
sleep 60

# Testar métricas dos nodes
kubectl top nodes

# Resultado esperado:
# NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
# k8s-lab-control-plane   176m         2%       606Mi           7%
# k8s-lab-worker          49m          0%       365Mi           4%

# Testar métricas dos pods
kubectl top pods -n demo

# Resultado esperado:
# NAME                        CPU(cores)   MEMORY(bytes)
# demo-api-7bd59bfdfc-xxxxx   1m           27Mi
```

## Configurações Importantes

### Para Kind/Minikube (Desenvolvimento)

```yaml
args:
  # Desabilita verificação de certificado TLS do kubelet
  # NECESSÁRIO em ambientes locais
  - --kubelet-insecure-tls

  # API aggregation também não valida TLS
spec:
  insecureSkipTLSVerify: true
```

### Para Produção

```yaml
args:
  # Remover --kubelet-insecure-tls
  # Configurar certificados adequados

  # Usar endereço preferencial interno
  - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname

  # Intervalo de coleta (padrão: 15s)
  - --metric-resolution=15s
```

## Componentes do Manifesto

### 1. ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
```

Conta de serviço com permissões para acessar recursos do cluster.

### 2. ClusterRoles

```yaml
# Permissões para leitura de métricas
kind: ClusterRole
metadata:
  name: system:aggregated-metrics-reader
rules:
  - apiGroups: ["metrics.k8s.io"]
    resources: ["pods", "nodes"]
    verbs: ["get", "list", "watch"]

# Permissões para o Metrics Server coletar dados
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
  - apiGroups: [""]
    resources: ["nodes/metrics"]
    verbs: ["get"]
```

### 3. Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
spec:
  ports:
    - name: https
      port: 443
      targetPort: https
  selector:
    k8s-app: metrics-server
```

Expõe o Metrics Server para comunicação HTTPS interna.

### 4. Deployment

```yaml
spec:
  replicas: 1  # Uma réplica suficiente para clusters pequenos
  template:
    spec:
      containers:
        - name: metrics-server
          image: registry.k8s.io/metrics-server/metrics-server:v0.7.2
          args:
            - --cert-dir=/tmp
            - --secure-port=10250
            - --kubelet-insecure-tls
            - --metric-resolution=15s
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 200m
              memory: 400Mi
```

### 5. APIService

```yaml
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
```

Registra a API `metrics.k8s.io` no kube-apiserver para API Aggregation.

## Recursos do Container

| Recurso | Request | Limit | Justificativa |
|---------|---------|-------|---------------|
| CPU | 100m | 200m | Coleta periódica, não intensivo |
| Memory | 200Mi | 400Mi | Armazena métricas em memória temporariamente |

## Probes de Saúde

### Liveness Probe

```yaml
livenessProbe:
  httpGet:
    path: /livez
    port: https
    scheme: HTTPS
  periodSeconds: 10
  failureThreshold: 3
```

Verifica se o processo está vivo. Reinicia o container após 3 falhas (30s).

### Readiness Probe

```yaml
readinessProbe:
  httpGet:
    path: /readyz
    port: https
    scheme: HTTPS
  initialDelaySeconds: 20
  periodSeconds: 10
  failureThreshold: 3
```

Verifica se está pronto para receber tráfego. Aguarda 20s antes da primeira verificação.

## Comandos Úteis

```bash
# Ver logs do Metrics Server
kubectl logs -n kube-system -l k8s-app=metrics-server

# Ver métricas de um node específico
kubectl top node k8s-lab-control-plane

# Ver métricas de pods ordenados por CPU
kubectl top pods -n demo --sort-by=cpu

# Ver métricas de pods ordenados por memória
kubectl top pods -n demo --sort-by=memory

# Ver métricas com containers detalhados
kubectl top pods -n demo --containers

# Descrever APIService
kubectl describe apiservice v1beta1.metrics.k8s.io
```

## Troubleshooting

### Problema: Métricas mostram "unknown"

```bash
# Verificar se o Metrics Server está rodando
kubectl get pods -n kube-system | grep metrics-server

# Verificar logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Aguardar primeiro ciclo de coleta (15-60 segundos)
```

### Problema: APIService mostra "False" em AVAILABLE

```bash
# Verificar status do APIService
kubectl get apiservice v1beta1.metrics.k8s.io

# Ver detalhes do problema
kubectl describe apiservice v1beta1.metrics.k8s.io

# Verificar se o Service existe
kubectl get svc metrics-server -n kube-system

# Verificar se o pod está healthy
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

### Problema: Erro de certificado TLS

```txt
Erro: x509: cannot validate certificate for 172.18.0.X
```

Solução: Adicionar `--kubelet-insecure-tls` aos args do container.

### Problema: Timeout ao coletar métricas

```bash
# Verificar conectividade entre Metrics Server e kubelets
kubectl exec -n kube-system <metrics-server-pod> -- wget -O- http://172.18.0.2:10250/metrics

# Verificar se kubelet está expondo métricas
docker exec k8s-lab-control-plane curl -k https://localhost:10250/metrics
```

## Diferenças: Metrics Server vs Prometheus

| Aspecto | Metrics Server | Prometheus |
|---------|----------------|------------|
| Propósito | Autoscaling (HPA) | Monitoramento e alertas |
| Retenção | ~1 minuto (apenas último valor) | Horas/dias/meses |
| Métricas | CPU e memória | Centenas de métricas custom |
| Resolução | 15 segundos | Configurável (1s-1m) |
| Storage | In-memory | Time-series database |
| Uso | HPA, VPA, kubectl top | Grafana, alertas, análise histórica |

## Segurança

### Contexto de Segurança

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop: ["ALL"]
```

Práticas de segurança aplicadas:

- Roda como usuário não-root (UID 1000)
- Filesystem somente leitura
- Sem escalação de privilégios
- Remove todas as capabilities do Linux
- Seccomp profile padrão do runtime

## Referências

- [Metrics Server GitHub](https://github.com/kubernetes-sigs/metrics-server)
- [Kubernetes API Aggregation](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)
- [Resource Metrics Pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)
