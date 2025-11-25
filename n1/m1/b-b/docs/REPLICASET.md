# Entendendo ReplicaSets no Kubernetes

## Contexto

ReplicaSet é um controlador do Kubernetes que garante que um número específico de réplicas de pods esteja sempre em execução. Este documento explica sua importância, funcionamento e limitações.

---

## O Problema que ReplicaSet Resolve

### Cenário: Pod Individual

Quando você cria um pod diretamente:

```bash
kubectl apply -f pod.yaml
```

**Problemas:**

- ❌ Se o pod crashar, **não é recriado automaticamente**
- ❌ Se o nó falhar, o pod **é perdido permanentemente**
- ❌ Não há **redundância** - apenas 1 instância
- ❌ Não há **balanceamento de carga** entre réplicas
- ❌ **Escalabilidade manual** e trabalhosa

### Cenário: Com ReplicaSet

Quando você cria um ReplicaSet:

```bash
kubectl apply -f replicaset.yaml
```

**Benefícios:**

- ✅ Pods crasheados são **recriados automaticamente**
- ✅ Se um nó falhar, pods são **recriados em outros nós**
- ✅ Mantém **múltiplas réplicas** para alta disponibilidade
- ✅ **Self-healing** - estado desejado é sempre mantido
- ✅ **Escalabilidade fácil** - mude o número de réplicas

---

## Como Funciona

### Arquitetura

```txt
ReplicaSet Controller
       │
       │ monitora constantemente
       ▼
   Estado Atual vs Estado Desejado
       │
       ├─► Faltam pods? → Cria novos
       ├─► Excesso de pods? → Deleta sobressalentes
       └─► Pods saudáveis? → Mantém
```

### Componentes Principais

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: meu-replicaset
  namespace: meu-namespace
spec:
  # Número desejado de réplicas
  replicas: 3

  # Como encontrar os pods que gerencia
  selector:
    matchLabels:
      app: minha-app

  # Template para criar novos pods
  template:
    metadata:
      labels:
        app: minha-app  # DEVE corresponder ao selector
    spec:
      containers:
      - name: nginx
        image: nginx:1.27.5
```

---

## Ciclo de Vida e Self-Healing

### 1. Estado Desejado: 3 réplicas

```txt
ReplicaSet configurado com replicas: 3

Estado Atual:
Pod 1 [Running]
Pod 2 [Running]
Pod 3 [Running]

✅ Estado atual = Estado desejado
   → Nenhuma ação necessária
```

### 2. Pod Crasheia

```txt
Pod 2 crasheia ou é deletado manualmente

Estado Atual:
Pod 1 [Running]
Pod 2 [Terminated]  ← Problema!
Pod 3 [Running]

❌ Estado atual (2) ≠ Estado desejado (3)
   → ReplicaSet detecta divergência
```

### 3. Self-Healing em Ação

```txt
ReplicaSet cria novo pod automaticamente

Estado Atual:
Pod 1 [Running]
Pod 3 [Running]
Pod 4 [Running]  ← Novo pod criado!

✅ Estado atual = Estado desejado novamente
```

---

## Seletor e Labels: Como o ReplicaSet Encontra Pods

### Mecânica de Labels

O ReplicaSet usa **labels** para identificar quais pods gerencia:

```yaml
spec:
  # ReplicaSet procura pods com estas labels
  selector:
    matchLabels:
      app: nginx
      tier: frontend

  # Novos pods criados terão estas labels
  template:
    metadata:
      labels:
        app: nginx        # DEVE corresponder ao selector
        tier: frontend    # DEVE corresponder ao selector
```

### Importante

⚠️ As labels no `template.metadata.labels` **DEVEM** incluir todas as labels do `selector.matchLabels`, caso contrário o ReplicaSet não conseguirá gerenciar os pods criados!

### Exemplo Prático

```bash
# ReplicaSet gerencia pods com label app=nginx
kubectl get replicaset -n lab

# Ver pods e suas labels
kubectl get pods -n lab --show-labels

# ReplicaSet conta quantos pods têm app=nginx
# Se < replicas → cria mais
# Se > replicas → deleta excesso
```

---

## Escalabilidade

### Escalar Manualmente

#### Via arquivo (Declarativo - Recomendado)

```yaml
# replicaset.yaml
spec:
  replicas: 5  # Mudou de 3 para 5
```

```bash
kubectl apply -f replicaset.yaml
```

#### Via comando (Imperativo)

```bash
# Escalar para 5 réplicas
kubectl scale replicaset meu-replicaset --replicas=5 -n meu-namespace

# Escalar para baixo
kubectl scale replicaset meu-replicaset --replicas=2 -n meu-namespace
```

### Observar Escalabilidade

```bash
# Acompanhar pods sendo criados/terminados
kubectl get pods -n meu-namespace --watch

# Ver status do ReplicaSet
kubectl get replicaset -n meu-namespace
```

Saída esperada:

```bash
NAME             DESIRED   CURRENT   READY   AGE
meu-replicaset   5         5         5       10m
```

- **DESIRED**: Número configurado em `replicas`
- **CURRENT**: Número de pods existentes
- **READY**: Número de pods prontos para receber tráfego

---

## Alta Disponibilidade

### Distribuição entre Nós

O scheduler distribui pods entre nós disponíveis:

```txt
Cluster com 3 nós:

Node 1:
  - Pod replica-1
  - Pod replica-4

Node 2:
  - Pod replica-2
  - Pod replica-5

Node 3:
  - Pod replica-3
```

### Cenário de Falha de Nó

```txt
Node 2 falha!

Antes:
  Node 1: Pod-1, Pod-4
  Node 2: Pod-2, Pod-5  ← FALHOU
  Node 3: Pod-3

ReplicaSet detecta: apenas 3 pods (desejado: 5)

Depois:
  Node 1: Pod-1, Pod-4, Pod-6  ← Novo pod
  Node 3: Pod-3, Pod-7          ← Novo pod

✅ 5 réplicas restauradas automaticamente!
```

---

## Limitações Importantes do ReplicaSet

### ❌ Não Gerencia Atualizações de Versão

**Problema principal:** ReplicaSet **NÃO atualiza** pods existentes quando você muda a imagem.

#### Exemplo do Problema

```yaml
# Versão inicial
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.27.5  # Versão antiga
```

```bash
kubectl apply -f replicaset.yaml
# Cria 3 pods com nginx:1.27.5
```

Agora você atualiza o arquivo:

```yaml
# Tentativa de atualização
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.28.0  # Versão nova
```

```bash
kubectl apply -f replicaset.yaml
# ReplicaSet é atualizado MAS...
```

**Resultado:**

```bash
kubectl get pods -n lab -o jsonpath='{.items[*].spec.containers[*].image}'

# Saída: nginx:1.27.5 nginx:1.27.5 nginx:1.27.5
# ❌ Todos os pods ainda usam versão antiga!
```

### Por que isso acontece?

O ReplicaSet apenas garante que **existam** 3 pods com as labels corretas. Como já existem 3 pods saudáveis, ele não faz nada!

### Solução: Use Deployment

```yaml
# Deployment gerencia ReplicaSets e faz rolling updates
apiVersion: apps/v1
kind: Deployment  # ← Use isto ao invés de ReplicaSet
# ... resto da configuração é similar
```

---

## ReplicaSet vs Deployment

| Aspecto | ReplicaSet | Deployment |
|---------|------------|------------|
| **Manter réplicas** | ✅ Sim | ✅ Sim (via ReplicaSet) |
| **Self-healing** | ✅ Sim | ✅ Sim (via ReplicaSet) |
| **Escalabilidade** | ✅ Sim | ✅ Sim (via ReplicaSet) |
| **Atualizações** | ❌ Manual (deletar pods) | ✅ Rolling update automático |
| **Rollback** | ❌ Não | ✅ Sim |
| **Histórico de versões** | ❌ Não | ✅ Sim |
| **Uso recomendado** | ⚠️ Raramente direto | ✅ Sempre preferir |

### Hierarquia

```txt
Deployment
    │
    ├── gerencia → ReplicaSet (v1)
    │                  └── gerencia → Pod 1, Pod 2, Pod 3
    │
    └── gerencia → ReplicaSet (v2)  [após update]
                       └── gerencia → Pod 1, Pod 2, Pod 3
```

**Conclusão:** Use Deployment em produção. ReplicaSet é útil para entender como funciona, mas Deployment é a abstração recomendada.

---

## Comandos Úteis

### Listar ReplicaSets

```bash
# Listar ReplicaSets
kubectl get replicaset -n <namespace>

# Abreviação
kubectl get rs -n <namespace>

# Ver detalhes
kubectl describe replicaset <name> -n <namespace>
```

### Escalar ReplicaSets

```bash
# Escalar para 5 réplicas
kubectl scale replicaset <name> --replicas=5 -n <namespace>

# Escalar para 0 (pausa tudo)
kubectl scale replicaset <name> --replicas=0 -n <namespace>
```

### Ver Pods Gerenciados

```bash
# Ver pods com suas labels
kubectl get pods -n <namespace> --show-labels

# Filtrar pods por label
kubectl get pods -n <namespace> -l app=nginx

# Ver qual ReplicaSet controla um pod
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences[0].name}'
```

### Deletar ReplicaSet

```bash
# Deletar ReplicaSet E todos os pods
kubectl delete replicaset <name> -n <namespace>

# Deletar ReplicaSet MAS manter pods órfãos
kubectl delete replicaset <name> -n <namespace> --cascade=orphan
```

### Ver Eventos

```bash
# Ver eventos do ReplicaSet (criação/deleção de pods)
kubectl describe replicaset <name> -n <namespace>

# Ver eventos do namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## Demonstração Prática: Self-Healing

### 1. Criar ReplicaSet com 3 réplicas

```bash
kubectl apply -f replicaset.yaml

# Ver pods criados
kubectl get pods -n lab
```

Saída:

```bash
NAME                   READY   STATUS    RESTARTS   AGE
nginx-replicaset-abc   1/1     Running   0          10s
nginx-replicaset-def   1/1     Running   0          10s
nginx-replicaset-ghi   1/1     Running   0          10s
```

### 2. Deletar um pod manualmente

```bash
# Copiar nome de um pod
kubectl delete pod nginx-replicaset-abc -n lab

# Imediatamente verificar
kubectl get pods -n lab
```

Saída:

```bash
NAME                   READY   STATUS        RESTARTS   AGE
nginx-replicaset-abc   1/1     Terminating   0          2m   ← Sendo deletado
nginx-replicaset-def   1/1     Running       0          2m
nginx-replicaset-ghi   1/1     Running       0          2m
nginx-replicaset-xyz   0/1     Pending       0          1s   ← NOVO pod criado!
```

### 3. Observar criação automática

```bash
# Após alguns segundos
kubectl get pods -n lab
```

Saída:

```bash
NAME                   READY   STATUS    RESTARTS   AGE
nginx-replicaset-def   1/1     Running   0          3m
nginx-replicaset-ghi   1/1     Running   0          3m
nginx-replicaset-xyz   1/1     Running   0          30s  ← Novo pod rodando!
```

✅ **ReplicaSet garantiu que sempre haja 3 réplicas!**

---

## Demonstração Prática: Limitação de Atualização

### 1. ReplicaSet com versão antiga

```yaml
# replicaset.yaml
image: nginx:1.27.5
```

```bash
kubectl apply -f replicaset.yaml
kubectl get pods -n lab
```

### 2. Tentar atualizar versão

```yaml
# replicaset.yaml - EDITADO
image: nginx:1.28.0  # Nova versão
```

```bash
kubectl apply -f replicaset.yaml

# Verificar imagens dos pods
kubectl get pods -n lab -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'
```

Saída:

```bash
nginx:1.27.5
nginx:1.27.5
nginx:1.27.5
```

❌ **Pods ainda usam versão antiga!**

### 3. Forçar atualização (solução manual)

```bash
# Deletar todos os pods manualmente
kubectl delete pods -l app=nginx -n lab

# ReplicaSet recria com nova imagem
kubectl get pods -n lab -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'
```

Saída:

```bash
nginx:1.28.0
nginx:1.28.0
nginx:1.28.0
```

✅ **Agora sim, mas foi manual e deselegante!**

---

## Boas Práticas

### ✅ Faça

1. **Use Deployment ao invés de ReplicaSet diretamente**
   - Deployment gerencia ReplicaSets automaticamente
   - Suporta rolling updates e rollbacks

2. **Defina resources (requests/limits)**

   ```yaml
   resources:
     requests:
       cpu: "100m"
       memory: "128Mi"
     limits:
       cpu: "250m"
       memory: "256Mi"
   ```

3. **Use labels consistentes**
   - Padrão: `app`, `tier`, `environment`, `version`
   - Facilita filtragem e gestão

4. **Monitore eventos**

   ```bash
   kubectl describe replicaset <name> -n <namespace>
   ```

### ❌ Não faça

1. **Não use ReplicaSet diretamente em produção**
   - Use Deployment para gerenciar atualizações

2. **Não edite pods gerenciados manualmente**
   - ReplicaSet pode deletá-los se divergirem

3. **Não confie em nomes de pods**
   - Pods são efêmeros e nomes mudam
   - Use Services para descoberta

4. **Não use réplicas: 1 achando que é redundância**
   - Use no mínimo 2-3 réplicas para alta disponibilidade

---

## Quando Usar ReplicaSet Diretamente?

### ✅ Casos raros de uso direto

- **Aprendizado didático**: Entender conceitos fundamentais
- **Casos muito específicos**: Quando você precisa de controle manual total sobre versões
- **Sistemas legados**: Código antigo que ainda usa ReplicaSets

### ❌ Não use em produção

Em 99% dos casos, use **Deployment** ao invés de ReplicaSet diretamente!

---

## Resumo

| Conceito | Descrição |
|----------|-----------|
| **Propósito** | Manter número desejado de réplicas rodando |
| **Self-healing** | Recria pods automaticamente quando falham |
| **Escalabilidade** | Fácil ajuste do número de réplicas |
| **Alta disponibilidade** | Múltiplas réplicas distribuídas entre nós |
| **Limitação principal** | Não gerencia atualizações de versão |
| **Solução** | Use Deployment para gerenciar ReplicaSets |

### Fluxo de Aprendizado

```txt
1. Pod Individual
   ↓ Problema: sem self-healing

2. ReplicaSet
   ↓ Solução: self-healing e réplicas
   ↓ Problema: atualizações manuais

3. Deployment
   ✅ Solução completa: self-healing + rolling updates
```

ReplicaSet é uma peça fundamental do Kubernetes, mas use-o através de Deployments.
