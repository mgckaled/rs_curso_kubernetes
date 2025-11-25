# Limpeza de Cluster Kubernetes

## Contexto

Guia genérico para remover clusters Kind do sistema e limpar configurações do kubeconfig.

---

## Opção 1: Via Lens (Recomendado para Iniciantes)

### Passo a Passo

1. Abra o Lens
2. Localize o cluster que deseja remover na lista
3. Clique com botão direito → **"Remove from kubeconfig"**
4. Confirme a ação

### O que acontece?

- Remove apenas a configuração de acesso
- Não afeta outros clusters
- Não deleta o cluster real (caso ainda exista no Docker)

---

## Opção 2: Via kubectl (Manual)

### 1. Verificar contextos atuais

```bash
kubectl config get-contexts
```

### 2. Deletar o contexto específico

```bash
kubectl config delete-context kind-<NOME-DO-CLUSTER>
```

### 3. Deletar o cluster da configuração

```bash
kubectl config delete-cluster kind-<NOME-DO-CLUSTER>
```

### 4. Deletar o usuário da configuração

```bash
kubectl config delete-user kind-<NOME-DO-CLUSTER>
```

### 5. Verificar se foi removido

```bash
kubectl config get-contexts
```

---

## Opção 3: Deletar o Cluster Real via Kind

Se você quiser garantir que o cluster foi completamente deletado (não apenas removido do kubeconfig):

### 1. Iniciar o Docker Desktop

Certifique-se de que o Docker Desktop está rodando.

### 2. Listar clusters Kind existentes

```bash
kind get clusters
```

### 3. Deletar o cluster específico

```bash
kind delete cluster --name <NOME-DO-CLUSTER>
```

Este comando:

- Deleta todos os containers do cluster
- Remove recursos do Docker
- Remove automaticamente do kubeconfig

---

## Qual Opção Escolher?

| Situação | Recomendação |
|----------|--------------|
| Apenas limpar configuração | Opção 1 (Lens) ou Opção 2 (kubectl) |
| Garantir que o cluster foi totalmente removido | Opção 3 (kind delete) |
| Não sabe se o cluster existe | Opção 3 primeiro, depois Opção 2 se necessário |

---

## Checklist de Segurança

- [ ] Docker Desktop rodando
- [ ] Verificar qual cluster está ativo (`kubectl config current-context`)
- [ ] Backup do kubeconfig (opcional): `copy %USERPROFILE%\.kube\config %USERPROFILE%\.kube\config.backup`

---

## Comandos de Verificação Pós-Limpeza

```bash
# Ver contextos restantes
kubectl config get-contexts

# Verificar cluster atual
kubectl config current-context

# Listar clusters Kind
kind get clusters

# Ver todos os containers Docker relacionados ao Kind
docker ps -a --filter label=io.x-k8s.kind.cluster
```

---

## Exemplo Prático

### Cenário: Deletar um cluster chamado "old-cluster"

```bash
# 1. Listar clusters existentes
kind get clusters

# 2. Deletar o cluster (remove do Docker e do kubeconfig)
kind delete cluster --name old-cluster

# 3. Verificar se foi removido
kind get clusters
kubectl config get-contexts
```

### Cenário: Remover apenas do kubeconfig (cluster já foi deletado)

```bash
# 1. Ver contextos atuais
kubectl config get-contexts

# 2. Remover contexto
kubectl config delete-context kind-old-cluster

# 3. Remover cluster
kubectl config delete-cluster kind-old-cluster

# 4. Remover usuário
kubectl config delete-user kind-old-cluster

# 5. Verificar
kubectl config get-contexts
```

---

## Notas Importantes

- **Prefixo `kind-`**: Clusters Kind sempre usam o prefixo `kind-` no kubeconfig
- **Cluster ativo**: Se você deletar o cluster que está ativo, mude para outro com `kubectl config use-context <nome>`
- **Múltiplos clusters**: Você pode ter vários clusters Kind rodando simultaneamente
- **Limpeza completa**: A Opção 3 (`kind delete cluster`) é a mais completa e remove tudo
