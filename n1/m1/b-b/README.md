# Bloco B - Orquestrando Containers

## Objetivos

- Criar e gerenciar Pods
- Entender Namespaces para organização
- Implementar ReplicaSets para redundância
- Usar Deployments para versionamento
- Expor aplicações com Services

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-namespace.yaml   # Namespace para isolar recursos
├── 02-pod.yaml         # Pod individual (demonstra efemeridade)
├── 03-replicaset.yaml  # ReplicaSet (demonstra limitações)
├── 04-deployment.yaml  # Deployment (solução recomendada)
└── 05-service.yaml     # Service (expõe a aplicação)
```

---

## Hierarquia de Objetos

```txt
Deployment
    │
    ├── gerencia ──► ReplicaSet (v1)
    │                    │
    │                    └── gerencia ──► Pod 1, Pod 2, Pod 3
    │
    └── gerencia ──► ReplicaSet (v2) [após update]
                         │
                         └── gerencia ──► Pod 1, Pod 2, Pod 3

Service
    │
    └── roteia tráfego para ──► Pods (via selector/labels)
```

---

## Prática 1: Namespace

### Criar o Namespace

```bash
# Aplicar o manifest
kubectl apply -f manifests/01-namespace.yaml

# Verificar namespaces existentes
kubectl get namespaces

# Abreviação
kubectl get ns
```

### O que são Namespaces?

- Divisão lógica do cluster
- Permite isolamento de recursos
- Padrões: `default`, `kube-system`, `kube-public`, `kube-node-lease`

---

## Prática 2: Pod

### Criar o Pod

```bash
# Aplicar o manifest
kubectl apply -f manifests/02-pod.yaml

# Listar pods no namespace lab
kubectl get pods -n lab

# Ver detalhes do pod
kubectl describe pod nginx-pod -n lab
```

### Acessar o Pod

```bash
# Port-forward: mapeia porta local para o container
# Formato: kubectl port-forward <recurso> <local>:<container>
kubectl port-forward pod/nginx-pod 8080:80 -n lab

# Em outro terminal, testar acesso
curl http://localhost:8080
```

### Ver Logs

```bash
# Logs do container
kubectl logs nginx-pod -n lab

# Logs em tempo real (follow)
kubectl logs nginx-pod -n lab -f
```

### Demonstrar Efemeridade

```bash
# Deletar o pod
kubectl delete pod nginx-pod -n lab

# Verificar: pod NÃO é recriado automaticamente!
kubectl get pods -n lab
```

> **Aprendizado:** Pods são efêmeros. Sem um controlador, não são recriados.

---

## Prática 3: ReplicaSet

### Criar o ReplicaSet

```bash
# Aplicar o manifest
kubectl apply -f manifests/03-replicaset.yaml

# Listar ReplicaSets
kubectl get replicaset -n lab
# Abreviação
kubectl get rs -n lab

# Ver os 3 pods criados
kubectl get pods -n lab
```

### Testar Resiliência

```bash
# Copiar o nome de um pod
kubectl get pods -n lab

# Deletar um pod
kubectl delete pod <nome-do-pod> -n lab

# Verificar: ReplicaSet recria automaticamente!
kubectl get pods -n lab
```

### Demonstrar Limitação do ReplicaSet

```bash
# Edite o arquivo 03-replicaset.yaml
# Altere a imagem de nginx:1.27.5 para nginx:1.28.0
# Aplique novamente
kubectl apply -f manifests/03-replicaset.yaml

# Verifique os pods: ainda estão com a versão antiga!
kubectl describe pod <nome-do-pod> -n lab | grep Image
```

> **Aprendizado:** ReplicaSet não atualiza pods existentes. Para atualizações, use Deployment.

### Limpar ReplicaSet

```bash
# Remover antes de criar o Deployment
kubectl delete replicaset nginx-replicaset -n lab
```

---

## Prática 4: Deployment

### Criar o Deployment

```bash
# Aplicar o manifest
kubectl apply -f manifests/04-deployment.yaml

# Listar Deployments
kubectl get deployments -n lab
# Abreviação
kubectl get deploy -n lab

# Ver ReplicaSet criado automaticamente
kubectl get rs -n lab

# Ver pods
kubectl get pods -n lab
```

### Rolling Update

```bash
# Edite o arquivo 04-deployment.yaml
# Altere a imagem de nginx:1.27.5 para nginx:1.28.0
# Aplique novamente
kubectl apply -f manifests/04-deployment.yaml

# Acompanhar o rollout
kubectl rollout status deployment/nginx-deployment -n lab

# Ver histórico de revisões
kubectl rollout history deployment/nginx-deployment -n lab

# Verificar: todos os pods têm a nova versão!
kubectl describe pod <nome-do-pod> -n lab | grep Image
```

### Rollback (se necessário)

```bash
# Voltar para a versão anterior
kubectl rollout undo deployment/nginx-deployment -n lab

# Verificar status
kubectl rollout status deployment/nginx-deployment -n lab
```

---

## Prática 5: Service

### Criar o Service

```bash
# Aplicar o manifest
kubectl apply -f manifests/05-service.yaml

# Listar Services
kubectl get services -n lab
# Abreviação
kubectl get svc -n lab
```

### Acessar via Service

```bash
# Port-forward no Service (balanceia entre pods)
kubectl port-forward svc/nginx-service 8080:80 -n lab

# Testar acesso
curl http://localhost:8080
```

### Ver Endpoints

```bash
# Endpoints são os IPs dos pods selecionados
kubectl get endpoints nginx-service -n lab
```

---

## Resumo de Comandos

### Recursos

| Comando | Descrição |
|---------|-----------|
| `kubectl apply -f <file>` | Criar/atualizar recurso |
| `kubectl delete -f <file>` | Deletar recurso |
| `kubectl get <resource> -n <ns>` | Listar recursos |
| `kubectl describe <resource> <name> -n <ns>` | Detalhes |

### Abreviações

| Recurso | Abreviação |
|---------|------------|
| namespaces | ns |
| pods | po |
| replicasets | rs |
| deployments | deploy |
| services | svc |

### Pods

| Comando | Descrição |
|---------|-----------|
| `kubectl logs <pod> -n <ns>` | Ver logs |
| `kubectl logs <pod> -n <ns> -f` | Logs em tempo real |
| `kubectl exec -it <pod> -n <ns> -- /bin/sh` | Shell no container |
| `kubectl port-forward <pod> <local>:<container> -n <ns>` | Encaminhar porta |

### Deployments

| Comando | Descrição |
|---------|-----------|
| `kubectl rollout status deploy/<name> -n <ns>` | Status do rollout |
| `kubectl rollout history deploy/<name> -n <ns>` | Histórico |
| `kubectl rollout undo deploy/<name> -n <ns>` | Rollback |

---

## Checklist

- [ ] Namespace `lab` criado
- [ ] Pod criado e acessível via port-forward
- [ ] Pod deletado não é recriado (efemeridade)
- [ ] ReplicaSet mantém 3 réplicas
- [ ] ReplicaSet não atualiza pods existentes (limitação)
- [ ] Deployment criado com sucesso
- [ ] Rolling update executado
- [ ] Service expondo os pods
- [ ] Acesso via Service funciona
