# Bloco A - Kubernetes Gerenciado (Simulacao Local com Kind)

## Objetivos

- Entender conceitos de Kubernetes gerenciado (managed Kubernetes)
- Simular ambiente cloud localmente com Kind
- Configurar LoadBalancer com MetalLB
- Implementar Ingress Controller para roteamento HTTP
- Expor aplicacoes para acesso externo
- Instalar ferramentas de monitoramento (Prometheus/Grafana)

---

## Contexto

Este bloco aborda conceitos de **Kubernetes gerenciado** (como DigitalOcean DOKS e AWS EKS), onde o Control Plane e gerenciado pelo provedor de cloud. Como o curso foca em custo zero, vamos **simular** esse ambiente localmente com Kind, implementando os mesmos conceitos e praticas.

### O que vamos simular

| Conceito Cloud | Simulacao Local com Kind |
|----------------|--------------------------|
| Control Plane gerenciado | Kind gerencia control plane automaticamente |
| Load Balancer externo | MetalLB (implementacao de LoadBalancer local) |
| Ingress para roteamento HTTP | Nginx Ingress Controller |
| Node groups com multiplos workers | Cluster Kind com 3 worker nodes |
| Monitoramento (Prometheus/Grafana) | kube-prometheus-stack via Helm |

---

## Estrutura de Arquivos

```txt
manifests/
├── 00-kind-cluster.yaml           # Configuracao do cluster Kind multi-node
├── 01-namespace.yaml              # Namespace para aplicacao
├── 02-deployment.yaml             # Deployment da demo-api
├── 03-service-clusterip.yaml      # Service ClusterIP (interno)
├── 04-service-loadbalancer.yaml   # Service LoadBalancer (com MetalLB)
├── 05-ingress.yaml                # Ingress para roteamento HTTP
├── 06-metallb-config.yaml         # Configuracao do MetalLB
└── 07-monitoring/                 # Manifestos de monitoramento
    ├── values-prometheus.yaml     # Configuracao do Prometheus
    └── README.md                  # Guia de instalacao
```

---

## Pre-requisitos

### 1. Ferramentas necessarias

```bash
# Verificar instalacoes
kind version
kubectl version --client
helm version
docker --version
```

### 2. Build da demo-api

```bash
# Navegar ate o diretorio da demo-api
cd apps/demo-api

# Build da imagem
docker build -t demo-api:v1 .

# Voltar para raiz
cd ../..
```

---

## Parte 1: Criando Cluster Kind Multi-Node

### Passo 1: Criar cluster simulando ambiente cloud

```bash
# Criar cluster com 1 control-plane + 3 workers
kind create cluster --config n2/m1/b-a/manifests/00-kind-cluster.yaml --name cloud-sim

# Verificar nodes
kubectl get nodes

# Saida esperada:
# NAME                      STATUS   ROLES           AGE   VERSION
# cloud-sim-control-plane   Ready    control-plane   1m    v1.31.0
# cloud-sim-worker          Ready    <none>          1m    v1.31.0
# cloud-sim-worker2         Ready    <none>          1m    v1.31.0
# cloud-sim-worker3         Ready    <none>          1m    v1.31.0
```

### Passo 2: Carregar imagem no cluster

```bash
# Carregar demo-api no Kind
kind load docker-image demo-api:v1 --name cloud-sim

# Verificar
docker exec -it cloud-sim-control-plane crictl images | grep demo-api
```

---

## Parte 2: Instalando MetalLB (Simulacao de LoadBalancer)

### Contexto: O que e MetalLB?

Em clouds gerenciadas, quando voce cria um Service tipo `LoadBalancer`, o provedor provisiona automaticamente um load balancer externo (ex: AWS ELB, DigitalOcean LB). No Kind, nao ha esse provisionamento automatico.

**MetalLB** e uma implementacao de LoadBalancer para clusters bare-metal e locais, que:

- Atribui IPs externos para Services tipo LoadBalancer
- Permite acesso externo ao cluster via esses IPs
- Simula o comportamento de load balancers de cloud

### Passo 1: Instalar MetalLB

```bash
# Aplicar manifests do MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Aguardar pods ficarem prontos
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Verificar instalacao
kubectl get pods -n metallb-system
```

### Passo 2: Configurar pool de IPs

```bash
# Descobrir range de IPs do Docker
docker network inspect -f '{{.IPAM.Config}}' kind

# Saida exemplo: [{172.18.0.0/16  172.18.0.1 map[]}]
# Usaremos range: 172.18.255.200-172.18.255.250

# Aplicar configuracao do MetalLB
kubectl apply -f n2/m1/b-a/manifests/06-metallb-config.yaml

# Verificar configuracao
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

---

## Parte 3: Deploy da Aplicacao

### Passo 1: Aplicar namespace e deployment

```bash
# Criar namespace
kubectl apply -f n2/m1/b-a/manifests/01-namespace.yaml

# Aplicar deployment
kubectl apply -f n2/m1/b-a/manifests/02-deployment.yaml

# Verificar pods
kubectl get pods -n demo-cloud -w
```

### Passo 2: Criar Service ClusterIP (acesso interno)

```bash
# Aplicar service interno
kubectl apply -f n2/m1/b-a/manifests/03-service-clusterip.yaml

# Verificar service
kubectl get svc -n demo-cloud

# Testar internamente (de dentro do cluster)
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -n demo-cloud -- \
  curl http://demo-api-service:3000/health
```

### Passo 3: Expor via LoadBalancer (MetalLB)

```bash
# Aplicar service LoadBalancer
kubectl apply -f n2/m1/b-a/manifests/04-service-loadbalancer.yaml

# Aguardar IP externo ser atribuido pelo MetalLB
kubectl get svc demo-api-lb -n demo-cloud -w

# Saida esperada:
# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)
# demo-api-lb   LoadBalancer   10.96.123.45    172.18.255.200    3000:30123/TCP

# Testar acesso externo
curl http://172.18.255.200:3000/health
```

---

## Parte 4: Configurando Ingress Controller

### Contexto: LoadBalancer vs Ingress

| Abordagem | Custo | Uso |
|-----------|-------|-----|
| **LoadBalancer** | 1 LB por Service (caro em cloud) | Ideal para servicos TCP/UDP |
| **Ingress** | 1 LB + roteamento HTTP(S) | Ideal para multiplas aplicacoes HTTP |

Em cloud, cada Service LoadBalancer custa ~$12-15/mes. Com Ingress, voce usa **1 unico LoadBalancer** e roteia multiplas apps via path/host.

### Passo 1: Instalar Nginx Ingress Controller

```bash
# Instalar via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar no namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Aguardar Ingress Controller ficar pronto
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verificar IP externo atribuido pelo MetalLB
kubectl get svc -n ingress-nginx
```

### Passo 2: Criar Ingress para demo-api

```bash
# Aplicar Ingress
kubectl apply -f n2/m1/b-a/manifests/05-ingress.yaml

# Verificar Ingress
kubectl get ingress -n demo-cloud

# Saida esperada:
# NAME              CLASS   HOSTS            ADDRESS          PORTS
# demo-api-ingress  nginx   demo-api.local   172.18.255.201   80
```

### Passo 3: Testar acesso via Ingress

```bash
# Obter IP do Ingress Controller
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Testar com header Host
curl -H "Host: demo-api.local" http://$INGRESS_IP/health

# Ou adicionar ao /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
# 172.18.255.201  demo-api.local

# Depois testar diretamente
curl http://demo-api.local/health
```

---

## Parte 5: Monitoramento com Prometheus e Grafana

### Passo 1: Instalar kube-prometheus-stack

```bash
# Adicionar repo do Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar com configuracoes customizadas
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values n2/m1/b-a/manifests/07-monitoring/values-prometheus.yaml

# Aguardar pods ficarem prontos
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=180s
```

### Passo 2: Acessar Grafana

```bash
# Port-forward para Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3001:80

# Acessar: http://localhost:3001
# Usuario: admin
# Senha: prom-operator (definida em values-prometheus.yaml)
```

### Passo 3: Configurar ServiceMonitor para demo-api

```bash
# O kube-prometheus-stack ja vem com ServiceMonitors pre-configurados
# Para nossa demo-api expor metricas, verificar endpoint /metrics

# Testar metricas da demo-api
curl http://demo-api.local/metrics

# Ver dashboards no Grafana:
# - Kubernetes / Compute Resources / Namespace (Pods)
# - Kubernetes / Compute Resources / Pod
# - Node Exporter / Nodes
```

---

## Comparacao: Kind vs Cloud Real

| Aspecto | Kind (Local) | Cloud Gerenciada (DO/AWS) |
|---------|--------------|---------------------------|
| **Control Plane** | Gerenciado pelo Kind | Gerenciado pelo provedor |
| **Worker Nodes** | Containers Docker | VMs reais (Droplets/EC2) |
| **LoadBalancer** | MetalLB (IPs locais) | LB real do provedor ($$$) |
| **Storage** | hostPath/local-path | Block Storage/EBS ($$$) |
| **Networking** | Bridge Docker | VPC real com subnets |
| **Custo** | Gratuito | $50-200+/mes |
| **Performance** | Limitado pela maquina | Escalavel sob demanda |

---

## Conceitos Aprendidos

### 1. Kubernetes Gerenciado

- Control Plane abstraido e gerenciado
- Foco em workloads, nao em infraestrutura
- Atualizacoes automaticas do control plane
- Alta disponibilidade garantida pelo provedor

### 2. Load Balancer

- Service tipo LoadBalancer provisiona LB externo
- Em cloud: custa dinheiro por LB
- MetalLB: simula localmente
- Importante: 1 LB por Service pode ficar caro

### 3. Ingress Controller

- Camada L7 (HTTP/HTTPS) para roteamento
- 1 unico LoadBalancer para multiplas aplicacoes
- Roteamento via host e path
- Economia significativa em cloud

### 4. Monitoramento

- Prometheus: coleta metricas time-series
- Grafana: visualizacao de metricas
- ServiceMonitor: configura scrape automatico
- Essencial para observabilidade em producao

---

## Comandos Uteis

| Comando | Descricao |
|---------|-----------|
| `kind get clusters` | Listar clusters Kind |
| `kubectl cluster-info` | Info do cluster atual |
| `kubectl get nodes` | Listar nodes (workers) |
| `kubectl get svc -A` | Listar todos services |
| `kubectl get ingress -A` | Listar todos ingresses |
| `helm list -A` | Listar releases do Helm |

---

## Troubleshooting

### MetalLB nao atribui IP externo

```bash
# Verificar logs do MetalLB
kubectl logs -n metallb-system -l app=metallb -l component=controller

# Verificar configuracao
kubectl describe ipaddresspool -n metallb-system
```

### Ingress Controller nao responde

```bash
# Verificar pods do Ingress
kubectl get pods -n ingress-nginx

# Ver logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Verificar se service tem EXTERNAL-IP
kubectl get svc -n ingress-nginx
```

### Prometheus nao coleta metricas

```bash
# Verificar ServiceMonitors
kubectl get servicemonitor -n monitoring

# Ver targets no Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090
# Acessar: http://localhost:9090/targets
```

---

## Limpeza

```bash
# Deletar namespace da aplicacao
kubectl delete namespace demo-cloud

# Desinstalar Ingress Controller
helm uninstall ingress-nginx -n ingress-nginx

# Desinstalar Prometheus
helm uninstall kube-prometheus -n monitoring

# Deletar MetalLB
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Deletar cluster Kind
kind delete cluster --name cloud-sim
```

---

## Checklist

- [ ] Cluster Kind multi-node criado
- [ ] MetalLB instalado e configurado
- [ ] Deployment da demo-api rodando
- [ ] Service ClusterIP testado internamente
- [ ] Service LoadBalancer com IP externo acessivel
- [ ] Nginx Ingress Controller instalado
- [ ] Ingress criado e testado via host header
- [ ] Prometheus/Grafana instalados
- [ ] Dashboards do Grafana acessados
- [ ] Metricas da demo-api visiveis no Prometheus

---

## Proximos Passos

No proximo bloco (N2-M1-B), vamos explorar **RBAC** (Role-Based Access Control) para controlar permissoes dentro do cluster, criando usuarios, roles e rolebindings.
