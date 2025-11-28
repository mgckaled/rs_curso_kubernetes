# Bloco B - Conhecendo o RBAC (Role-Based Access Control)

## Objetivos

- Entender RBAC (Role-Based Access Control) no Kubernetes
- Diferenciar Roles e ClusterRoles
- Criar RoleBindings e ClusterRoleBindings
- Implementar ServiceAccounts para pods
- Aplicar principio de privilegio minimo
- Testar permissoes com kubectl auth can-i
- Simular cenarios de acesso multi-usuario

---

## Contexto

Este bloco aborda **RBAC** (Role-Based Access Control), o sistema de controle de acesso do Kubernetes que define **quem pode fazer o que** no cluster.

### O que e RBAC?

RBAC e um modelo de seguranca que restringe acesso a recursos baseado nas **funcoes** (roles) dos usuarios ou processos. No Kubernetes:

- **Subjects** (quem): Users, Groups, ServiceAccounts
- **Resources** (o que): Pods, Services, Deployments, etc
- **Verbs** (fazer): get, list, create, update, delete, watch

### Por que RBAC e importante?

| Problema sem RBAC | Solucao com RBAC |
|-------------------|------------------|
| Todos tem acesso total (cluster-admin) | Permissoes granulares por necessidade |
| Dificil rastrear quem fez o que | Auditoria clara de acoes |
| Apps tem permissoes excessivas | ServiceAccounts com privilegio minimo |
| Riscos de seguranca elevados | Defesa em profundidade (defense in depth) |

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-namespaces.yaml                 # Namespaces dev e prod
├── 02-serviceaccount-app-reader.yaml  # SA para aplicacao read-only
├── 03-role-pod-reader.yaml            # Role para ler pods
├── 04-rolebinding-app-reader.yaml     # Liga Role ao ServiceAccount
├── 05-clusterrole-node-reader.yaml    # ClusterRole para ler nodes
├── 06-clusterrolebinding-viewer.yaml  # Liga ClusterRole a grupo
├── 07-deployment-with-sa.yaml         # App usando ServiceAccount
├── 08-role-pod-manager.yaml           # Role para gerenciar pods
├── 09-rolebinding-dev-admin.yaml      # Admin do namespace dev
└── 10-test-pod.yaml                   # Pod para testar permissoes
```

---

## Pre-requisitos

### 1. Cluster Kind do Bloco A

```bash
# Se nao criou ainda, criar cluster
kind create cluster --config ../b-a/manifests/00-kind-cluster.yaml --name cloud-sim

# Verificar cluster
kubectl cluster-info
kubectl get nodes
```

### 2. Demo-api image carregada

```bash
# Se necessario, buildar e carregar
cd apps/demo-api
docker build -t demo-api:v1 .
kind load docker-image demo-api:v1 --name cloud-sim
cd ../../..
```

---

## Conceitos Fundamentais

### Recursos RBAC

| Recurso | Escopo | Descricao |
|---------|--------|-----------|
| **Role** | Namespace | Define permissoes em um namespace |
| **ClusterRole** | Cluster | Define permissoes no cluster todo |
| **RoleBinding** | Namespace | Liga Role/ClusterRole a subjects em um namespace |
| **ClusterRoleBinding** | Cluster | Liga ClusterRole a subjects no cluster todo |
| **ServiceAccount** | Namespace | Identidade para processos em pods |

### Verbs (Verbos) Comuns

| Verb | Descricao | Exemplo |
|------|-----------|---------|
| `get` | Ler um recurso especifico | `kubectl get pod my-pod` |
| `list` | Listar recursos | `kubectl get pods` |
| `watch` | Monitorar mudancas | `kubectl get pods -w` |
| `create` | Criar recurso | `kubectl create deployment` |
| `update` | Atualizar recurso | `kubectl apply -f` |
| `patch` | Modificar parcialmente | `kubectl patch` |
| `delete` | Deletar recurso | `kubectl delete pod` |

### Subjects (Sujeitos)

| Subject | Descricao | Exemplo |
|---------|-----------|---------|
| **User** | Usuario humano | `user: alice` |
| **Group** | Grupo de usuarios | `group: developers` |
| **ServiceAccount** | Identidade de processo | `serviceaccount: app-reader` |

---

## Parte 1: Namespaces e ServiceAccounts

### Passo 1: Criar namespaces dev e prod

```bash
# Aplicar namespaces
kubectl apply -f n2/m1/b-b/manifests/01-namespaces.yaml

# Verificar
kubectl get namespaces
```

### Passo 2: Criar ServiceAccount

```bash
# Criar ServiceAccount app-reader
kubectl apply -f n2/m1/b-b/manifests/02-serviceaccount-app-reader.yaml

# Verificar
kubectl get serviceaccounts -n dev
kubectl describe sa app-reader -n dev
```

---

## Parte 2: Roles e RoleBindings

### Passo 1: Criar Role para ler pods

```bash
# Aplicar Role pod-reader
kubectl apply -f n2/m1/b-b/manifests/03-role-pod-reader.yaml

# Verificar Role
kubectl get role pod-reader -n dev
kubectl describe role pod-reader -n dev
```

### Passo 2: Criar RoleBinding

```bash
# Ligar Role ao ServiceAccount
kubectl apply -f n2/m1/b-b/manifests/04-rolebinding-app-reader.yaml

# Verificar RoleBinding
kubectl get rolebinding app-reader-binding -n dev
kubectl describe rolebinding app-reader-binding -n dev
```

### Passo 3: Testar permissoes do ServiceAccount

```bash
# Testar se ServiceAccount pode listar pods
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev:app-reader \
  --namespace=dev

# Resultado: yes

# Testar se pode criar pods
kubectl auth can-i create pods \
  --as=system:serviceaccount:dev:app-reader \
  --namespace=dev

# Resultado: no

# Testar em outro namespace
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev:app-reader \
  --namespace=prod

# Resultado: no (Role e RoleBinding sao namespace-scoped)
```

---

## Parte 3: ClusterRoles e ClusterRoleBindings

### Passo 1: Criar ClusterRole para ler nodes

```bash
# Aplicar ClusterRole
kubectl apply -f n2/m1/b-b/manifests/05-clusterrole-node-reader.yaml

# Verificar
kubectl get clusterrole node-reader
kubectl describe clusterrole node-reader
```

### Passo 2: Criar ClusterRoleBinding

```bash
# Aplicar ClusterRoleBinding
kubectl apply -f n2/m1/b-b/manifests/06-clusterrolebinding-viewer.yaml

# Verificar
kubectl get clusterrolebinding viewer-binding
kubectl describe clusterrolebinding viewer-binding
```

### Passo 3: Testar permissoes do grupo

```bash
# Simular usuario do grupo viewers
kubectl auth can-i list nodes --as=viewer-user --as-group=viewers

# Resultado: yes

# Testar permissoes em recursos namespacados
kubectl auth can-i list pods --as=viewer-user --as-group=viewers -n dev

# Resultado: no (ClusterRole e sobre nodes, nao pods)
```

---

## Parte 4: Aplicacao com ServiceAccount

### Passo 1: Deploy da demo-api com ServiceAccount

```bash
# Aplicar deployment usando app-reader ServiceAccount
kubectl apply -f n2/m1/b-b/manifests/07-deployment-with-sa.yaml

# Verificar pods
kubectl get pods -n dev

# Ver ServiceAccount do pod
kubectl get pod -n dev -l app=demo-api-rbac -o jsonpath='{.items[0].spec.serviceAccountName}'
```

### Passo 2: Testar permissoes de dentro do pod

```bash
# Entrar no pod
kubectl exec -it -n dev $(kubectl get pod -n dev -l app=demo-api-rbac -o jsonpath='{.items[0].metadata.name}') -- sh

# Dentro do pod, instalar kubectl (se necessario)
# apk add --no-cache curl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl && mv kubectl /usr/local/bin/

# Testar permissoes
kubectl auth can-i list pods

# Resultado: yes (ServiceAccount app-reader pode list pods)

# Tentar criar pod
kubectl auth can-i create pods

# Resultado: no
```

---

## Parte 5: Cenarios Avancados

### Cenario 1: Admin de Namespace

```bash
# Criar Role para gerenciar pods
kubectl apply -f n2/m1/b-b/manifests/08-role-pod-manager.yaml

# Criar RoleBinding para admin
kubectl apply -f n2/m1/b-b/manifests/09-rolebinding-dev-admin.yaml

# Testar permissoes do admin
kubectl auth can-i create pods --as=dev-admin --namespace=dev
kubectl auth can-i delete pods --as=dev-admin --namespace=dev
kubectl auth can-i create secrets --as=dev-admin --namespace=dev

# Resultado: yes, yes, no (nao tem permissao para secrets)
```

### Cenario 2: Usando ClusterRole com RoleBinding

```bash
# ClusterRoles pre-definidas do Kubernetes:
# - view: leitura de recursos comuns
# - edit: modificar recursos (exceto RBAC)
# - admin: controle total no namespace

# Criar RoleBinding usando ClusterRole view
kubectl create rolebinding viewer \
  --clusterrole=view \
  --user=alice \
  --namespace=dev

# Testar
kubectl auth can-i list pods --as=alice --namespace=dev
kubectl auth can-i list services --as=alice --namespace=dev
kubectl auth can-i create pods --as=alice --namespace=dev

# Resultado: yes, yes, no
```

### Cenario 3: Restringir acesso a recursos especificos

```bash
# Role que permite acesso apenas a um ConfigMap especifico
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["app-config"]  # Apenas este ConfigMap
    verbs: ["get", "list"]
EOF

# Criar RoleBinding
kubectl create rolebinding config-reader-binding \
  --role=config-reader \
  --user=config-user \
  --namespace=dev

# Testar
kubectl auth can-i get configmap/app-config --as=config-user -n dev
kubectl auth can-i get configmap/other-config --as=config-user -n dev

# Resultado: yes, no
```

---

## Pratica Guiada: Testando Permissoes

### Passo 1: Listar todas as permissoes de um usuario

```bash
# Ver todas as acoes permitidas
kubectl auth can-i --list --as=dev-admin --namespace=dev
```

### Passo 2: Criar pod de teste

```bash
# Aplicar pod de teste
kubectl apply -f n2/m1/b-b/manifests/10-test-pod.yaml

# Entrar no pod
kubectl exec -it test-rbac -n dev -- sh

# Dentro do pod, testar permissoes
# Este pod usa ServiceAccount default (sem permissoes customizadas)
kubectl auth can-i list pods
```

### Passo 3: Verificar permissoes de ServiceAccounts

```bash
# Ver todos ServiceAccounts no namespace
kubectl get serviceaccounts -n dev

# Ver detalhes de um SA
kubectl describe sa app-reader -n dev

# Ver Secrets associados (token de autenticacao)
kubectl get secret -n dev | grep app-reader
```

---

## Comandos Uteis

| Comando | Descricao |
|---------|-----------|
| `kubectl auth can-i <verb> <resource>` | Testar permissao do usuario atual |
| `kubectl auth can-i --list` | Listar todas permissoes do usuario |
| `kubectl auth can-i list pods --as=user` | Testar como outro usuario |
| `kubectl auth can-i create pods --as=system:serviceaccount:dev:app-reader -n dev` | Testar como ServiceAccount |
| `kubectl get roles -A` | Listar todas Roles |
| `kubectl get clusterroles` | Listar todas ClusterRoles |
| `kubectl get rolebindings -A` | Listar todos RoleBindings |
| `kubectl describe role <name>` | Ver detalhes de Role |
| `kubectl create role <name> --verb=get --resource=pods` | Criar Role via CLI |

---

## Melhores Praticas de RBAC

### 1. Principio de Privilegio Minimo

Conceda apenas as permissoes estritamente necessarias.

```yaml
# BOM: permissoes especificas
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["app-config"]
    verbs: ["get", "list"]

# RUIM: wildcards excessivos
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

### 2. Use ServiceAccounts Dedicados

Nao use o ServiceAccount `default` para aplicacoes.

```yaml
# BOM: ServiceAccount dedicado
spec:
  serviceAccountName: app-reader

# RUIM: usa default (todos os pods compartilham)
spec:
  # serviceAccountName omitido
```

### 3. Prefira Roles a ClusterRoles

Use Roles sempre que possivel para limitar escopo.

```yaml
# BOM: Role com escopo de namespace
kind: Role

# Use ClusterRole apenas para:
# - Recursos cluster-scoped (nodes, pv)
# - Endpoints non-resource (/healthz)
# - Acesso a todos namespaces
```

### 4. Evite ClusterRoleBindings Amplos

Nunca vincule `cluster-admin` a grupos amplos.

```yaml
# PERIGOSO: da acesso total a todos usuarios autenticados
subjects:
  - kind: Group
    name: system:authenticated
```

### 5. Use resourceNames para Restringir Acesso

Limite acesso a recursos especificos quando possivel.

```yaml
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["db-password"]  # Apenas este Secret
    verbs: ["get"]
```

---

## Troubleshooting

### Problema: "User cannot list pods"

```bash
# Verificar permissoes
kubectl auth can-i list pods --as=user -n namespace

# Ver Roles/RoleBindings do namespace
kubectl get role,rolebinding -n namespace

# Verificar ClusterRoles/ClusterRoleBindings
kubectl get clusterrole,clusterrolebinding | grep user
```

### Problema: ServiceAccount nao tem permissoes

```bash
# Verificar RoleBindings do ServiceAccount
kubectl get rolebinding -n namespace -o yaml | grep -A 5 "serviceaccount:namespace:sa-name"

# Testar permissoes
kubectl auth can-i list pods --as=system:serviceaccount:namespace:sa-name -n namespace
```

### Problema: "Forbidden: User cannot create resource"

```bash
# Verificar verbs na Role
kubectl describe role role-name -n namespace

# Adicionar verb necessario
kubectl edit role role-name -n namespace
```

---

## Limpeza

```bash
# Deletar todos recursos RBAC criados
kubectl delete -f n2/m1/b-b/manifests/

# Verificar
kubectl get role,rolebinding,clusterrole,clusterrolebinding,serviceaccount -A | grep -E "pod-reader|app-reader|node-reader"
```

---

## Checklist

- [ ] Namespaces dev e prod criados
- [ ] ServiceAccount app-reader criado
- [ ] Role pod-reader criada
- [ ] RoleBinding app-reader-binding criado
- [ ] ClusterRole node-reader criada
- [ ] ClusterRoleBinding viewer-binding criado
- [ ] Deployment com ServiceAccount funcionando
- [ ] Testes com kubectl auth can-i executados
- [ ] Compreensao de Roles vs ClusterRoles
- [ ] Compreensao de RoleBinding vs ClusterRoleBinding
- [ ] Principio de privilegio minimo aplicado

---

## Proximos Passos

No proximo modulo (N2-M2), vamos explorar **StatefulSet e DaemonSet** para gerenciar aplicacoes stateful e agentes de sistema no cluster.
