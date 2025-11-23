# Bloco A - Explorando Deployment e Cenários em uma Aplicação Real

## Objetivos

- Containerizar e fazer deploy de uma aplicação NestJS
- Configurar Deployment com estratégias de atualização
- Criar Service para expor a aplicação
- Utilizar ConfigMap para variáveis não sensíveis
- Utilizar Secret para variáveis sensíveis
- Praticar rollback e versionamento

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-namespace.yaml       # Namespace para isolar recursos
├── 02-configmap.yaml       # Variáveis não sensíveis
├── 03-secret.yaml          # Variáveis sensíveis (base64)
├── 04-deployment.yaml      # Deployment com estratégia RollingUpdate
├── 05-deployment-recreate.yaml  # Deployment com estratégia Recreate
└── 06-service.yaml         # Service ClusterIP
```

---

## Pré-requisitos

### 1. Build da Imagem Docker

```bash
# Navegar até o diretório da demo-api
cd apps/demo-api

# Build da imagem
docker build -t demo-api:v1 .

# Verificar imagem criada
docker images | grep demo-api
```

### 2. Carregar Imagem no Kind (ambiente local)

```bash
# Carregar imagem no cluster Kind
kind load docker-image demo-api:v1 --name k8s-lab
```

---

## Prática 1: Namespace

```bash
kubectl apply -f manifests/01-namespace.yaml
kubectl get ns
```

---

## Prática 2: ConfigMap

```bash
# Criar ConfigMap
kubectl apply -f manifests/02-configmap.yaml

# Verificar ConfigMap criado
kubectl get configmap -n demo

# Ver detalhes
kubectl describe configmap demo-api-config -n demo
```

---

## Prática 3: Secret

```bash
# Criar Secret
kubectl apply -f manifests/03-secret.yaml

# Verificar Secret criado
kubectl get secret -n demo

# Ver detalhes (valores em base64)
kubectl describe secret demo-api-secret -n demo

# Decodificar um valor
kubectl get secret demo-api-secret -n demo -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

---

## Prática 4: Deployment (RollingUpdate)

```bash
# Criar Deployment
kubectl apply -f manifests/04-deployment.yaml

# Verificar Deployment
kubectl get deployment -n demo

# Ver pods criados
kubectl get pods -n demo

# Ver detalhes do Deployment
kubectl describe deployment demo-api -n demo

# Testar acesso via port-forward
kubectl port-forward deployment/demo-api 3000:3000 -n demo

# Em outro terminal, testar endpoints
curl http://localhost:3000/
curl http://localhost:3000/env
```

---

## Prática 5: Service

```bash
# Criar Service
kubectl apply -f manifests/06-service.yaml

# Verificar Service
kubectl get svc -n demo

# Acessar via Service
kubectl port-forward svc/demo-api-service 3000:80 -n demo

# Testar
curl http://localhost:3000/
```

---

## Prática 6: Rolling Update

```bash
# Simular nova versão (alterar tag no deployment)
# Edite 04-deployment.yaml: image: demo-api:v2

# Aplicar atualização
kubectl apply -f manifests/04-deployment.yaml

# Acompanhar rollout
kubectl rollout status deployment/demo-api -n demo

# Ver histórico
kubectl rollout history deployment/demo-api -n demo

# Rollback para versão anterior
kubectl rollout undo deployment/demo-api -n demo

# Rollback para revisão específica
kubectl rollout undo deployment/demo-api -n demo --to-revision=1
```

---

## Prática 7: Estratégia Recreate

```bash
# Aplicar deployment com estratégia Recreate
kubectl apply -f manifests/05-deployment-recreate.yaml

# Observar comportamento (todos os pods são terminados antes de criar novos)
kubectl get pods -n demo -w
```

> **Atenção:** Recreate causa indisponibilidade! Use apenas em ambientes de desenvolvimento ou quando necessário.

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `kubectl rollout status deploy/<name>` | Status do rollout |
| `kubectl rollout history deploy/<name>` | Histórico de revisões |
| `kubectl rollout undo deploy/<name>` | Rollback |
| `kubectl rollout restart deploy/<name>` | Reiniciar pods |
| `kubectl set image deploy/<name> <container>=<image>` | Atualizar imagem |

---

## Checklist

- [ ] Namespace `demo` criado
- [ ] ConfigMap criado e verificado
- [ ] Secret criado e verificado
- [ ] Deployment rodando com 3 réplicas
- [ ] Service expondo a aplicação
- [ ] Endpoint `/env` mostrando variáveis do ConfigMap/Secret
- [ ] Rolling update executado com sucesso
- [ ] Rollback testado
- [ ] Estratégia Recreate testada
