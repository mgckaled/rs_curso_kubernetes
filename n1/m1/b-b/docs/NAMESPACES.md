# Entendendo Namespaces no Kubernetes

## Contexto

Namespaces são divisões lógicas do cluster Kubernetes que permitem organizar e isolar recursos. Este documento explica os namespaces padrão e como utilizá-los.

---

## O que são Namespaces?

Namespaces são como "pastas virtuais" ou "departamentos" dentro de um cluster Kubernetes:

- Permitem organizar recursos logicamente
- Isolam recursos entre equipes/projetos/ambientes
- Facilitam controle de acesso (RBAC)
- Permitem limpeza em massa (`kubectl delete namespace <name>`)

### Analogia

| Conceito | Analogia |
|----------|----------|
| **Cluster** | Datacenter físico ou prédio |
| **Namespace** | Departamento ou andar do prédio |
| **Pod/Service** | Recursos específicos dentro do departamento |

---

## Visualizando Namespaces

```bash
# Listar todos os namespaces
kubectl get namespaces

# Abreviação
kubectl get ns
```

### Exemplo de saída

```txt
NAME                 STATUS   AGE
default              Active   40m
kube-node-lease      Active   40m
kube-public          Active   40m
kube-system          Active   40m
local-path-storage   Active   39m
lab                  Active   3m
```

---

## Namespaces Padrão do Kubernetes

### 1. default

- **Função**: Namespace padrão para recursos sem especificação
- **Uso**: Recursos criados sem `-n <namespace>` vão para aqui
- **Quando usar**: Testes rápidos, ambiente local
- **Boa prática**: Evite em produção - sempre use namespaces específicos

```bash
# Criar um pod sem especificar namespace (vai para default)
kubectl run nginx --image=nginx
```

---

### 2. kube-system

- **Função**: Componentes principais do sistema Kubernetes
- **Conteúdo típico**:
  - Control plane: `etcd`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager`
  - Rede: `kube-proxy`, CNI plugins (kindnet, calico, etc.)
  - DNS: `coredns`
  - Addons do sistema
- **Importante**: ⚠️ NÃO crie recursos de aplicação aqui - é reservado para o Kubernetes

```bash
# Ver componentes do sistema
kubectl get pods -n kube-system
```

---

### 3. kube-public

- **Função**: Recursos públicos visíveis para todos os usuários
- **Visibilidade**: Acessível mesmo para usuários não autenticados
- **Uso típico**: ConfigMaps com informações de descoberta do cluster
- **Na prática**: Raramente usado em clusters normais

```bash
# Ver recursos públicos
kubectl get all -n kube-public
```

---

### 4. kube-node-lease

- **Função**: Armazena objetos "Lease" (contratos de tempo) dos nós
- **Responsabilidade**: Detecção rápida de falhas de nós
- **Mecânica**:
  - Cada nó atualiza seu lease periodicamente (heartbeat)
  - Control plane monitora essas atualizações
  - Se um nó para de atualizar, é marcado como `NotReady`
- **Uso prático**: Totalmente gerenciado - você não interage diretamente

```bash
# Ver leases dos nós
kubectl get leases -n kube-node-lease
```

---

### 5. local-path-storage (específico do Kind)

- **Função**: Provisionador de volumes locais do Kind
- **Uso**: StorageClass padrão para PersistentVolumes
- **Importante**: Este namespace é **específico do Kind** - não existe em todos os clusters
- **Conteúdo**: Pods que gerenciam provisionamento dinâmico de volumes locais

```bash
# Ver recursos de armazenamento
kubectl get pods -n local-path-storage
```

**Nota**: Em outros ambientes, você pode encontrar namespaces similares como `kube-storage` ou namespaces de provedores de armazenamento específicos.

---

## Criando Namespaces Personalizados

### Via manifest (recomendado)

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: meu-namespace
```

```bash
kubectl apply -f namespace.yaml
```

### Via comando imperativo

```bash
# Criar namespace diretamente
kubectl create namespace meu-namespace
```

---

## Trabalhando com Namespaces

### Especificar namespace em comandos

```bash
# Criar recurso em namespace específico
kubectl apply -f deployment.yaml -n meu-namespace

# Listar pods em namespace específico
kubectl get pods -n meu-namespace

# Ver detalhes de um recurso
kubectl describe pod meu-pod -n meu-namespace
```

### Ver recursos em todos os namespaces

```bash
# Listar pods de todos os namespaces
kubectl get pods --all-namespaces

# Abreviação
kubectl get pods -A

# Ver todos os tipos de recursos
kubectl get all -A
```

### Definir namespace padrão

```bash
# Definir namespace padrão para o contexto atual
# (evita repetir -n em todos os comandos)
kubectl config set-context --current --namespace=meu-namespace

# Verificar contexto atual
kubectl config get-contexts

# Voltar para default
kubectl config set-context --current --namespace=default
```

---

## Isolamento e Limites

### O que namespaces isolam

✅ **Isolam:**

- Nomes de recursos (pode ter `pod-nginx` em múltiplos namespaces)
- Políticas de RBAC (controle de acesso)
- Network Policies (se configuradas)
- Resource Quotas (limites de CPU/memória)

❌ **NÃO isolam:**

- Rede por padrão (pods se comunicam entre namespaces)
- Nós do cluster
- Volumes persistentes (são cluster-wide)
- Custom Resource Definitions (CRDs)

### Aplicar limites de recursos

```yaml
# resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: meu-namespace
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

---

## Deletando Namespaces

### Deletar namespace (e TODOS os recursos dentro)

```bash
# CUIDADO: Deleta TUDO dentro do namespace!
kubectl delete namespace meu-namespace
```

⚠️ **Atenção**: Esta operação:

- Deleta TODOS os recursos (pods, services, deployments, etc.)
- É irreversível
- Pode demorar alguns segundos/minutos para finalizar

### Deletar apenas recursos específicos

```bash
# Deletar apenas deployments
kubectl delete deployments --all -n meu-namespace

# Deletar apenas pods
kubectl delete pods --all -n meu-namespace
```

---

## Boas Práticas

### ✅ Faça

1. **Use namespaces para organização**
   - Ambientes: `dev`, `staging`, `production`
   - Equipes: `team-frontend`, `team-backend`
   - Projetos: `project-a`, `project-b`

2. **Sempre especifique namespace em manifestos**

   ```yaml
   metadata:
     name: meu-app
     namespace: producao  # Sempre explícito!
   ```

3. **Use Resource Quotas**
   - Evita que um namespace consuma todos os recursos
   - Define limites claros por equipe/projeto

4. **Nomeie de forma consistente**
   - Use padrão: `<ambiente>-<projeto>`
   - Exemplo: `prod-api`, `dev-api`

### ❌ Não faça

1. **Não use `kube-system` para aplicações**
   - Reservado para componentes do Kubernetes
   - Misturar pode causar problemas de segurança/estabilidade

2. **Não use apenas `default` em produção**
   - Dificulta organização e controle de acesso
   - Não permite isolamento adequado

3. **Não ignore namespaces achando que são opcionais**
   - São fundamentais para clusters multi-tenant
   - Facilitam muito a gestão em escala

4. **Não delete namespaces sem verificar**
   - Sempre confira o conteúdo antes: `kubectl get all -n <namespace>`
   - Faça backup se necessário

---

## Comandos Úteis de Referência

```bash
# Listar namespaces
kubectl get namespaces
kubectl get ns

# Criar namespace
kubectl create namespace <name>

# Deletar namespace
kubectl delete namespace <name>

# Ver detalhes de um namespace
kubectl describe namespace <name>

# Ver recursos em namespace específico
kubectl get all -n <name>

# Ver recursos em todos os namespaces
kubectl get all --all-namespaces
kubectl get all -A

# Definir namespace padrão do contexto
kubectl config set-context --current --namespace=<name>

# Ver contexto atual (inclui namespace padrão)
kubectl config get-contexts

# Ver yaml completo de um namespace
kubectl get namespace <name> -o yaml
```

---

## Exemplo Prático: Organização por Ambiente

```bash
# Criar namespaces para diferentes ambientes
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# Deploy da mesma aplicação em ambientes diferentes
kubectl apply -f app.yaml -n dev
kubectl apply -f app.yaml -n staging
kubectl apply -f app.yaml -n production

# Ver status em cada ambiente
kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n production
```

---

## Namespaces e DNS Interno

Pods podem se comunicar entre namespaces usando DNS:

### Formato do DNS

```txt
<service-name>.<namespace>.svc.cluster.local
```

### Exemplo

```bash
# Service "api" no namespace "backend"
# Pode ser acessado de outros namespaces via:
api.backend.svc.cluster.local

# Dentro do mesmo namespace, pode usar apenas:
api
```

### Teste de conectividade

```bash
# De um pod no namespace "frontend", acessar service no namespace "backend"
kubectl exec -it meu-pod -n frontend -- curl http://api.backend.svc.cluster.local
```

---

## Visualização Hierárquica

```plaintext
Cluster k8s-lab
├── Namespace: default
│   ├── Pod: app-1
│   └── Service: app-1-svc
│
├── Namespace: kube-system
│   ├── Pod: coredns-xxx
│   ├── Pod: etcd-xxx
│   └── ...
│
├── Namespace: dev
│   ├── Deployment: api
│   ├── Service: api-svc
│   └── ConfigMap: api-config
│
└── Namespace: production
    ├── Deployment: api
    ├── Service: api-svc
    └── ConfigMap: api-config
```

Cada namespace é completamente independente em termos de nomenclatura de recursos!

---

## Namespaces vs Outros Conceitos

| Conceito | Isolamento | Escopo |
|----------|------------|--------|
| **Cluster** | Físico/Infraestrutura | Máximo - instância completa do K8s |
| **Namespace** | Lógico | Médio - organização dentro do cluster |
| **Labels** | Nenhum | Mínimo - apenas tag/filtro de recursos |
| **Node** | Físico | Máximo - máquina/VM individual |

---

## Troubleshooting

### Namespace preso em "Terminating"

Às vezes um namespace fica preso deletando:

```bash
# Ver status
kubectl get namespace <name>

# Ver o que está impedindo
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n <name>

# Forçar limpeza (use com cuidado!)
kubectl delete namespace <name> --grace-period=0 --force
```

### Verificar quotas e limites

```bash
# Ver quotas aplicadas
kubectl get resourcequota -n <name>

# Ver detalhes das quotas
kubectl describe resourcequota -n <name>
```
