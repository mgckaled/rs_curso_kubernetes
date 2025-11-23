# Bloco B - Conhecendo o HPA (Horizontal Pod Autoscaler)

## Objetivos

- Entender escala vertical vs horizontal
- Instalar e configurar o Metrics Server
- Criar HPA v1 e v2 com diferentes métricas
- Realizar testes de estresse com Fortio
- Configurar políticas de scale up/down

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-metrics-server.yaml      # Metrics Server para coleta de métricas
├── 02-deployment.yaml          # Deployment da demo-api com resources definidos
├── 03-service.yaml             # Service para expor a aplicação
├── 04-hpa-v1.yaml              # HPA v1 (apenas CPU)
├── 05-hpa-v2.yaml              # HPA v2 (CPU + Memory)
├── 06-hpa-v2-behavior.yaml     # HPA v2 com políticas de stabilization
└── 07-fortio.yaml              # Pod Fortio para testes de carga
```

---

## Conceitos Importantes

### Escala Vertical vs Horizontal

| Aspecto | Vertical | Horizontal |
|---------|----------|------------|
| O que muda | Tamanho da máquina (CPU/RAM) | Número de réplicas |
| Downtime | Sim (reinício necessário) | Não |
| Limite | Hardware máximo | Teoricamente ilimitado |
| Kubernetes | VPA (Vertical Pod Autoscaler) | HPA (Horizontal Pod Autoscaler) |

### Metrics Server

O Metrics Server coleta métricas de CPU e memória dos pods em tempo real.
Sem ele, o HPA não funciona pois não tem dados para tomar decisões.

### HPA Triggers

- **CPU**: Porcentagem de utilização em relação ao `requests.cpu`
- **Memory**: Porcentagem de utilização em relação ao `requests.memory`
- **Custom Metrics**: Métricas customizadas via Prometheus Adapter

---

## Pré-requisitos

### 1. Namespace e Deployment do Bloco A

```bash
# Aplicar manifests do Bloco A primeiro
kubectl apply -f ../b-a/manifests/01-namespace.yaml
kubectl apply -f ../b-a/manifests/02-configmap.yaml
kubectl apply -f ../b-a/manifests/03-secret.yaml
```

### 2. Build da Imagem (se ainda não fez)

```bash
cd apps/demo-api
docker build -t demo-api:v1 .
kind load docker-image demo-api:v1 --name k8s-lab
```

---

## Prática 1: Instalar Metrics Server

```bash
# Aplicar Metrics Server (versão para Kind com --kubelet-insecure-tls)
kubectl apply -f manifests/01-metrics-server.yaml

# Aguardar Metrics Server ficar pronto
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

# Verificar instalação
kubectl get pods -n kube-system | grep metrics-server

# Testar métricas (aguarde ~60s após instalação)
kubectl top nodes
kubectl top pods -n demo
```

---

## Prática 2: Deployment com Resources

```bash
# Aplicar Deployment otimizado para HPA
kubectl apply -f manifests/02-deployment.yaml

# Verificar pods
kubectl get pods -n demo

# Verificar consumo de recursos
kubectl top pods -n demo
```

> **Importante:** O HPA calcula a porcentagem de uso baseado no `requests`, não no `limits`.

---

## Prática 3: Service

```bash
# Criar Service
kubectl apply -f manifests/03-service.yaml

# Verificar
kubectl get svc -n demo
```

---

## Prática 4: HPA v1 (CPU)

```bash
# Criar HPA v1 (apenas CPU)
kubectl apply -f manifests/04-hpa-v1.yaml

# Verificar HPA
kubectl get hpa -n demo

# Acompanhar em tempo real
kubectl get hpa -n demo -w
```

---

## Prática 5: HPA v2 (CPU + Memory)

```bash
# Remover HPA v1 antes de aplicar v2
kubectl delete hpa demo-api-hpa-v1 -n demo

# Criar HPA v2
kubectl apply -f manifests/05-hpa-v2.yaml

# Verificar
kubectl get hpa -n demo
kubectl describe hpa demo-api-hpa-v2 -n demo
```

---

## Prática 6: HPA v2 com Behavior

```bash
# Remover HPA v2 anterior
kubectl delete hpa demo-api-hpa-v2 -n demo

# Criar HPA v2 com políticas de estabilização
kubectl apply -f manifests/06-hpa-v2-behavior.yaml

# Ver detalhes das políticas
kubectl describe hpa demo-api-hpa-behavior -n demo
```

---

## Prática 7: Teste de Estresse com Fortio

```bash
# Criar pod Fortio
kubectl apply -f manifests/07-fortio.yaml

# Aguardar pod ficar pronto
kubectl wait --for=condition=ready pod/fortio -n demo --timeout=60s

# Executar teste de carga (8 threads, 30 segundos)
kubectl exec -n demo fortio -- fortio load -c 8 -t 30s -qps 0 http://demo-api-service/stress/cpu?duration=100

# Em outro terminal, observar HPA escalando
kubectl get hpa -n demo -w

# Observar pods sendo criados
kubectl get pods -n demo -w
```

### Cenários de Teste

```bash
# Teste de CPU (endpoint que consome CPU)
kubectl exec -n demo fortio -- fortio load -c 4 -t 60s -qps 0 http://demo-api-service/stress/cpu?duration=50

# Teste de Memory (endpoint que aloca memória)
kubectl exec -n demo fortio -- fortio load -c 2 -t 30s -qps 0 http://demo-api-service/stress/memory?mb=50

# Teste de escrita intensiva
kubectl exec -n demo fortio -- fortio load -c 4 -t 45s -qps 0 http://demo-api-service/stress/write
```

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `kubectl top nodes` | Métricas dos nodes |
| `kubectl top pods -n demo` | Métricas dos pods |
| `kubectl get hpa -n demo` | Listar HPAs |
| `kubectl describe hpa <name> -n demo` | Detalhes do HPA |
| `kubectl get hpa -n demo -w` | Watch em tempo real |
| `kubectl delete hpa <name> -n demo` | Remover HPA |

---

## Troubleshooting

### HPA mostra `<unknown>` nas métricas

```bash
# Verificar se Metrics Server está rodando
kubectl get pods -n kube-system | grep metrics-server

# Verificar logs do Metrics Server
kubectl logs -n kube-system -l k8s-app=metrics-server

# Aguardar ~60 segundos após instalação
```

### HPA não escala

```bash
# Verificar se o Deployment tem resources.requests definido
kubectl get deployment demo-api -n demo -o yaml | grep -A5 resources

# Verificar eventos do HPA
kubectl describe hpa -n demo
```

---

## Checklist

- [ ] Metrics Server instalado e funcionando
- [ ] `kubectl top pods` retornando métricas
- [ ] Deployment com `resources.requests` definido
- [ ] HPA v1 criado e monitorando CPU
- [ ] HPA v2 criado com CPU e Memory
- [ ] HPA v2 com behavior configurado
- [ ] Teste de estresse executado com Fortio
- [ ] Observado scale up automático
- [ ] Observado scale down após carga reduzir
