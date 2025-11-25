# Bloco B - Orquestrando Containers

## Objetivos

- Criar e gerenciar Pods
- Entender Namespaces para organização
- Implementar ReplicaSets para redundância
- Usar Deployments para versionamento
- Expor aplicações com Services

---

## Documentação Complementar

Este bloco contém documentos de referência na pasta `docs/`:

- **[NAMESPACES.md](docs/NAMESPACES.md)**: Guia completo sobre namespaces no Kubernetes. Explica os namespaces padrão (default, kube-system, kube-public, kube-node-lease), como criar e gerenciar, isolamento de recursos, boas práticas e troubleshooting.

- **[REPLICASET.md](docs/REPLICASET.md)**: Documentação detalhada sobre ReplicaSets. Aborda self-healing, escalabilidade, alta disponibilidade, limitações de atualização de versão e por que usar Deployments em produção.

- **[ACESSO-PODS-SERVICES.md](docs/ACESSO-PODS-SERVICES.md)**: Guia completo sobre formas de acessar pods e services. Cobre port-forward, tipos de Services (ClusterIP, NodePort, LoadBalancer), load balancing, DNS interno e quando usar cada abordagem.

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
# Linux/Mac:
kubectl describe pod <nome-do-pod> -n lab | grep Image

# PowerShell:
kubectl describe pod <nome-do-pod> -n lab | Select-String "Image"

# Ou verificar diretamente (funciona em qualquer terminal):
kubectl get pods -n lab -o jsonpath='{.items[*].spec.containers[*].image}'
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
# Linux/Mac:
kubectl describe pod <nome-do-pod> -n lab | grep Image

# PowerShell:
kubectl describe pod <nome-do-pod> -n lab | Select-String "Image"

# Ou verificar todas as imagens diretamente (funciona em qualquer terminal):
kubectl get pods -n lab -o jsonpath='{.items[*].spec.containers[*].image}'

# Ver formatado com nome do pod e imagem:
kubectl get pods -n lab -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[*].image
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
# Linux/Mac:
curl http://localhost:8080

# PowerShell:
Invoke-WebRequest http://localhost:8080

# Ou abra no navegador:
# http://localhost:8080
```

### Ver Endpoints

```bash
# Endpoints são os IPs dos pods selecionados
kubectl get endpoints nginx-service -n lab
```

---

## Explorando o Ambiente

Após concluir todas as práticas, use estes comandos para explorar o estado atual do namespace:

### Visão Geral Completa

```bash
# Ver todos os recursos criados no namespace lab
kubectl get all -n lab

# Saída esperada:
# - 3 pods (deployment)
# - 1 service
# - 1 deployment
# - 2 replicasets (atual + histórico)
```

### Detalhes do Service

```bash
# Ver detalhes completos do Service
kubectl describe svc nginx-service -n lab

# Informações mostradas:
# - Tipo: ClusterIP
# - IP interno do cluster
# - Porta e TargetPort
# - Selector (labels)
# - Endpoints (IPs dos pods)
```

### Endpoints e Load Balancing

```bash
# Ver endpoints (IPs dos pods que o Service roteia)
kubectl get endpoints nginx-service -n lab

# Mostrar IPs detalhados dos pods
kubectl get pods -n lab -o wide

# Ver mapeamento completo: nome do pod → IP → imagem
kubectl get pods -n lab -o custom-columns=NAME:.metadata.name,IP:.status.podIP,IMAGE:.spec.containers[*].image
```

### Logs e Monitoramento

```bash
# Ver logs de todos os pods do deployment (últimas 20 linhas)
kubectl logs -l app=nginx -n lab --tail=20

# Ver logs de um pod específico
kubectl logs <nome-do-pod> -n lab

# Seguir logs em tempo real
kubectl logs -l app=nginx -n lab -f

# Ver eventos do namespace
kubectl get events -n lab --sort-by='.lastTimestamp'
```

### Histórico e Versões

```bash
# Ver histórico de rollouts do deployment
kubectl rollout history deployment/nginx-deployment -n lab

# Ver detalhes de uma revisão específica
kubectl rollout history deployment/nginx-deployment -n lab --revision=2

# Ver ReplicaSets e suas versões
kubectl get rs -n lab -o wide
```

### Relacionamento entre Recursos

```bash
# Ver hierarquia: Deployment → ReplicaSet → Pods
kubectl get deployment,rs,pods -n lab

# Ver labels de todos os pods
kubectl get pods -n lab --show-labels

# Ver quais pods o Service está selecionando
kubectl get pods -n lab -l app=nginx

# Comparar selector do Service com labels dos pods
kubectl describe svc nginx-service -n lab | grep -A3 "Selector"
kubectl get pods -n lab --show-labels
```

### Testes de Resiliência

```bash
# Deletar um pod e observar recriação automática
kubectl delete pod <nome-de-um-pod> -n lab

# Imediatamente verificar status
kubectl get pods -n lab --watch

# Verificar que o Service ainda funciona
kubectl port-forward svc/nginx-service 8080:80 -n lab
# Acessar: http://localhost:8080
```

### Informações de Recursos

```bash
# Ver recursos (CPU/memória) dos pods
kubectl top pods -n lab

# Ver detalhes de configuração de um pod
kubectl get pod <nome-do-pod> -n lab -o yaml

# Ver apenas a seção de containers
kubectl get pod <nome-do-pod> -n lab -o jsonpath='{.spec.containers[*]}'
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

- [x] Namespace `lab` criado
- [x] Pod criado e acessível via port-forward
- [x] Pod deletado não é recriado (efemeridade)
- [x] ReplicaSet mantém 3 réplicas
- [x] ReplicaSet não atualiza pods existentes (limitação)
- [x] Deployment criado com sucesso
- [x] Rolling update executado
- [x] Service expondo os pods
- [x] Acesso via Service funciona
