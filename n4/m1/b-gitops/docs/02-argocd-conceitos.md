<!-- markdownlint-disable -->

# Argo CD: Conceitos Fundamentais

## Indice

- [Introducao](#introducao)
- [O que e o Argo CD](#o-que-e-o-argo-cd)
- [Como o Argo CD Funciona](#como-o-argo-cd-funciona)
- [Arquitetura do Argo CD](#arquitetura-do-argo-cd)
- [Componentes Principais](#componentes-principais)
- [CRD e Controller Pattern](#crd-e-controller-pattern)
- [Conceitos Operacionais](#conceitos-operacionais)
- [Modos de Sincronizacao](#modos-de-sincronizacao)
- [O que o Argo CD Observa vs Nao Observa](#o-que-o-argo-cd-observa-vs-nao-observa)
- [Relacao com Argo Rollouts](#relacao-com-argo-rollouts)
- [Interface Grafica (UI)](#interface-grafica-ui)
- [Resumo](#resumo)
- [Referencias](#referencias)

## Introducao

Este documento apresenta os conceitos fundamentais do **Argo CD**, a ferramenta de entrega continua declarativa para Kubernetes que implementa o modelo GitOps. O conteudo aqui abordado corresponde a **Aula 3** do curso, servindo como base conceitual para as aulas praticas seguintes.

O objetivo e que o leitor compreenda **o que e** o Argo CD, **como funciona** sua reconciliacao continua, quais sao seus **componentes internos** e quais sao os **limites** de responsabilidade da ferramenta.

## O que e o Argo CD

O Argo CD e um projeto **open source** mantido pelo **Argo Project**, uma colecao de ferramentas para workflows e entrega continua no Kubernetes. O Argo Project faz parte da **CNCF** (Cloud Native Computing Foundation) e inclui outros projetos como Argo Workflows, Argo Events e Argo Rollouts.

### Caracteristicas Principais

- **Continuous Delivery declarativa:** diferentemente de pipelines imperativas (que executam comandos como `kubectl apply`), o Argo CD adota uma abordagem declarativa. Voce define o estado desejado em arquivos YAML no Git e o Argo CD garante que o cluster reflita esse estado.
- **Nativo para Kubernetes:** o Argo CD foi criado especificamente para Kubernetes. Ele nao e uma ferramenta generica adaptada -- e uma solucao que entende a API do Kubernetes nativamente.
- **Baseado em GitOps (pull-based):** o Argo CD **puxa** as mudancas do Git, em vez de depender de pipelines que **empurram** configuracoes para o cluster. Isso garante que o Git seja sempre a fonte da verdade.
- **Open source:** codigo aberto, mantido pela comunidade e por organizacoes que contribuem ativamente.

### Qual Problema o Argo CD Resolve

Sem o Argo CD, o fluxo tradicional de deploy envolve:

1. Desenvolvedor altera codigo ou configuracao
2. Pipeline de CI constroi imagem e gera artefatos
3. Pipeline de CD executa `kubectl apply` no cluster
4. Ninguem monitora se o cluster divergiu do Git depois

Esse modelo tem problemas serios:

- **Drift operacional:** alguem pode alterar o cluster manualmente e ninguem percebe
- **Falta de auditoria:** nao ha registro centralizado de quem aplicou o que
- **Dependencia de pipelines:** se a pipeline falha, o cluster fica desatualizado
- **Aplicacao manual:** em emergencias, equipes aplicam manifests diretamente, quebrando a consistencia

O Argo CD resolve todos esses problemas ao monitorar continuamente tanto o Git quanto o cluster, reconciliando divergencias automaticamente.

## Como o Argo CD Funciona

O Argo CD opera em um loop continuo de tres etapas:

1. **Observa o repositorio Git:** le os arquivos YAML que definem o estado desejado
2. **Observa o cluster Kubernetes:** verifica o estado atual dos recursos
3. **Compara e reconcilia:** detecta divergencias e aplica correcoes

### Fluxo de Reconciliacao

```
Desenvolvedor faz commit no Git
        |
        v
Argo CD detecta mudanca no repositorio
        |
        v
Argo CD compara: estado do Git vs estado do cluster
        |
        v
  [Divergencia?]
   /          \
  Sim          Nao
  |             |
  v             v
Reconcilia    Nenhuma
(aplica no    acao
 cluster)     necessaria
```

### Conceito de Drift (Out-of-Sync)

Quando o estado do cluster **diverge** do estado definido no Git, o Argo CD identifica essa situacao como **out-of-sync** (fora de sincronia). Essa divergencia pode ocorrer por dois motivos:

- **Mudanca no Git:** alguem fez um commit alterando um YAML -- o cluster ainda nao reflete a mudanca
- **Mudanca manual no cluster:** alguem executou um `kubectl edit` ou `kubectl apply` diretamente -- o cluster nao corresponde mais ao Git

Em ambos os casos, o Argo CD detecta o drift e pode reconciliar automaticamente, restaurando o estado definido no Git.

## Arquitetura do Argo CD

O diagrama abaixo mostra a arquitetura geral do Argo CD e como seus componentes interagem entre si:

```
+------------------------------------------------------------------+
|                     REPOSITORIO GIT                              |
|  (YAMLs: Deployments, Services, HPAs, ConfigMaps, etc.)         |
+----------------------------+-------------------------------------+
                             |
                    (clona / sincroniza)
                             |
                             v
+------------------------------------------------------------------+
|                    ARGO CD (namespace: argocd)                   |
|                                                                  |
|  +-------------------------+    +-----------------------------+  |
|  |   argocd-repo-server    |    |    argocd-dex-server        |  |
|  |                         |    |                             |  |
|  | - Clona repositorios    |    | - Autenticacao externa      |  |
|  | - Gera manifests        |    | - SSO (OIDC, SAML, LDAP)   |  |
|  | - Cache de repos        |    +-----------------------------+  |
|  +------------+------------+                                     |
|               |                                                  |
|               v                                                  |
|  +---------------------------+    +---------------------------+  |
|  | argocd-application-       |    |     argocd-server         |  |
|  |         controller        |    |                           |  |
|  |                           |    | - API REST / gRPC         |  |
|  | - Monitora Applications   |    | - Interface Web (UI)      |  |
|  | - Compara Git vs Cluster  |    | - Ponto de entrada CLI    |  |
|  | - Executa reconciliacao   |    +---------------------------+  |
|  +---------------------------+                                   |
|               |                    +---------------------------+ |
|               |                    |     argocd-redis          | |
|               |                    |                           | |
|               |                    | - Cache interno           | |
|               |                    | - Dados de sessao         | |
|               |                    +---------------------------+ |
|               |                                                  |
|               |                    +---------------------------+ |
|               |                    | argocd-applicationset-    | |
|               |                    |         controller        | |
|               |                    |                           | |
|               |                    | - Gera Applications       | |
|               |                    |   a partir de templates   | |
|               |                    +---------------------------+ |
+---------------+--------------------------------------------------+
                |
      (aplica manifests)
                |
                v
+------------------------------------------------------------------+
|                   CLUSTER KUBERNETES                             |
|                                                                  |
|  Namespace: app-exemplo                                          |
|  +------------------+  +------------------+  +----------------+  |
|  | Deployment       |  | Service          |  | HPA            |  |
|  | (demo-api)       |  | (demo-api-svc)   |  | (demo-api-hpa) |  |
|  +------------------+  +------------------+  +----------------+  |
+------------------------------------------------------------------+
```

## Componentes Principais

O Argo CD e composto por varios componentes que rodam como Pods dentro do namespace `argocd`. Cada um tem uma responsabilidade especifica.

### Tabela de Componentes

| Componente | Tipo | Funcao Principal |
|---|---|---|
| `argocd-server` | Deployment | Expoe a API REST/gRPC e a interface web (UI). Ponto de entrada para CLI e navegador. |
| `argocd-repo-server` | Deployment | Clona e sincroniza repositorios Git. Gera manifests finais a partir de Helm, Kustomize ou YAML puro. |
| `argocd-application-controller` | StatefulSet | Coracao do Argo CD. Monitora as Applications, compara o estado Git vs cluster e executa a reconciliacao. |
| `argocd-redis` | Deployment | Cache interno usado pelo server e pelo controller para melhorar performance e armazenar dados de sessao. |
| `argocd-dex-server` | Deployment | Servidor de autenticacao externa. Integra com provedores SSO como OIDC, SAML e LDAP. |
| `argocd-applicationset-controller` | Deployment | Gera multiplas Applications automaticamente a partir de templates (ApplicationSets). Util para multi-cluster e multi-tenant. |

### Detalhamento de Cada Componente

#### argocd-server

O `argocd-server` e o ponto de entrada do Argo CD. Ele expoe:

- **API REST e gRPC:** permite que o CLI (`argocd`) e outras ferramentas interajam com o Argo CD
- **Interface Web (UI):** dashboard visual para acompanhar o estado das Applications, visualizar recursos e diagnosticar problemas
- **Webhook endpoints:** recebe notificacoes de mudancas no Git (opcional, para sincronizacao mais rapida)

No acesso local, geralmente usa-se `kubectl port-forward` para alcanca-lo:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### argocd-repo-server

O `argocd-repo-server` e responsavel por toda a interacao com repositorios Git:

- Clona repositorios configurados
- Faz pull periodico para detectar mudancas
- Renderiza manifests finais (resolve templates Helm, aplica Kustomize overlays, ou simplesmente le YAMLs puros)
- Mantém cache local dos repositorios para evitar clonagens repetidas

Esse componente **nunca** acessa o cluster diretamente. Ele apenas gera os manifests que serao comparados pelo controller.

#### argocd-application-controller

O `argocd-application-controller` e o **coracao** do Argo CD. Suas responsabilidades:

- Monitora todos os recursos do tipo `Application` no cluster
- Solicita ao `repo-server` os manifests desejados (do Git)
- Consulta a API do Kubernetes para obter o estado atual
- Compara os dois estados e determina se ha **drift**
- Executa a **reconciliacao** quando necessario (aplica, atualiza ou remove recursos)

Esse componente roda como **StatefulSet** para garantir consistencia no processamento.

#### argocd-redis

O `argocd-redis` e uma instancia Redis usada internamente como cache:

- Armazena dados de sessao da UI
- Faz cache de resultados de operacoes frequentes
- Melhora a performance do `argocd-server` e do controller
- Nao armazena dados persistentes criticos (pode ser recriado sem perda)

#### argocd-dex-server

O `argocd-dex-server` e o componente de autenticacao:

- Implementa o protocolo OpenID Connect (OIDC)
- Permite integracao com provedores de identidade externos (Google, GitHub, LDAP, SAML)
- Em ambientes locais/didaticos, geralmente usa-se a autenticacao interna (usuario `admin` com senha gerada)
- Em producao, e recomendado configurar SSO via Dex

#### argocd-applicationset-controller

O `argocd-applicationset-controller` automatiza a criacao de Applications:

- Le recursos do tipo `ApplicationSet`
- Gera multiplas `Application` a partir de templates e geradores
- Util para cenarios como:
  - **Multi-cluster:** criar a mesma aplicacao em varios clusters
  - **Multi-tenant:** gerar Applications para diferentes equipes
  - **Mono-repo:** criar uma Application por diretorio no repositorio

## CRD e Controller Pattern

O Argo CD segue o padrao nativo do Kubernetes de **CRDs** (Custom Resource Definitions) e **Controllers**.

### O que e um CRD

Um CRD (Custom Resource Definition) e uma forma de estender a API do Kubernetes com novos tipos de recursos. Em vez de trabalhar apenas com Pods, Services e Deployments, voce pode definir recursos personalizados.

O Argo CD registra CRDs como:

- `Application`
- `ApplicationSet`
- `AppProject`

Isso significa que voce pode gerenciar esses recursos com `kubectl`, exatamente como faria com qualquer recurso nativo:

```bash
# Listar Applications do Argo CD
kubectl get applications -n argocd

# Descrever uma Application especifica
kubectl describe application minha-app -n argocd

# Aplicar uma Application via YAML
kubectl apply -f application.yaml
```

### O que e o Controller Pattern

O padrao Controller e o modelo fundamental do Kubernetes:

1. Um **recurso** define o estado desejado (ex: "quero 3 replicas")
2. Um **controller** observa esse recurso continuamente
3. O controller compara o estado desejado com o estado atual
4. Se houver divergencia, o controller age para convergir

O Argo CD aplica exatamente esse padrao:

- O recurso `Application` define: "quero que o diretorio X do repositorio Y esteja aplicado no namespace Z"
- O `argocd-application-controller` observa esse recurso
- Se o cluster divergir do Git, o controller reconcilia

```
+---------------------+       +---------------------------+
|  Application (CRD)  | ----> | application-controller    |
|                     |       |                           |
| Estado desejado:    |       | 1. Le o Application       |
| - Repo: git@...     |       | 2. Busca manifests (Git)  |
| - Path: /manifests  |       | 3. Compara com cluster    |
| - Namespace: app    |       | 4. Reconcilia se preciso  |
+---------------------+       +---------------------------+
```

## Conceitos Operacionais

O Argo CD utiliza tres conceitos operacionais fundamentais para organizar e gerenciar deployments.

### Application

Uma `Application` e o recurso principal do Argo CD. Ela define:

- **Fonte (source):** repositorio Git, branch e path onde estao os YAMLs
- **Destino (destination):** cluster e namespace onde os recursos devem ser aplicados
- **Politica de sincronizacao:** manual ou automatica
- **Projeto:** a qual AppProject pertence

Exemplo conceitual:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-api
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git@github.com:usuario/repo.git
    targetRevision: main
    path: k8s/manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### ApplicationSet

Um `ApplicationSet` e um recurso que **gera** multiplas Applications automaticamente. Ele usa geradores (generators) para criar variantes a partir de templates.

Casos de uso comuns:

- Criar a mesma aplicacao em 3 clusters diferentes
- Gerar uma Application por diretorio dentro de um mono-repo
- Criar Applications dinamicamente baseadas em uma lista

### AppProject

Um `AppProject` e um recurso de organizacao que agrupa Applications e define permissoes:

- Quais repositorios Git podem ser usados
- Quais clusters de destino sao permitidos
- Quais namespaces podem ser acessados
- Quais recursos Kubernetes podem ser criados

O Argo CD cria automaticamente um projeto `default` que permite qualquer fonte e destino. Em producao, e recomendado criar projetos especificos com restricoes.

## Modos de Sincronizacao

O Argo CD oferece dois modos de sincronizacao, que definem como ele reage ao detectar divergencia entre Git e cluster.

### Sincronizacao Manual

No modo manual, o Argo CD:

1. Detecta que o Git e o cluster estao diferentes (drift)
2. Marca a Application como **out-of-sync**
3. Notifica o usuario (via UI, CLI ou webhook)
4. **Aguarda** uma acao explicita do usuario para sincronizar

Quando usar:

- Ambientes de producao com aprovacao obrigatoria
- Situacoes onde e necessario revisar antes de aplicar
- Equipes que ainda estao adotando GitOps gradualmente

### Sincronizacao Automatica

No modo automatico (recomendado como padrao), o Argo CD:

1. Detecta que o Git e o cluster estao diferentes (drift)
2. **Aplica automaticamente** o estado do Git no cluster
3. Marca a Application como **synced** (em sincronia)

Opcoes adicionais do modo automatico:

- **Prune (poda):** remove recursos do cluster que nao existem mais no Git
- **Self-Heal (auto-reparo):** reverte mudancas manuais feitas diretamente no cluster

```yaml
syncPolicy:
  automated:
    prune: true      # Remove recursos orfaos
    selfHeal: true    # Reverte mudancas manuais
```

### Comparacao entre os Modos

| Aspecto | Manual | Automatico |
|---|---|---|
| Deteccao de drift | Sim | Sim |
| Acao automatica | Nao | Sim |
| Requer intervencao humana | Sim | Nao |
| Recomendado para | Producao com aprovacao | Maioria dos ambientes |
| Risco de mudancas nao revisadas | Nenhum | Possivel (mitigado por Git review) |

## O que o Argo CD Observa vs Nao Observa

Esse e um ponto fundamental para entender os limites do Argo CD. Ele **nao** e uma ferramenta de CI (Continuous Integration) -- ele so se preocupa com o **estado declarativo** dos recursos Kubernetes.

### O que o Argo CD OBSERVA

O Argo CD monitora arquivos YAML no repositorio Git que definem recursos Kubernetes:

- **Deployments:** definicoes de pods, replicas, imagens
- **Services:** exposicao de rede dos pods
- **HPAs (Horizontal Pod Autoscalers):** regras de auto-scaling
- **ConfigMaps e Secrets:** configuracoes e dados sensiveis
- **Qualquer recurso Kubernetes definido em YAML:** Ingress, PVCs, NetworkPolicies, CRDs customizados, etc.

Quando qualquer um desses arquivos muda no Git (novo commit), o Argo CD detecta e reconcilia.

### O que o Argo CD NAO OBSERVA

O Argo CD **nao** monitora:

- **Mudancas no codigo-fonte da aplicacao:** alterar um arquivo `.js`, `.go` ou `.py` nao gera nenhuma acao no Argo CD
- **Build de imagens Docker:** o processo de CI (construir e publicar imagens) esta fora do escopo
- **Testes automatizados:** o Argo CD nao executa testes
- **Pipelines de CI:** ferramentas como GitHub Actions ou Jenkins cuidam dessa parte

### Quando uma Mudanca de Codigo Chega ao Argo CD

Uma mudanca de codigo so e percebida pelo Argo CD quando **gera um novo YAML** no repositorio. O fluxo completo e:

```
1. Desenvolvedor altera codigo
2. CI constroi nova imagem (ex: demo-api:v2)
3. CI atualiza o YAML no Git (image: demo-api:v2)
4. Argo CD detecta a mudanca no YAML
5. Argo CD aplica o novo Deployment no cluster
```

Perceba que as etapas 1 a 3 sao responsabilidade do **CI**. O Argo CD so entra na etapa 4, quando o YAML muda.

## Relacao com Argo Rollouts

O **Argo Rollouts** e outro projeto do Argo, complementar ao Argo CD. Enquanto o Argo CD cuida da **sincronizacao** (garantir que o cluster reflita o Git), o Argo Rollouts cuida da **estrategia de deploy** (como a mudanca e aplicada gradualmente).

### Argo CD vs Argo Rollouts

| Aspecto | Argo CD | Argo Rollouts |
|---|---|---|
| Responsabilidade | Sincronizar Git com cluster | Controlar como o deploy acontece |
| Foco | Estado desejado | Estrategia de transicao |
| Estrategias | N/A (aplica direto) | Blue-Green, Canary |
| Recurso principal | Application | Rollout |

### Estrategias do Argo Rollouts (Mencao Conceitual)

- **Blue-Green:** mantem duas versoes simultaneas (blue = atual, green = nova). Apos validacao, o trafego e redirecionado para green.
- **Canary:** redireciona uma porcentagem pequena do trafego para a nova versao. Se tudo correr bem, aumenta gradualmente ate 100%.

### Uso Combinado

Em producao, e comum usar os dois juntos:

- **Argo CD** sincroniza o recurso `Rollout` do Git para o cluster
- **Argo Rollouts** controla como essa mudanca e aplicada (ex: 10% do trafego por 5 minutos, depois 50%, depois 100%)

Essa separacao de responsabilidades e uma das forcas do ecossistema Argo.

## Interface Grafica (UI)

O Argo CD oferece uma interface web acessivel atraves do `argocd-server`. A UI e util para:

- **Visualizacao:** ver o estado de todas as Applications, seus recursos e dependencias
- **Auditoria:** acompanhar historico de sincronizacoes e eventos
- **Estudo:** entender como o Argo CD organiza e gerencia recursos
- **Diagnostico:** identificar erros de sincronizacao e recursos faltantes

### Importante: UI Nao e Fonte de Configuracao

A interface web permite criar e editar Applications, mas isso **nao e recomendado**. No modelo GitOps:

- Toda configuracao deve estar **versionada no Git**
- Mudancas feitas pela UI sao imperativas (nao ficam registradas no Git)
- O Argo CD pode ate reverter mudancas feitas pela UI se o self-heal estiver ativo

Use a UI para **visualizar e aprender**, mas configure tudo via **YAML no Git**.

## Resumo

Os pontos principais abordados neste documento:

1. **Argo CD** e um projeto open source do Argo Project, criado para Continuous Delivery declarativa em Kubernetes.

2. **Funcionamento:** o Argo CD observa o repositorio Git e o cluster Kubernetes simultaneamente. Quando detecta divergencia (drift/out-of-sync), executa a reconciliacao.

3. **Componentes:** o Argo CD e composto por seis componentes principais -- server, repo-server, application-controller, redis, dex-server e applicationset-controller -- cada um com responsabilidade bem definida.

4. **CRD e Controller:** o Argo CD estende a API do Kubernetes com CRDs (Application, ApplicationSet, AppProject) e usa controllers para manter o estado desejado.

5. **Modos de sincronizacao:** manual (aguarda acao do usuario) ou automatico (aplica imediatamente). O automatico e recomendado como padrao.

6. **Limites:** o Argo CD observa apenas YAMLs de recursos Kubernetes. Mudancas no codigo-fonte so importam se gerarem novos YAMLs.

7. **Argo Rollouts:** complementa o Argo CD com estrategias de deploy progressivo (blue-green, canary). Sao projetos diferentes com responsabilidades diferentes.

8. **UI:** util para visualizacao e estudo, mas nao deve ser usada como fonte de configuracao. Git e a unica fonte da verdade.

## Referencias

- [Argo CD - Documentacao Oficial](https://argo-cd.readthedocs.io/en/stable/)
- [Argo Project - GitHub](https://github.com/argoproj)
- [Argo CD - Architectural Overview](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/)
- [CNCF - Argo Project](https://www.cncf.io/projects/argo/)
- [Argo Rollouts - Documentacao Oficial](https://argo-rollouts.readthedocs.io/en/stable/)
- [Kubernetes - Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
