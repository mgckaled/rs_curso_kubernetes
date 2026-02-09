<!-- markdownlint-disable -->

# Operacao Pratica do Argo CD - Aula 6

Documentacao sobre a operacao dia-a-dia do Argo CD, cobrindo AutoSync, deteccao de drift, rollback, monitoramento de saude dos recursos e comandos essenciais para o uso cotidiano da ferramenta.

---

## Indice

1. [AutoSync: Como Funciona](#autosync-como-funciona)
2. [Commit como Gatilho de Deploy](#commit-como-gatilho-de-deploy)
3. [Drift Detection: Deteccao de Divergencia](#drift-detection-deteccao-de-divergencia)
4. [Diff de Manifestos YAML](#diff-de-manifestos-yaml)
5. [Rollback: Revertendo Mudancas](#rollback-revertendo-mudancas)
6. [Health Status dos Recursos](#health-status-dos-recursos)
7. [Como Forcar Refresh](#como-forcar-refresh)
8. [Tabela de Acoes Comuns do Dia-a-Dia](#tabela-de-acoes-comuns-do-dia-a-dia)
9. [Resumo](#resumo)
10. [Referencias](#referencias)

---

## AutoSync: Como Funciona

O AutoSync e o mecanismo que permite ao Argo CD **sincronizar automaticamente** o cluster com o repositorio Git, sem intervencao humana. Quando habilitado, qualquer divergencia detectada entre o Git e o cluster e corrigida automaticamente.

### Polling: o ciclo de verificacao

O Argo CD verifica mudancas no repositorio Git atraves de um mecanismo chamado **polling**. Por padrao, o intervalo de polling e de aproximadamente **180 segundos (3 minutos)**.

```
┌─────────────────────────────────────────────────────────────────┐
│                   Ciclo de Polling do Argo CD                     │
│                                                                   │
│   T=0s          T=180s         T=360s         T=540s             │
│    |              |              |              |                  │
│    v              v              v              v                  │
│  [poll]         [poll]         [poll]         [poll]              │
│    |              |              |              |                  │
│  "sem            "novo          "sem           "sem               │
│   mudanca"       commit!"       mudanca"       mudanca"           │
│                   |                                               │
│                   v                                               │
│                [sync]                                             │
│                   |                                               │
│                   v                                               │
│              Cluster atualizado                                  │
│                                                                   │
│   Intervalo padrao: ~180 segundos (configuravel)                 │
└─────────────────────────────────────────────────────────────────┘
```

### Configuracao do intervalo de polling

O intervalo de polling pode ser ajustado no ConfigMap `argocd-cm`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  # Intervalo de polling em segundos (padrao: 180)
  timeout.reconciliation: "180"
```

Valores comuns:

| Valor | Intervalo | Cenario |
|-------|-----------|---------|
| `60` | 1 minuto | Ambientes de desenvolvimento (mais responsivo) |
| `180` | 3 minutos | Padrao (equilibrio entre responsividade e carga) |
| `300` | 5 minutos | Ambientes com muitas Applications (menor carga no Git) |

### Webhooks: alternativa ao polling

Em vez de esperar o proximo ciclo de polling, voce pode configurar **webhooks** no GitHub/GitLab para notificar o Argo CD imediatamente apos cada push:

```
Push no Git --> Webhook --> Argo CD recebe notificacao --> Sync imediato
```

Isso reduz o tempo entre o push e o deploy de ~180 segundos para **poucos segundos**. Em ambiente local de estudo, o polling padrao e suficiente.

### O que o AutoSync faz e nao faz

| O que faz | O que nao faz |
|-----------|---------------|
| Aplica novos commits automaticamente | Nao executa builds de imagem Docker |
| Reverte mudancas manuais (selfHeal) | Nao roda testes automatizados |
| Remove recursos deletados do Git (prune) | Nao faz code review |
| Mantem o cluster sempre atualizado | Nao garante que o commit e correto |

---

## Commit como Gatilho de Deploy

No modelo GitOps com Argo CD, o **commit** e o unico gatilho valido para alteracoes no cluster. O fluxo completo desde o commit ate a aplicacao no cluster segue estas etapas:

### Fluxo completo

```
┌──────────────────────────────────────────────────────────────────┐
│              Commit como Gatilho de Deploy                        │
│                                                                   │
│   1. Desenvolvedor edita YAML localmente                         │
│      (ex: muda replicas de 3 para 5)                             │
│                     |                                             │
│                     v                                             │
│   2. git add + git commit + git push                             │
│      (mudanca chega ao GitHub)                                   │
│                     |                                             │
│                     v                                             │
│   3. Argo CD detecta novo commit                                 │
│      (polling a cada ~180s ou via webhook)                       │
│                     |                                             │
│                     v                                             │
│   4. Argo CD compara: Git (replicas: 5) vs Cluster (replicas: 3)│
│      Resultado: OutOfSync                                        │
│                     |                                             │
│                     v                                             │
│   5a. [AutoSync ON]  -> Aplica automaticamente                   │
│   5b. [AutoSync OFF] -> Marca como OutOfSync, aguarda usuario    │
│                     |                                             │
│                     v                                             │
│   6. Cluster atualizado: replicas = 5                            │
│      Application status: Synced + Healthy                        │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Tempo total estimado (com polling padrao)

| Etapa | Tempo estimado |
|-------|----------------|
| Commit + push | Instantaneo |
| Argo CD detecta (polling) | 0 a 180 segundos |
| Argo CD compara e aplica | 5 a 30 segundos |
| Pods atualizados (rollout) | 10 a 60 segundos |
| **Total** | **15 segundos a ~4 minutos** |

Com webhooks configurados, o tempo total cai para **15 a 90 segundos**.

### O que nao aciona o Argo CD

Alteracoes que **nao sao commits em arquivos YAML** no path observado nao acionam o Argo CD:

- Mudancas em codigo-fonte (`.js`, `.go`, `.py`)
- Mudancas em arquivos fora do `path` configurado na Application
- Mudancas em branches diferentes da `targetRevision`
- Commits que alteram apenas `README.md` ou documentacao

---

## Drift Detection: Deteccao de Divergencia

**Drift** (desvio ou dissonancia) e a divergencia entre o estado desejado (Git) e o estado real (cluster). O Argo CD monitora continuamente ambos os lados para detectar drift.

### Causas comuns de drift

| Causa | Exemplo | Frequencia |
|-------|---------|------------|
| Alteracao manual via kubectl | `kubectl scale deployment --replicas=10` | Comum |
| Editar recurso diretamente | `kubectl edit deployment minha-app` | Comum |
| Hotfix de emergencia | Mudar imagem do container sem commit | Ocasional |
| Escala manual para debug | Aumentar replicas para teste de carga | Ocasional |
| Outro operador ou ferramenta | Helm upgrade executado por outra equipe | Raro |

### Como o Argo CD detecta drift

O Argo CD compara o estado em dois momentos distintos:

```
┌───────────────────────────────────────────────────────────────┐
│                  Deteccao de Drift                              │
│                                                                │
│   Estado desejado (Git)          Estado real (Cluster)         │
│   ┌──────────────────┐          ┌──────────────────────┐      │
│   │ replicas: 3      │   ==/== │ replicas: 10          │      │
│   │ image: v2.0      │  DRIFT! │ image: v2.0           │      │
│   │ cpu: 250m        │          │ cpu: 250m             │      │
│   └──────────────────┘          └──────────────────────┘      │
│                                                                │
│   Argo CD detecta:                                             │
│   - Campo "replicas" diverge (3 no Git vs 10 no cluster)      │
│   - Application marcada como OutOfSync                        │
│                                                                │
│   Se selfHeal = true:                                          │
│   - Argo CD reverte replicas para 3 automaticamente           │
│   - Application volta a Synced                                │
│                                                                │
│   Se selfHeal = false:                                         │
│   - Application permanece OutOfSync                           │
│   - Drift persiste ate sync manual                            │
└───────────────────────────────────────────────────────────────┘
```

### selfHeal: correcao automatica de drift

O `selfHeal` e a opcao que define se o Argo CD **reverte** automaticamente mudancas manuais:

| selfHeal | Comportamento | Cenario recomendado |
|----------|---------------|---------------------|
| `true` | Reverte qualquer alteracao manual no cluster | Ambientes onde o Git e a unica verdade (padrao GitOps) |
| `false` | Detecta drift mas nao corrige | Ambientes em transicao para GitOps |

Com `selfHeal: true`, executar `kubectl scale deployment --replicas=10` diretamente no cluster e inutil: o Argo CD ira reverter para o valor definido no Git (ex: `replicas: 3`) no proximo ciclo de reconciliacao.

### Exemplo pratico de drift e selfHeal

```bash
# 1. Verificar estado atual (Synced, replicas=3)
kubectl get deployment demo-nginx -n demo-app

# 2. Causar drift manualmente
kubectl scale deployment demo-nginx -n demo-app --replicas=10

# 3. Verificar que agora tem 10 replicas (drift!)
kubectl get deployment demo-nginx -n demo-app

# 4. Aguardar ~30 segundos (selfHeal em acao)

# 5. Verificar novamente: Argo CD reverteu para 3 replicas
kubectl get deployment demo-nginx -n demo-app
```

---

## Diff de Manifestos YAML

O Argo CD oferece a capacidade de visualizar a **diferenca** (diff) entre o que esta no Git e o que esta no cluster. Isso e essencial para entender exatamente o que mudou antes de sincronizar.

### Diff pela interface web (UI)

Na UI do Argo CD, ao clicar em uma Application que esta **OutOfSync**, voce pode visualizar o diff detalhado:

1. Clicar na Application na lista
2. Clicar no botao **"App Diff"** ou no recurso especifico
3. Ver a comparacao lado a lado: Git (desejado) vs Cluster (atual)

O diff mostra:

- Linhas **adicionadas** (existem no Git mas nao no cluster)
- Linhas **removidas** (existem no cluster mas nao no Git)
- Linhas **modificadas** (diferentes entre Git e cluster)

### Diff pela CLI

Usando a CLI do Argo CD, o diff pode ser visualizado com:

```bash
# Ver diff completo da Application
argocd app diff demo-nginx

# Ver diff de um recurso especifico dentro da Application
argocd app diff demo-nginx --resource Deployment:demo-nginx
```

### Diff via kubectl

Voce tambem pode comparar manualmente usando kubectl:

```bash
# Exportar estado atual do cluster
kubectl get deployment demo-nginx -n demo-app -o yaml > cluster.yaml

# Comparar com o YAML do Git
diff cluster.yaml manifests/deployment.yaml
```

### Quando usar o diff

| Situacao | Acao |
|----------|------|
| Application OutOfSync apos commit | Ver o diff para confirmar que as mudancas estao corretas antes de sincronizar |
| Suspeita de drift manual | Ver o diff para identificar o que foi alterado no cluster |
| Antes de um sync manual em producao | Revisar todas as mudancas que serao aplicadas |
| Debug de problemas de sincronizacao | Identificar campos conflitantes ou divergentes |

---

## Rollback: Revertendo Mudancas

O Argo CD mantem um **historico de sincronizacoes**, permitindo reverter para um estado anterior caso algo de errado.

### Historico de sincronizacoes

Cada vez que o Argo CD sincroniza uma Application, ele registra:

- O commit SHA que foi sincronizado
- A data e hora da sincronizacao
- O resultado (sucesso ou falha)
- Os recursos que foram criados, atualizados ou removidos

### Visualizar historico via CLI

```bash
# Ver historico de deploy da Application
argocd app history demo-nginx
```

Saida esperada:

```
ID  DATE                           REVISION
0   2025-01-15 10:30:00 +0000 UTC  abc1234 (HEAD)
1   2025-01-14 14:20:00 +0000 UTC  def5678
2   2025-01-13 09:15:00 +0000 UTC  ghi9012
```

### Rollback via CLI

Para reverter para uma versao anterior:

```bash
# Reverter para o deploy com ID 1
argocd app rollback demo-nginx 1
```

Esse comando aplica no cluster o estado que existia no commit `def5678`, revertendo as mudancas do commit `abc1234`.

### Rollback via UI

Na interface web do Argo CD:

1. Clicar na Application
2. Clicar em **"History and Rollback"**
3. Localizar a versao desejada na lista
4. Clicar no botao **"Rollback"** ao lado da versao

### Rollback via Git (recomendado em GitOps)

A forma mais alinhada com o modelo GitOps de reverter mudancas e **pelo Git**, nao pelo Argo CD:

```bash
# Identificar o commit problematico
git log --oneline

# Reverter o commit (cria um novo commit de reversao)
git revert abc1234

# Enviar a reversao para o repositorio
git push
```

O Argo CD detecta o novo commit de reversao e sincroniza automaticamente o cluster para o estado anterior.

### Tabela comparativa de metodos de rollback

| Metodo | Como funciona | Alinhado com GitOps | Persiste no Git |
|--------|---------------|---------------------|-----------------|
| `argocd app rollback` | Aplica estado anterior diretamente no cluster | Parcialmente (pode causar drift) | Nao |
| `git revert` + push | Cria commit de reversao no Git | Sim (Git e a fonte da verdade) | Sim |
| Rollback via UI | Mesmo que CLI, pela interface grafica | Parcialmente | Nao |

A recomendacao e sempre usar **`git revert`** para rollbacks, pois mantem o Git como fonte unica da verdade e gera rastreabilidade completa.

### Atencao com rollback e AutoSync

Se o AutoSync estiver habilitado e voce fizer rollback via CLI (sem alterar o Git), o Argo CD ira **reverter o rollback** no proximo ciclo de polling, porque o Git ainda contem o commit mais recente. Para evitar isso:

1. **Desabilite o AutoSync temporariamente** antes do rollback via CLI
2. **Ou use `git revert`** (metodo recomendado), que funciona naturalmente com o AutoSync

---

## Health Status dos Recursos

O Argo CD monitora continuamente o **status de saude** de cada recurso gerenciado. Isso permite identificar rapidamente problemas no cluster.

### Hierarquia de saude

O health status segue a hierarquia natural dos recursos Kubernetes. A saude da Application depende da saude de todos os recursos que ela gerencia:

```
Application: demo-nginx
│
├── Deployment: demo-nginx
│   │  Health: Healthy / Degraded / Progressing
│   │
│   └── ReplicaSet: demo-nginx-abc123
│       │  Health: Healthy / Degraded / Progressing
│       │
│       ├── Pod: demo-nginx-abc123-x1  (Running)
│       ├── Pod: demo-nginx-abc123-x2  (Running)
│       └── Pod: demo-nginx-abc123-x3  (CrashLoopBackOff -> Degraded)
│
├── Service: demo-nginx-svc
│   Health: Healthy (Service existe e tem endpoints)
│
└── ConfigMap: demo-nginx-config
    Health: Healthy (ConfigMap existe)
```

### Regra de propagacao de saude

A saude da Application e determinada pelo **pior** status entre seus recursos:

| Recursos | Status da Application |
|----------|----------------------|
| Todos Healthy | **Healthy** |
| Pelo menos um Progressing, nenhum Degraded | **Progressing** |
| Pelo menos um Degraded | **Degraded** |
| Pelo menos um Missing | **Missing** |
| Pelo menos um Unknown | **Unknown** |

### Health check por tipo de recurso

Cada tipo de recurso Kubernetes tem sua propria logica de health check:

| Recurso | Healthy quando | Degraded quando |
|---------|----------------|-----------------|
| **Deployment** | Todas as replicas disponiveis (Ready) | Replicas insuficientes ou pods falhando |
| **ReplicaSet** | Numero desejado de pods Running | Pods em CrashLoopBackOff ou Error |
| **Pod** | Container Running e health checks passando | CrashLoopBackOff, Error, ImagePullBackOff |
| **Service** | Existe e tem endpoints (se aplicavel) | Sempre Healthy se existe |
| **ConfigMap** | Existe | Sempre Healthy se existe |
| **Ingress** | Endereco IP atribuido | Sem endereco atribuido |
| **PVC** | Status Bound | Status Pending |

### Monitorando health pela CLI

```bash
# Ver status geral da Application (inclui health)
argocd app get demo-nginx

# Ver recursos individuais com health status
argocd app resources demo-nginx
```

### Monitorando health pela UI

Na interface web, a saude e representada visualmente:

- **Coracao verde:** Healthy
- **Coracao amarelo:** Progressing
- **Coracao vermelho:** Degraded
- **Coracao cinza:** Unknown ou Missing

---

## Como Forcar Refresh

O Argo CD verifica mudancas no Git a cada ~180 segundos (polling). Se voce fez um push e nao quer esperar o proximo ciclo, pode forcar um refresh imediato.

### Refresh vs Hard Refresh

| Tipo | Comando | O que faz |
|------|---------|-----------|
| **Refresh** | `argocd app get <app> --refresh` | Verifica o repositorio Git e compara com o cluster |
| **Hard Refresh** | `argocd app get <app> --hard-refresh` | Limpa o cache do repo-server e faz clone fresco do repositorio |

### Quando usar cada tipo

| Situacao | Tipo recomendado |
|----------|------------------|
| Fez push e quer ver o OutOfSync imediatamente | Refresh |
| Mudou branch ou tag no repositorio | Hard Refresh |
| Cache do repo-server parece desatualizado | Hard Refresh |
| Verificacao rapida de rotina | Refresh |

### Comandos de refresh

```bash
# Refresh normal (verifica Git e compara)
argocd app get demo-nginx --refresh

# Hard refresh (limpa cache e faz clone fresco)
argocd app get demo-nginx --hard-refresh
```

### Refresh pela UI

Na interface web:

1. Abrir a Application
2. Clicar no botao **"Refresh"** no canto superior
3. Para hard refresh, clicar na seta ao lado do botao e selecionar **"Hard Refresh"**

---

## Tabela de Acoes Comuns do Dia-a-Dia

### Visualizacao e monitoramento

| Acao | Comando CLI | Alternativa UI |
|------|-------------|----------------|
| Listar todas as Applications | `argocd app list` | Dashboard principal |
| Ver detalhes de uma Application | `argocd app get demo-nginx` | Clicar na Application |
| Ver recursos da Application | `argocd app resources demo-nginx` | Aba "Resources" na Application |
| Ver diff (Git vs Cluster) | `argocd app diff demo-nginx` | Botao "App Diff" |
| Ver historico de deploys | `argocd app history demo-nginx` | Botao "History and Rollback" |
| Ver logs de um pod | `argocd app logs demo-nginx` | Clicar no Pod -> "Logs" |

### Sincronizacao

| Acao | Comando CLI | Alternativa UI |
|------|-------------|----------------|
| Sincronizar Application | `argocd app sync demo-nginx` | Botao "Sync" |
| Forcar refresh do Git | `argocd app get demo-nginx --refresh` | Botao "Refresh" |
| Hard refresh (limpa cache) | `argocd app get demo-nginx --hard-refresh` | Botao "Hard Refresh" |
| Sync com prune (remove orfaos) | `argocd app sync demo-nginx --prune` | Marcar "Prune" no modal de Sync |

### Rollback e correcao

| Acao | Comando CLI | Alternativa UI |
|------|-------------|----------------|
| Rollback para versao anterior | `argocd app rollback demo-nginx <ID>` | Botao "Rollback" no historico |
| Reverter via Git (recomendado) | `git revert <SHA> && git push` | N/A (feito no Git) |

### Gerenciamento

| Acao | Comando CLI | Alternativa UI |
|------|-------------|----------------|
| Criar Application | `kubectl apply -f application.yaml` | Botao "New App" (nao recomendado) |
| Deletar Application | `argocd app delete demo-nginx` | Botao "Delete" na Application |
| Deletar com cascade (remove recursos) | `argocd app delete demo-nginx --cascade` | Marcar "cascade" ao deletar |

### Usando kubectl diretamente

| Acao | Comando kubectl |
|------|-----------------|
| Listar Applications | `kubectl get applications -n argocd` |
| Ver detalhes | `kubectl describe application demo-nginx -n argocd` |
| Criar Application | `kubectl apply -f manifests/05-argocd-application.yaml` |
| Deletar Application | `kubectl delete application demo-nginx -n argocd` |
| Ver eventos | `kubectl get events -n argocd --sort-by=.lastTimestamp` |

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **AutoSync** | Sincronizacao automatica entre Git e cluster, acionada por polling (~180s) ou webhook |
| **Polling** | Mecanismo de verificacao periodica do repositorio Git (padrao: 180 segundos) |
| **Commit como gatilho** | No GitOps, o commit e push sao os unicos meios legitimos de alterar o cluster |
| **Drift** | Divergencia entre estado desejado (Git) e estado real (cluster) |
| **selfHeal** | Correcao automatica de drift (reverte mudancas manuais no cluster) |
| **Diff** | Comparacao detalhada entre Git e cluster para identificar divergencias |
| **Rollback** | Reversao para estado anterior (via CLI, UI ou git revert) |
| **git revert** | Metodo preferido de rollback em GitOps (mantem rastreabilidade no Git) |
| **Health status** | Monitoramento de saude dos recursos (Healthy, Degraded, Progressing) |
| **Refresh** | Verificacao imediata do Git sem esperar o proximo ciclo de polling |
| **Hard Refresh** | Refresh com limpeza de cache do repo-server |

---

## Referencias

- [Argo CD - Automated Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
- [Argo CD - Sync Options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [Argo CD - Tracking and Deployment Strategies](https://argo-cd.readthedocs.io/en/stable/user-guide/tracking_strategies/)
- [Argo CD - Health Assessment](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/)
- [Argo CD - Webhook Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/)
- [Argo CD - Diffing Customization](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/)
