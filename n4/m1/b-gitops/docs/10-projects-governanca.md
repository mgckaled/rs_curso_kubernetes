<!-- markdownlint-disable -->

# Projects e Governanca no Argo CD - Aula 11

Documentacao sobre AppProjects como camada de governanca no
Argo CD, cobrindo o CRD AppProject, restricoes de repositorios
e clusters, RBAC com Roles e Policies, Sync Windows para controle
temporal de deploys, organizacao de repositorios e a transicao
para Helm.

---

## Indice

1. [AppProject como Camada de Governanca](#appproject-como-camada-de-governanca)
2. [Project "default" vs Projects Customizados](#project-default-vs-projects-customizados)
3. [Campos do AppProject CRD](#campos-do-appproject-crd)
4. [Roles e Policies (RBAC do Argo CD)](#roles-e-policies-rbac-do-argo-cd)
5. [Sync Windows (Janelas de Sincronizacao)](#sync-windows-janelas-de-sincronizacao)
6. [Organizacao de Repositorios](#organizacao-de-repositorios)
7. [Transicao para Helm](#transicao-para-helm)
8. [Tabela Resumo dos Controles de Governanca](#tabela-resumo-dos-controles-de-governanca)
9. [Resumo](#resumo)
10. [Referencias](#referencias)

---

## AppProject como Camada de Governanca

O **AppProject** (ou simplesmente Project) e um CRD do Argo CD
que funciona como uma **camada de governanca** sobre as
Applications. Ele define quais repositorios, clusters, namespaces
e tipos de recursos cada grupo de Applications pode utilizar.

Sem Projects customizados, qualquer Application pode acessar
qualquer repositorio e fazer deploy em qualquer namespace de
qualquer cluster registrado. Em ambientes reais com multiplas
equipes, isso representa um risco de seguranca e de organizacao.

### Analogia

Pense no AppProject como uma **politica de acesso** que responde
as seguintes perguntas:

- **De onde** pode vir o codigo? (quais repositorios Git)
- **Para onde** pode ir o deploy? (quais clusters e namespaces)
- **O que** pode ser criado? (quais tipos de recursos Kubernetes)
- **Quem** pode operar? (quais roles e permissoes)
- **Quando** pode sincronizar? (janelas de tempo permitidas)

### Hierarquia

```
AppProject (governanca)
  |
  |-- Define restricoes de repositorios (sourceRepos)
  |-- Define restricoes de destinos (destinations)
  |-- Define restricoes de recursos (whitelist/blacklist)
  |-- Define roles e policies (RBAC)
  |-- Define sync windows (janelas temporais)
  |
  +-- Application A (pertence a este project)
  +-- Application B (pertence a este project)
  +-- ApplicationSet C (pertence a este project)
```

---

## Project "default" vs Projects Customizados

### Project "default"

O Argo CD cria automaticamente um project chamado `default` durante
a instalacao. Esse project **nao possui restricoes**: qualquer
repositorio, qualquer cluster, qualquer namespace e qualquer tipo
de recurso sao permitidos.

```yaml
# O project "default" criado automaticamente pelo Argo CD
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  # Permite qualquer repositorio como fonte
  sourceRepos:
    - '*'
  # Permite deploy em qualquer cluster e namespace
  destinations:
    - namespace: '*'
      server: '*'
  # Permite qualquer recurso em nivel de cluster
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```

### Quando o "default" e adequado

| Cenario | Adequado? |
|---------|-----------|
| Estudo e aprendizado | Sim - sem restricoes facilita experimentacao |
| Equipe unica com poucos repositorios | Sim - overhead de governanca nao compensa |
| Ambiente de desenvolvimento local | Sim - nao ha risco real |
| Producao com multiplas equipes | Nao - falta de isolamento e perigosa |
| Ambiente regulado (compliance) | Nao - exige controles de acesso |

### Projects customizados

Em ambientes reais, e recomendado criar Projects especificos para
cada equipe, aplicacao ou dominio de negocio, cada um com suas
proprias restricoes.

```
Argo CD
  |
  +-- Project: "team-backend"
  |     |-- sourceRepos: github.com/org/backend-*
  |     |-- destinations: cluster-prod/ns-backend
  |     +-- Applications: api-users, api-orders, api-payments
  |
  +-- Project: "team-frontend"
  |     |-- sourceRepos: github.com/org/frontend-*
  |     |-- destinations: cluster-prod/ns-frontend
  |     +-- Applications: web-app, admin-panel
  |
  +-- Project: "team-infra"
        |-- sourceRepos: github.com/org/infra-*
        |-- destinations: cluster-prod/*
        +-- Applications: monitoring, logging, ingress
```

---

## Campos do AppProject CRD

O CRD AppProject possui diversos campos para controlar o que
cada grupo de Applications pode fazer. Abaixo, os campos mais
importantes com exemplos detalhados.

### sourceRepos

Define **quais repositorios Git** as Applications deste project
podem usar como fonte de manifests.

```yaml
spec:
  sourceRepos:
    # Opcao 1: permitir QUALQUER repositorio (sem restricao)
    - '*'

    # Opcao 2: listar repositorios especificos
    - https://github.com/minha-org/repo-backend.git
    - https://github.com/minha-org/repo-infra.git

    # Opcao 3: usar wildcards por organizacao
    # Permite qualquer repositorio da organizacao "minha-org"
    - 'https://github.com/minha-org/*'
```

Se uma Application pertencente a este project tentar usar um
repositorio que **nao esta listado** em `sourceRepos`, o Argo CD
**rejeita** a criacao da Application.

### destinations

Define **quais clusters e namespaces** as Applications deste
project podem usar como destino de deploy.

```yaml
spec:
  destinations:
    # Opcao 1: permitir QUALQUER cluster e namespace
    - namespace: '*'
      server: '*'

    # Opcao 2: restringir a namespaces especificos no cluster local
    - namespace: app-backend
      server: https://kubernetes.default.svc
    - namespace: app-backend-staging
      server: https://kubernetes.default.svc

    # Opcao 3: restringir a um cluster externo e namespaces especificos
    - namespace: producao
      server: https://172.18.0.3:6443
    - namespace: staging
      server: https://172.18.0.3:6443

    # Opcao 4: usar wildcard no namespace (qualquer namespace no cluster)
    - namespace: '*'
      server: https://172.18.0.3:6443
```

Se uma Application tentar fazer deploy em um cluster ou namespace
**nao listado**, o Argo CD **rejeita** a operacao.

### clusterResourceWhitelist

Define **quais recursos de nivel de cluster** as Applications
deste project podem criar. Recursos de nivel de cluster sao
aqueles que nao pertencem a um namespace (ex: Namespace,
ClusterRole, ClusterRoleBinding, PersistentVolume).

```yaml
spec:
  clusterResourceWhitelist:
    # Permitir TODOS os recursos de cluster
    - group: '*'
      kind: '*'

    # Ou restringir a tipos especificos
    - group: ''
      kind: Namespace
    - group: rbac.authorization.k8s.io
      kind: ClusterRole
    - group: rbac.authorization.k8s.io
      kind: ClusterRoleBinding
```

### clusterResourceBlacklist

Define quais recursos de nivel de cluster sao **proibidos**
(blacklist tem precedencia sobre whitelist).

```yaml
spec:
  clusterResourceBlacklist:
    # Proibir criacao de ClusterRoles (seguranca)
    - group: rbac.authorization.k8s.io
      kind: ClusterRole
    - group: rbac.authorization.k8s.io
      kind: ClusterRoleBinding
```

### namespaceResourceWhitelist

Define quais recursos **dentro de namespaces** as Applications
podem criar.

```yaml
spec:
  namespaceResourceWhitelist:
    # Permitir apenas Deployments, Services e ConfigMaps
    - group: apps
      kind: Deployment
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
```

Se nao definido, todos os recursos de namespace sao permitidos
por padrao.

### namespaceResourceBlacklist

Define quais recursos dentro de namespaces sao **proibidos**.

```yaml
spec:
  namespaceResourceBlacklist:
    # Proibir criacao de Secrets via Argo CD
    # (Secrets devem ser gerenciados por outra ferramenta)
    - group: ''
      kind: Secret
```

### Exemplo completo do AppProject

```yaml
# Recurso AppProject do Argo CD
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  # Nome do project (referenciado pelas Applications)
  name: team-backend
  # Namespace do Argo CD
  namespace: argocd
spec:
  # Descricao do project (informativo)
  description: "Project para a equipe de backend"

  # Repositorios permitidos como fonte de manifests
  sourceRepos:
    # Qualquer repositorio da organizacao que comece com "backend-"
    - 'https://github.com/minha-org/backend-*'
    # Repositorio de configuracao compartilhada
    - 'https://github.com/minha-org/shared-config.git'

  # Clusters e namespaces permitidos como destino de deploy
  destinations:
    # Namespace de backend no cluster local
    - namespace: backend
      server: https://kubernetes.default.svc
    # Namespace de backend-staging no cluster local
    - namespace: backend-staging
      server: https://kubernetes.default.svc

  # Recursos de nivel de cluster permitidos
  clusterResourceWhitelist:
    # Apenas Namespaces (nao pode criar ClusterRoles, etc.)
    - group: ''
      kind: Namespace

  # Recursos de namespace proibidos
  namespaceResourceBlacklist:
    # Secrets devem ser gerenciados por External Secrets ou Vault
    - group: ''
      kind: Secret
```

---

## Roles e Policies (RBAC do Argo CD)

O Argo CD possui seu proprio sistema de RBAC (Role-Based Access
Control) que funciona **dentro do Argo CD**, independente do RBAC
do Kubernetes. Ele controla quem pode fazer o que com as
Applications e Projects do Argo CD.

### Formato das Policies

As policies seguem o formato **Casbin** (biblioteca de controle
de acesso):

```
p, <subject>, <resource>, <action>, <object>, <effect>
```

| Campo | Descricao | Exemplos |
|-------|-----------|----------|
| `p` | Indicador de policy | Sempre `p` |
| `subject` | Quem (usuario, grupo ou role) | `role:team-backend-readonly`, `grupo:devs` |
| `resource` | Tipo de recurso do Argo CD | `applications`, `clusters`, `repositories`, `projects` |
| `action` | Acao permitida ou negada | `get`, `create`, `update`, `delete`, `sync`, `override`, `*` |
| `object` | Escopo (project/application) | `team-backend/*`, `default/demo-app` |
| `effect` | Permitir ou negar | `allow`, `deny` |

### Exemplo: Role read-only para desenvolvedores

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-backend
  namespace: argocd
spec:
  # ... (sourceRepos, destinations, etc.)

  roles:
    # Role de somente leitura para desenvolvedores
    - name: readonly
      description: "Acesso somente leitura para desenvolvedores"
      policies:
        # Pode visualizar (get) qualquer Application deste project
        - p, proj:team-backend:readonly, applications, get, team-backend/*, allow
      groups:
        # Grupo OIDC/SSO que sera vinculado a esta role
        - dev-team
```

### Exemplo: Role de sync para DevOps

```yaml
  roles:
    # Role de leitura (devs)
    - name: readonly
      description: "Acesso somente leitura para desenvolvedores"
      policies:
        - p, proj:team-backend:readonly, applications, get, team-backend/*, allow

    # Role de operacao (devops)
    - name: devops
      description: "Acesso de sync e leitura para equipe DevOps"
      policies:
        # Pode visualizar Applications
        - p, proj:team-backend:devops, applications, get, team-backend/*, allow
        # Pode sincronizar Applications (trigger manual de sync)
        - p, proj:team-backend:devops, applications, sync, team-backend/*, allow
        # Pode ver detalhes de acoes (logs, eventos)
        - p, proj:team-backend:devops, applications, action/*, team-backend/*, allow
      groups:
        # Grupo OIDC/SSO da equipe DevOps
        - devops-team
```

### Tabela de acoes disponiveis

| Acao | Descricao |
|------|-----------|
| `get` | Visualizar (listar, descrever, ver detalhes) |
| `create` | Criar novas Applications |
| `update` | Atualizar Applications existentes |
| `delete` | Deletar Applications |
| `sync` | Disparar sincronizacao manual |
| `override` | Sobrescrever parametros da Application |
| `action/*` | Executar acoes customizadas (restart, logs) |
| `*` | Todas as acoes (acesso completo) |

### Integracao com OIDC/SSO (conceitual)

Em ambientes de producao, o Argo CD se integra com provedores de
identidade externos via **OIDC** (OpenID Connect) ou **SSO**
(Single Sign-On). O componente `argocd-dex-server` e responsavel
por essa integracao.

```
Fluxo de autenticacao:
  Usuario --> Argo CD UI --> Dex Server --> Provedor OIDC
                                            (Google, Okta,
                                             Azure AD, GitHub)
                                                |
                                                v
                                           Retorna grupos
                                           do usuario
                                                |
                                                v
                                           Argo CD mapeia
                                           grupos para roles
                                           dos Projects
```

Provedores suportados:

| Provedor | Protocolo | Uso tipico |
|----------|-----------|-----------|
| Google Workspace | OIDC | Empresas que usam G Suite |
| Azure Active Directory | OIDC/SAML | Empresas que usam Microsoft 365 |
| Okta | OIDC/SAML | Gestao de identidade corporativa |
| GitHub | OAuth2 | Equipes que ja usam GitHub |
| GitLab | OAuth2 | Equipes que usam GitLab |
| LDAP | LDAP | Ambientes on-premise tradicionais |

A configuracao detalhada de OIDC/SSO foge do escopo desta aula,
mas o conceito importante e: **os grupos do provedor de identidade
sao mapeados para roles dos AppProjects**, criando um controle
de acesso centralizado e automatizado.

---

## Sync Windows (Janelas de Sincronizacao)

As **Sync Windows** permitem controlar **quando** as
sincronizacoes podem ocorrer. Isso e util em ambientes de
producao onde deploys devem acontecer apenas em horarios
especificos (ex: horario comercial, fora de picos de trafego).

### Conceito

Uma Sync Window define:

- **Tipo:** permitir (`allow`) ou negar (`deny`) sincronizacoes
- **Agenda:** expressao cron que define quando a janela esta ativa
- **Duracao:** por quanto tempo a janela fica aberta
- **Filtros:** quais Applications, namespaces ou clusters sao
  afetados

### Formato da Sync Window

```yaml
spec:
  syncWindows:
    # Janela que PERMITE sync apenas em horario comercial
    - kind: allow
      # Expressao cron: minuto hora dia-mes mes dia-semana
      # "0 8 * * 1-5" = as 08:00, de segunda a sexta
      schedule: '0 8 * * 1-5'
      # Duracao: 10 horas (08:00 ate 18:00)
      duration: 10h
      # Filtrar por Applications (wildcard = todas)
      applications:
        - '*'
      # Filtrar por namespaces (opcional)
      namespaces:
        - 'producao'
      # Filtrar por clusters (opcional)
      clusters:
        - 'https://kubernetes.default.svc'
```

### Exemplo: permitir deploy apenas em horario comercial

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-backend
  namespace: argocd
spec:
  # ... (sourceRepos, destinations, etc.)

  syncWindows:
    # Janela 1: permitir sync de segunda a sexta, 08h-18h
    - kind: allow
      # Cron: as 08:00 de segunda (1) a sexta (5)
      schedule: '0 8 * * 1-5'
      # Duracao de 10 horas (fecha as 18:00)
      duration: 10h
      applications:
        - '*'

    # Janela 2: negar sync em feriados/manutencao
    - kind: deny
      # Cron: todo dia 25 de dezembro, meia-noite
      schedule: '0 0 25 12 *'
      # Duracao de 24 horas (dia inteiro bloqueado)
      duration: 24h
      applications:
        - '*'
```

### Comportamento das janelas

| Tipo | Efeito |
|------|--------|
| `allow` | Sincronizacao **so pode ocorrer** durante o periodo definido |
| `deny` | Sincronizacao **nao pode ocorrer** durante o periodo definido |

### Precedencia

- Se existirem multiplas janelas, `deny` tem **precedencia** sobre
  `allow`
- Se nao houver nenhuma janela definida, sync e permitido a
  qualquer momento (comportamento padrao)
- Se uma janela `allow` existir, sync so e permitido dentro dela.
  Fora da janela, sync e bloqueado automaticamente

### Expressoes cron comuns

| Expressao | Significado |
|-----------|-------------|
| `0 8 * * 1-5` | Todos os dias uteis as 08:00 |
| `0 0 * * 0` | Todo domingo a meia-noite |
| `0 22 * * *` | Todos os dias as 22:00 |
| `0 0 1 * *` | Primeiro dia de cada mes a meia-noite |
| `0 0 25 12 *` | Dia 25 de dezembro a meia-noite |

### Formato da expressao cron

```
┌───────────── minuto (0 - 59)
│ ┌───────────── hora (0 - 23)
│ │ ┌───────────── dia do mes (1 - 31)
│ │ │ ┌───────────── mes (1 - 12)
│ │ │ │ ┌───────────── dia da semana (0 - 6, 0 = domingo)
│ │ │ │ │
* * * * *
```

---

## Organizacao de Repositorios

Uma pratica recomendada no GitOps e **separar os repositorios de
configuracao dos repositorios de aplicacao**. Isso facilita a
governanca, o controle de acesso e a evolucao independente de
cada parte.

### Modelo recomendado

```
github.com/minha-org/
  |
  |-- app-backend/           (codigo-fonte da aplicacao)
  |     |-- src/
  |     |-- Dockerfile
  |     |-- package.json
  |     +-- .github/workflows/ci.yaml   (pipeline de CI)
  |
  |-- app-frontend/          (codigo-fonte da aplicacao)
  |     |-- src/
  |     |-- Dockerfile
  |     +-- .github/workflows/ci.yaml
  |
  |-- gitops-config/         (configuracoes Kubernetes)
        |-- apps/
        |     |-- backend/
        |     |     |-- deployment.yaml
        |     |     |-- service.yaml
        |     |     +-- hpa.yaml
        |     |-- frontend/
        |     |     |-- deployment.yaml
        |     |     +-- service.yaml
        |     +-- shared/
        |           +-- configmap.yaml
        |
        |-- argocd/
        |     |-- applications/
        |     |     |-- app-backend.yaml
        |     |     +-- app-frontend.yaml
        |     +-- projects/
        |           |-- team-backend.yaml
        |           +-- team-frontend.yaml
        |
        +-- clusters/
              |-- dev/
              +-- prod/
```

### Beneficios da separacao

| Beneficio | Descricao |
|-----------|-----------|
| **Isolamento de acesso** | Devs acessam o repo de codigo, ops acessam o repo de config |
| **Ciclos independentes** | Codigo pode ser alterado sem afetar configuracao e vice-versa |
| **Auditoria clara** | Mudancas de infra ficam separadas de mudancas de codigo |
| **Controle de merge** | Diferentes regras de aprovacao para cada repositorio |
| **Reutilizacao** | Configuracoes podem ser compartilhadas entre aplicacoes |

---

## Transicao para Helm

Conforme o numero de microservicos e ambientes cresce, gerenciar
dezenas ou centenas de arquivos YAML individuais se torna
insustentavel. O **Helm** e a ferramenta padrao do ecossistema
Kubernetes para resolver esse problema.

### Por que muitos YAMLs nao escalam

| Problema | Descricao |
|----------|-----------|
| **Duplicacao** | Deployments de microservicos diferentes sao 90% identicos |
| **Manutencao** | Alterar um padrao (ex: adicionar label) exige editar N arquivos |
| **Variacoes por ambiente** | Dev usa 1 replica, staging usa 2, prod usa 5 - como gerenciar? |
| **Erro humano** | Com 50 arquivos, e facil esquecer de atualizar um |
| **Onboarding** | Novos membros da equipe precisam entender dezenas de YAMLs |

### Como Helm resolve

O Helm introduz o conceito de **charts** (pacotes de templates):

- **Templates:** YAMLs com variaveis (similar ao ApplicationSet,
  mas para recursos Kubernetes individuais)
- **Values:** arquivo de valores que parametriza os templates
  (replicas, imagem, portas, etc.)
- **Releases:** instancias de um chart com valores especificos
  para cada ambiente

```
Sem Helm:
  deployment-dev.yaml     (replicas: 1, image: v1.0)
  deployment-staging.yaml (replicas: 2, image: v1.0)
  deployment-prod.yaml    (replicas: 5, image: v1.0)

Com Helm:
  templates/deployment.yaml     (replicas: {{.Values.replicas}})
  values-dev.yaml               (replicas: 1)
  values-staging.yaml           (replicas: 2)
  values-prod.yaml              (replicas: 5)
```

### Argo CD e Helm

O Argo CD tem **suporte nativo a Helm**. Quando uma Application
aponta para um chart Helm, o componente `argocd-repo-server`
renderiza os templates com os values especificados e gera os
manifests finais. O fluxo de reconciliacao continua o mesmo.

```yaml
# Application usando Helm como source
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app-helm
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/minha-org/gitops-config.git
    targetRevision: main
    path: charts/demo-app
    helm:
      # Arquivo de values especifico para o ambiente
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: producao
```

### Quando migrar para Helm

| Cenario | Recomendacao |
|---------|-------------|
| 1-3 microservicos, 1 ambiente | YAML puro e suficiente |
| 3-10 microservicos, 2+ ambientes | Considerar Helm |
| 10+ microservicos, 3+ ambientes | Helm fortemente recomendado |
| Templates compartilhados entre equipes | Helm e essencial |

---

## Tabela Resumo dos Controles de Governanca

| Controle | Campo/Recurso | O que controla | Exemplo |
|----------|---------------|----------------|---------|
| **Repositorios permitidos** | `sourceRepos` | De onde pode vir o codigo | `https://github.com/org/*` |
| **Destinos permitidos** | `destinations` | Para onde pode ir o deploy | `cluster-prod` + `namespace: backend` |
| **Recursos de cluster permitidos** | `clusterResourceWhitelist` | Quais recursos globais podem ser criados | Namespaces, ClusterRoles |
| **Recursos de cluster proibidos** | `clusterResourceBlacklist` | Quais recursos globais sao bloqueados | PersistentVolumes, ClusterRoleBindings |
| **Recursos de namespace permitidos** | `namespaceResourceWhitelist` | Quais recursos locais podem ser criados | Deployments, Services |
| **Recursos de namespace proibidos** | `namespaceResourceBlacklist` | Quais recursos locais sao bloqueados | Secrets (gerenciados externamente) |
| **Roles e Policies** | `roles[].policies` | Quem pode fazer o que | Devs: read-only, DevOps: sync |
| **Sync Windows** | `syncWindows` | Quando sync pode ocorrer | Segunda a sexta, 08h-18h |
| **Organizacao de repos** | Pratica recomendada | Separar config de codigo | Repo de app separado de repo GitOps |

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **AppProject** | CRD de governanca que agrupa e restringe Applications |
| **Project default** | Criado automaticamente, sem restricoes (adequado para estudo) |
| **sourceRepos** | Controla quais repositorios Git sao permitidos (wildcards aceitos) |
| **destinations** | Controla quais clusters e namespaces sao permitidos como destino |
| **clusterResourceWhitelist** | Lista de recursos de nivel de cluster permitidos |
| **clusterResourceBlacklist** | Lista de recursos de nivel de cluster proibidos |
| **namespaceResourceWhitelist** | Lista de recursos de namespace permitidos |
| **namespaceResourceBlacklist** | Lista de recursos de namespace proibidos |
| **Roles e Policies** | RBAC interno do Argo CD (formato Casbin: p, subject, resource, action, object, effect) |
| **Sync Windows** | Janelas temporais que controlam quando sync e permitido ou bloqueado |
| **Organizacao de repos** | Separar repositorios de codigo de repositorios de configuracao GitOps |
| **Helm** | Ferramenta de templates que resolve o problema de escala com muitos YAMLs |

---

## Referencias

- [Argo CD - Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [Argo CD - RBAC Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Argo CD - Sync Windows](https://argo-cd.readthedocs.io/en/stable/user-guide/sync_windows/)
- [Argo CD - Helm](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [Argo CD - Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- [Casbin - Policy Syntax](https://casbin.org/docs/syntax-for-models/)
- [Helm - Documentation](https://helm.sh/docs/)
