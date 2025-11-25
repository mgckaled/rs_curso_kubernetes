<!-- markdownlint-disable -->

# Acessando Pods e Services no Kubernetes

## Contexto

Este documento explica as diferentes formas de acessar pods e services no Kubernetes, quando usar cada abordagem e as melhores práticas.

---

## Conceitos Fundamentais

### Pod vs Service

| Conceito | Característica | Acesso |
|----------|----------------|--------|
| **Pod** | Efêmero, IP muda ao recriar | Não recomendado diretamente |
| **Service** | Estável, IP fixo, load balancing | Forma recomendada |

### Por que não acessar pods diretamente?

- Pods são efêmeros - podem ser recriados a qualquer momento
- IP do pod muda quando é recriado
- Sem load balancing entre réplicas
- Não há failover automático

---

## Port-Forward: Ferramenta de Debug

O comando `kubectl port-forward` é uma ferramenta de **desenvolvimento e debug** que mapeia uma porta local para um recurso no cluster.

### Sintaxe Básica

```bash
kubectl port-forward <tipo>/<nome> <porta-local>:<porta-container> -n <namespace>
```

---

## Opção 1: Port-Forward em Pod Individual

### Quando usar

- Debug de um pod específico
- Investigar problema em réplica específica
- Testes isolados

### Comando

```bash
# Mapear localhost:8080 para o pod específico
kubectl port-forward pod/nginx-deployment-8fb5b4578-8nb5z 8080:80 -n lab

# Acessar
# Linux/Mac:
curl http://localhost:8080

# PowerShell:
Invoke-WebRequest http://localhost:8080

# Navegador:
# http://localhost:8080
```

### Múltiplos pods em portas diferentes

```bash
# Terminal 1: Pod 1 em localhost:8081
kubectl port-forward pod/nginx-deployment-8fb5b4578-8nb5z 8081:80 -n lab

# Terminal 2: Pod 2 em localhost:8082
kubectl port-forward pod/nginx-deployment-8fb5b4578-b69bh 8082:80 -n lab

# Terminal 3: Pod 3 em localhost:8083
kubectl port-forward pod/nginx-deployment-8fb5b4578-dw27m 8083:80 -n lab
```

Acesso:

- Pod 1: `http://localhost:8081`
- Pod 2: `http://localhost:8082`
- Pod 3: `http://localhost:8083`

### Limitações

- Requer um terminal aberto para cada conexão
- Se o terminal fechar, a conexão cai
- Apenas para desenvolvimento/debug
- Não há load balancing
- Não é escalável

### Visualização

```txt
Terminal 1                 Terminal 2                 Terminal 3
    |                          |                          |
    v                          v                          v
localhost:8081             localhost:8082             localhost:8083
    |                          |                          |
    v                          v                          v
  Pod 1                      Pod 2                      Pod 3
```

---

## Opção 2: Port-Forward em Service (Recomendado para Debug)

### Quando usar

- Desenvolvimento local
- Testar aplicação com load balancing
- Debug geral da aplicação

### Comando

```bash
# Mapear localhost:8080 para o Service
kubectl port-forward svc/nginx-service 8080:80 -n lab

# Acessar
curl http://localhost:8080
```

### Vantagens

- Load balancing automático entre pods
- Service roteia para pods saudáveis
- Apenas 1 terminal necessário
- Simula comportamento de produção

### Visualização

```txt
Terminal único
      |
      v
localhost:8080
      |
      v
nginx-service (Service)
      |
      +-------+-------+
      |       |       |
      v       v       v
    Pod 1   Pod 2   Pod 3

Cada requisição pode ser atendida por um pod diferente!
```

### Demonstração de Load Balancing

```powershell
# PowerShell: Fazer 10 requisições
for ($i=1; $i -le 10; $i++) {
    Write-Host "Requisição $i"
    Invoke-WebRequest http://localhost:8080 | Select-Object StatusCode
}
```

```bash
# Linux/Mac: Fazer 10 requisições
for i in {1..10}; do
    echo "Requisição $i"
    curl -s http://localhost:8080 > /dev/null
done
```

O Service distribui automaticamente entre os 3 pods!

---

## Opção 3: ClusterIP Service (Padrão)

### Características

- Tipo padrão de Service
- IP interno do cluster
- Não acessível de fora do cluster
- Usado para comunicação entre pods

### Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: lab
spec:
  type: ClusterIP  # Padrão (pode omitir)
  selector:
    app: nginx
  ports:
  - port: 80        # Porta do Service
    targetPort: 80  # Porta do container
```

### Acesso

```bash
# Dentro do cluster (de outro pod):
curl http://nginx-service.lab.svc.cluster.local

# De fora do cluster: usar port-forward
kubectl port-forward svc/nginx-service 8080:80 -n lab
```

### Quando usar

- Comunicação interna entre microserviços
- Pods se comunicando entre si
- Não precisa de acesso externo

---

## Opção 4: NodePort Service

### Características

- Expõe Service em porta fixa em todos os nós
- Range de portas: 30000-32767
- Acessível via IP de qualquer nó
- Não precisa de port-forward

### Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  namespace: lab
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80          # Porta do Service
    targetPort: 80    # Porta do container
    nodePort: 30080   # Porta no nó (30000-32767)
```

### Aplicar

```bash
kubectl apply -f service-nodeport.yaml
```

### Acesso

```bash
# Acesso direto sem port-forward
# http://localhost:30080
# http://<node-ip>:30080

# Testar
curl http://localhost:30080
```

### Visualização

```txt
localhost:30080
      |
      v
  Qualquer Nó
      |
      v
nginx-nodeport (NodePort Service)
      |
      +-------+-------+
      |       |       |
      v       v       v
    Pod 1   Pod 2   Pod 3
```

### Quando usar

- Ambientes de desenvolvimento
- Clusters on-premise sem LoadBalancer
- Acesso persistente sem port-forward
- Testes de integração

### Limitações

- Expõe porta alta (30000+) não convencional
- Precisa gerenciar IPs dos nós
- Não ideal para produção em cloud

---

## Opção 5: LoadBalancer Service

### Características

- Provisiona um Load Balancer externo
- Disponível em ambientes cloud (AWS, GCP, Azure)
- IP público automático
- Ideal para produção

### Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  namespace: lab
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Acesso

```bash
# Verificar IP externo
kubectl get svc nginx-loadbalancer -n lab

# Saída:
# NAME                  TYPE           EXTERNAL-IP      PORT(S)
# nginx-loadbalancer    LoadBalancer   203.0.113.42     80:31234/TCP

# Acessar
curl http://203.0.113.42
```

### Quando usar

- Produção em cloud
- Aplicações públicas
- Precisa de IP fixo e gerenciado

### Limitações

- Funciona apenas em clouds com suporte
- Kind/Minikube: não provisiona IP real
- Custo adicional (cloud providers cobram por LB)

---

## Comparação de Tipos de Service

| Tipo | Acesso Externo | Load Balancing | Port-Forward | Produção | Custo |
|------|----------------|----------------|--------------|----------|-------|
| **ClusterIP** | Não (apenas interno) | Sim | Sim | Sim (interno) | Grátis |
| **NodePort** | Sim (porta alta) | Sim | Não necessário | Dev/Staging | Grátis |
| **LoadBalancer** | Sim (IP público) | Sim | Não necessário | Sim | Pago (cloud) |

---

## Comparação de Abordagens de Acesso

| Abordagem | Portas | Load Balancing | Persistente | Uso Recomendado |
|-----------|--------|----------------|-------------|-----------------|
| Port-forward em pod | 8081, 8082, 8083 | Não | Não | Debug de pod específico |
| Port-forward em Service | 8080 | Sim | Não | Debug local geral |
| ClusterIP + port-forward | 8080 | Sim | Não | Dev local |
| NodePort | 30080 | Sim | Sim | Dev/Staging |
| LoadBalancer | 80 | Sim | Sim | Produção |

---

## Verificando Configuração de Service

### Ver Services

```bash
# Listar services
kubectl get services -n lab
kubectl get svc -n lab

# Ver detalhes
kubectl describe svc nginx-service -n lab
```

### Ver Endpoints

Endpoints são os IPs dos pods que o Service está roteando:

```bash
# Ver endpoints
kubectl get endpoints nginx-service -n lab

# Saída exemplo:
# NAME            ENDPOINTS
# nginx-service   10.244.0.5:80,10.244.1.3:80,10.244.1.4:80
```

### Verificar Pods Selecionados

```bash
# Ver quais pods o Service está selecionando
kubectl get pods -n lab -l app=nginx -o wide

# Ver labels dos pods
kubectl get pods -n lab --show-labels
```

---

## DNS Interno do Kubernetes

Services criam entradas DNS automáticas no cluster:

### Formato

```txt
<service-name>.<namespace>.svc.cluster.local
```

### Exemplos

```bash
# Dentro do mesmo namespace
curl http://nginx-service

# De outro namespace
curl http://nginx-service.lab.svc.cluster.local

# Forma completa sempre funciona
curl http://nginx-service.lab.svc.cluster.local
```

### Testar DNS

```bash
# Criar pod temporário para teste
kubectl run test-pod --image=busybox -n lab --rm -it -- sh

# Dentro do pod:
nslookup nginx-service
nslookup nginx-service.lab.svc.cluster.local

# Testar conectividade
wget -qO- http://nginx-service
```

---

## Comandos Úteis

### Port-Forward

```bash
# Pod específico
kubectl port-forward pod/<pod-name> <local>:<container> -n <namespace>

# Service
kubectl port-forward svc/<service-name> <local>:<service-port> -n <namespace>

# Deployment (redireciona para um pod do deployment)
kubectl port-forward deployment/<deployment-name> <local>:<container> -n <namespace>

# Escutar em todas as interfaces (0.0.0.0)
kubectl port-forward --address 0.0.0.0 svc/<service-name> <local>:<container> -n <namespace>
```

### Services

```bash
# Listar services
kubectl get svc -n <namespace>

# Detalhes do service
kubectl describe svc <service-name> -n <namespace>

# Ver endpoints
kubectl get endpoints <service-name> -n <namespace>

# Editar service
kubectl edit svc <service-name> -n <namespace>

# Deletar service
kubectl delete svc <service-name> -n <namespace>
```

### Debug

```bash
# Ver logs de todos os pods de um service
kubectl logs -l app=nginx -n lab --tail=20

# Executar comando em pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Ver eventos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## Casos de Uso Práticos

### Caso 1: Debug de Pod Específico

```bash
# Identificar pods
kubectl get pods -n lab -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[*].image

# Pod 2 está com comportamento estranho
kubectl port-forward pod/nginx-deployment-8fb5b4578-b69bh 8082:80 -n lab

# Testar diretamente esse pod
curl http://localhost:8082

# Ver logs desse pod
kubectl logs nginx-deployment-8fb5b4578-b69bh -n lab

# Entrar no container
kubectl exec -it nginx-deployment-8fb5b4578-b69bh -n lab -- /bin/sh
```

### Caso 2: Desenvolvimento Local

```bash
# Usar Service para simular produção
kubectl port-forward svc/nginx-service 8080:80 -n lab

# Desenvolver aplicação que consome a API
# http://localhost:8080 no código
```

### Caso 3: Testes de Integração

```yaml
# service-nodeport.yaml para CI/CD
apiVersion: v1
kind: Service
metadata:
  name: nginx-test
  namespace: lab
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

```bash
# CI/CD pode acessar diretamente
curl http://localhost:30080
```

---

## Boas Práticas

### Faça

1. **Use Services para acesso normal**
   - Services fornecem load balancing
   - IP estável e DNS automático
   - Failover automático

2. **Use ClusterIP para comunicação interna**
   - Padrão para microserviços
   - Não expõe desnecessariamente

3. **Use port-forward apenas para debug**
   - Temporário e local
   - Não deixe rodando permanentemente

4. **Use labels consistentes**
   - Service usa labels para selecionar pods
   - Labels devem corresponder ao selector

5. **Defina resources nos pods**
   - Service roteia apenas para pods Ready
   - Pods sem resources podem causar problemas

### Não faça

1. **Não acesse pods diretamente em produção**
   - Use Services sempre
   - Pods são efêmeros

2. **Não use NodePort em produção cloud**
   - Use LoadBalancer
   - NodePort expõe portas não convencionais

3. **Não deixe port-forward rodando 24/7**
   - É ferramenta de debug
   - Use Service types apropriados

4. **Não use port-forward para aplicações de usuários**
   - Apenas desenvolvimento
   - Use Ingress ou LoadBalancer

---

## Troubleshooting

### Port-forward não conecta

```bash
# Verificar se pod está rodando
kubectl get pods -n lab

# Verificar logs do pod
kubectl logs <pod-name> -n lab

# Verificar se porta está correta
kubectl describe pod <pod-name> -n lab | grep -i port
```

### Service não roteia tráfego

```bash
# Verificar se service tem endpoints
kubectl get endpoints <service-name> -n lab

# Se vazio, labels não correspondem
kubectl get pods -n lab --show-labels
kubectl describe svc <service-name> -n lab

# Verificar selector do service vs labels dos pods
```

### Endpoints vazios

```bash
# Service não encontra pods
# Verificar:

# 1. Labels do pod
kubectl get pods -n lab --show-labels

# 2. Selector do service
kubectl get svc <service-name> -n lab -o yaml | grep -A5 selector

# 3. Corrigir labels ou selector
kubectl label pod <pod-name> app=nginx -n lab
```

---

## Resumo

### Para Debug e Desenvolvimento

```bash
# Debug de pod específico
kubectl port-forward pod/<name> 8080:80 -n lab

# Debug geral com load balancing
kubectl port-forward svc/<name> 8080:80 -n lab
```

### Para Aplicações

| Ambiente | Tipo Recomendado |
|----------|------------------|
| **Desenvolvimento local** | ClusterIP + port-forward |
| **Staging on-premise** | NodePort |
| **Produção cloud** | LoadBalancer |
| **Interno (microserviços)** | ClusterIP |

### Regra de Ouro

**Sempre use Services, nunca acesse pods diretamente!**

Services fornecem:
- IP estável
- Load balancing
- Descoberta via DNS
- Failover automático