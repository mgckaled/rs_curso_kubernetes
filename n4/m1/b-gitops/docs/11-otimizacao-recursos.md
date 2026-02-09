<!-- markdownlint-disable -->

# Otimizacao de Recursos - Argo CD em Ambiente Local

Guia pratico para otimizar o consumo de RAM do Argo CD ao rodar
em clusters Kind com recursos limitados (2.5 GB de RAM).

---

## 1. Contexto do Problema

O Argo CD foi projetado para ambientes de producao com recursos abundantes.
Cada componente possui valores padrao de `requests` e `limits` que, somados,
podem facilmente ultrapassar 2 GB de RAM apenas para o Argo CD.

Em ambientes locais de estudo como o Kind (Kubernetes in Docker), a RAM
disponivel e compartilhada com o sistema operacional, o Docker Desktop e
o proprio control plane do Kubernetes. Sem otimizacao, o ambiente pode
atingir o limite de memoria e apresentar instabilidade (pods em
`OOMKilled`, reinicializacoes constantes ou travamentos do Docker).

**Por isso, otimizar os resource limits e essencial para rodar
o Argo CD localmente com estabilidade.**

---

## 2. Tipos de Instalacao do Argo CD

O Argo CD oferece tres tipos de instalacao, cada um com diferente
consumo de recursos:

| Tipo | Arquivo YAML | Inclui UI | Alta Disponibilidade (HA) | Uso Recomendado |
|------|-------------|-----------|--------------------------|----------------|
| Non-HA (padrao) | `install.yaml` | Sim | Nao | Dev / estudo |
| HA | `ha/install.yaml` | Sim | Sim | Producao |
| Core | `core-install.yaml` | Nao | Nao | Minimo possivel |

**Para este projeto, usamos a instalacao Non-HA (padrao)** porque:

- Inclui a interface web (UI), essencial para aprendizado visual.
- Nao replica componentes (1 pod por componente), economizando RAM.
- A instalacao HA duplica ou triplica cada componente, inviavel localmente.

> Se sua maquina tiver menos de 2 GB livres para o cluster,
> considere a instalacao **Core** (`core-install.yaml`), que remove
> a UI e o dex-server, reduzindo significativamente o consumo.

---

## 3. Consumo de RAM por Componente

A tabela abaixo compara os valores padrao do Argo CD com os valores
otimizados para ambiente local:

| Componente | Padrao (requests / limits) | Otimizado (requests / limits) |
|------------|---------------------------|-------------------------------|
| `argocd-server` | 256Mi / 512Mi | 64Mi / 256Mi |
| `argocd-repo-server` | 256Mi / 512Mi | 64Mi / 256Mi |
| `argocd-application-controller` | 512Mi / 1Gi | 128Mi / 512Mi |
| `argocd-redis` | 128Mi / 256Mi | 32Mi / 128Mi |
| `argocd-dex-server` | 128Mi / 256Mi | 32Mi / 64Mi |
| `argocd-applicationset-controller` | 128Mi / 256Mi | 64Mi / 128Mi |
| `argocd-notifications-controller` | 64Mi / 128Mi | 32Mi / 64Mi |
| **TOTAL** | **~1.5 Gi / ~2.9 Gi** | **~416 Mi / ~1408 Mi** |

**O que significam requests e limits:**

- **requests**: quantidade minima de memoria que o Kubernetes reserva
  para o pod ao agenda-lo em um node. O scheduler so coloca o pod em
  um node que tenha pelo menos essa quantidade disponivel.
- **limits**: quantidade maxima de memoria que o pod pode consumir.
  Se ultrapassar, o Kubernetes encerra o container com `OOMKilled`.

**Impacto da otimizacao:**

- Os `requests` caem de ~1.5 Gi para ~416 Mi (reducao de ~72%).
- Os `limits` caem de ~2.9 Gi para ~1408 Mi (reducao de ~51%).
- O cluster consegue agendar todos os pods sem pressao de memoria.

---

## 4. Estimativa Total do Ambiente

Considerando todos os componentes rodando simultaneamente:

| Componente | RAM Estimada |
|------------|-------------|
| Kind control-plane (kubelet, etcd, apiserver, scheduler) | 600 - 800 MB |
| Argo CD (com limits otimizados) | 800 - 1400 MB |
| App demo (nginx) | 5 - 10 MB |
| **Total estimado** | **1.4 - 2.2 GB** |

Essa estimativa cabe confortavelmente nos 2.5 GB de RAM alocados
para o WSL2, deixando margem para picos temporarios de consumo.

> **Nota**: esses valores sao estimativas baseadas em uso tipico
> de estudo. O consumo real varia conforme o numero de aplicacoes
> gerenciadas pelo Argo CD e a frequencia de sincronizacoes.

---

## 5. Como Aplicar Resource Limits (Patches)

### Por que usar patches?

O arquivo oficial `install.yaml` do Argo CD **nao define resource limits
por padrao**. Ele apenas define os Deployments, Services e demais recursos,
mas deixa os campos `resources.requests` e `resources.limits` vazios.

Sem limits definidos, cada pod pode consumir memoria livremente, o que
em um cluster local pode causar instabilidade rapidamente.

### Estrategia com patches

Em vez de modificar diretamente o `install.yaml` oficial (o que
dificultaria atualizacoes futuras), utilizamos **patches separados**
que sobrescrevem apenas os campos de recursos de cada Deployment.

O arquivo de patches esta em:

```text
manifests/02-argocd-resource-patches.yaml
```

### Estrutura de um patch de recursos

Cada patch segue este formato:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server          # Nome do Deployment a ser alterado
  namespace: argocd            # Namespace onde o Argo CD esta instalado
spec:
  template:
    spec:
      containers:
        - name: argocd-server  # Nome do container dentro do pod
          resources:
            requests:
              memory: "64Mi"   # Memoria minima reservada
              cpu: "50m"       # CPU minima reservada
            limits:
              memory: "256Mi"  # Memoria maxima permitida
              cpu: "500m"      # CPU maxima permitida
```

Esse mesmo padrao e repetido para cada componente do Argo CD,
ajustando os valores conforme a tabela da secao 3.

### Aplicando os patches

Apos instalar o Argo CD com o `install.yaml` oficial, aplique os
patches com:

```bash
# Aplicar os patches de resource limits
kubectl apply -f manifests/02-argocd-resource-patches.yaml
```

O Kubernetes faz merge dos patches com os Deployments existentes,
adicionando ou sobrescrevendo apenas os campos especificados.

---

## 6. Dicas Extras para Economizar RAM

### 6.1. Fechar aplicacoes desnecessarias

Antes de subir o cluster, feche programas que consomem muita memoria:

- Navegadores com muitas abas abertas
- IDEs pesadas (VS Code com muitas extensoes, IntelliJ)
- Aplicacoes Electron (Slack, Discord, Teams)

### 6.2. Limitar RAM do WSL2 via .wslconfig

O Docker Desktop no Windows roda dentro do WSL2, que por padrao pode
consumir ate 50% da RAM total do sistema. Para limitar:

1. Crie ou edite o arquivo `C:\Users\<seu-usuario>\.wslconfig`:

```ini
[wsl2]
memory=3GB
swap=1GB
processors=2
```

2. Reinicie o WSL2 para aplicar:

```powershell
wsl --shutdown
```

3. Reabra o Docker Desktop.

> **Recomendacao**: alocar 2.5 a 3 GB para o WSL2 e suficiente para
> o projeto. Valores menores podem causar instabilidade.

### 6.3. Monitorar consumo de recursos

Use o script de verificacao incluido no projeto para acompanhar
o consumo de RAM em tempo real:

```bash
bash scripts/06-check-resources.sh
```

Esse script mostra:

- Consumo de memoria dos containers Docker (Kind nodes).
- Status e recursos dos pods no namespace `argocd`.
- Clusters Kind ativos no momento.

### 6.4. Alternativa para maquinas com pouca RAM

Se mesmo com a otimizacao o ambiente estiver instavel, considere
usar a instalacao **Core** do Argo CD:

```bash
# Instalacao Core (sem UI, sem dex-server)
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
```

Na instalacao Core:

- A interface web (UI) nao e instalada.
- O dex-server (autenticacao) nao e instalado.
- Toda interacao e feita via CLI (`argocd`) ou `kubectl`.
- O consumo de RAM cai significativamente.

---

## 7. Resumo

| Acao | Impacto |
|------|---------|
| Usar instalacao Non-HA (em vez de HA) | Evita replicacao de pods |
| Aplicar patches de resource limits | Reduz limits de ~2.9 Gi para ~1.4 Gi |
| Limitar RAM do WSL2 via `.wslconfig` | Evita que WSL2 consuma RAM excessiva |
| Monitorar com `scripts/06-check-resources.sh` | Detecta problemas antes que causem falhas |
| Usar instalacao Core (se necessario) | Remove UI e dex, consumo minimo |

Com essas otimizacoes, e possivel rodar o Argo CD localmente em um
cluster Kind com apenas 2.5 GB de RAM de forma estavel e funcional
para fins de estudo.
