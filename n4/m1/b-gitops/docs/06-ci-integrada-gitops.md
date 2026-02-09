<!-- markdownlint-disable -->

# CI Integrada ao GitOps com Argo CD - Aula 7

Documentacao sobre a integracao entre pipelines de Integracao Continua (CI) e o modelo GitOps com Argo CD. Este material explica a separacao de responsabilidades entre CI e CD, o fluxo completo de uma pipeline tipica, a simulacao local e estrategias para evitar problemas comuns como loops infinitos.

---

## Indice

1. [Separacao CI vs CD em GitOps](#separacao-ci-vs-cd-em-gitops)
2. [Responsabilidades da CI](#responsabilidades-da-ci)
3. [Responsabilidades do CD (Argo CD)](#responsabilidades-do-cd-argo-cd)
4. [Pipeline CI Tipico com GitHub Actions](#pipeline-ci-tipico-com-github-actions)
5. [Fluxo Completo: Codigo ao Cluster](#fluxo-completo-codigo-ao-cluster)
6. [Simulacao Local com Script](#simulacao-local-com-script)
7. [Problema de Loop Infinito e Como Evitar](#problema-de-loop-infinito-e-como-evitar)
8. [Estrategia Avancada: Repositorios Separados](#estrategia-avancada-repositorios-separados)
9. [Diagrama ASCII do Fluxo CI/CD Completo](#diagrama-ascii-do-fluxo-cicd-completo)
10. [Resumo](#resumo)
11. [Referencias](#referencias)

---

## Separacao CI vs CD em GitOps

No modelo GitOps, **CI e CD sao processos distintos** com responsabilidades bem definidas. Diferentemente do modelo tradicional onde uma unica pipeline faz tudo (build, test, deploy), no GitOps a entrega continua (CD) e delegada inteiramente ao Argo CD.

### Divisao de responsabilidades

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│   CI (Integracao Continua)              CD (Entrega Continua)    │
│   Responsabilidade: PIPELINE            Responsabilidade: ARGO CD│
│                                                                   │
│   ┌──────────────────────────┐    ┌───────────────────────────┐  │
│   │ 1. Checkout do codigo    │    │ 1. Observa repositorio    │  │
│   │ 2. Instala dependencias  │    │    Git (polling/webhook)  │  │
│   │ 3. Roda testes           │    │ 2. Detecta mudanca nos    │  │
│   │ 4. Build da imagem Docker│    │    manifests YAML         │  │
│   │ 5. Push para registry    │    │ 3. Compara Git vs Cluster │  │
│   │ 6. Atualiza YAML no Git  │    │ 4. Aplica no cluster      │  │
│   │    (nova tag da imagem)  │    │ 5. Monitora health        │  │
│   └──────────────────────────┘    └───────────────────────────┘  │
│                                                                   │
│   Ferramentas: GitHub Actions,    Ferramenta: Argo CD            │
│   GitLab CI, Jenkins, CircleCI                                   │
│                                                                   │
│   Ponto de conexao: COMMIT no Git (YAML atualizado)             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Por que separar CI e CD

| Aspecto | CI+CD juntos (tradicional) | CI e CD separados (GitOps) |
|---------|---------------------------|---------------------------|
| **Deploy** | Pipeline executa `kubectl apply` | Argo CD aplica automaticamente |
| **Credenciais** | Pipeline precisa de kubeconfig | Credenciais ficam dentro do cluster |
| **Drift** | Nao detectado apos deploy | Detectado e corrigido continuamente |
| **Rollback** | Script customizado na pipeline | `git revert` ou rollback no Argo CD |
| **Auditoria** | Logs dispersos em jobs | Historico completo no Git |
| **Seguranca** | Kubeconfig exposto no CI | Kubeconfig nunca sai do cluster |

---

## Responsabilidades da CI

A pipeline de CI e responsavel por tudo que acontece **antes** do deploy. Seu objetivo final e gerar um artefato (imagem Docker) e atualizar o manifesto YAML no Git com a nova versao.

### Etapas tipicas da CI

| Etapa | O que faz | Exemplo |
|-------|-----------|---------|
| **Checkout** | Baixa o codigo-fonte do repositorio | `actions/checkout@v4` |
| **Setup** | Configura o ambiente de execucao | Instala Node.js, Go, Python, etc. |
| **Install** | Instala dependencias do projeto | `npm install`, `go mod download` |
| **Test** | Executa testes automatizados | `npm test`, `go test ./...` |
| **Build image** | Constroi a imagem Docker da aplicacao | `docker build -t app:v1.2.3 .` |
| **Push image** | Envia a imagem para o container registry | `docker push ghcr.io/user/app:v1.2.3` |
| **Update YAML** | Atualiza o manifesto YAML com a nova tag | Muda `image: app:v1.2.2` para `image: app:v1.2.3` |
| **Commit YAML** | Faz commit automatico da mudanca no YAML | `git commit -m "ci: update image to v1.2.3"` |

A etapa final (Update + Commit) e o que conecta a CI ao Argo CD. Quando o YAML e atualizado no Git, o Argo CD detecta a mudanca e faz o deploy.

---

## Responsabilidades do CD (Argo CD)

O Argo CD assume toda a responsabilidade pelo **deploy** e **monitoramento continuo**. Ele nao sabe e nao precisa saber sobre builds, testes ou pipelines.

### O que o Argo CD faz automaticamente

1. **Observa** o repositorio Git (polling a cada ~180s ou via webhook)
2. **Detecta** que o YAML mudou (nova tag de imagem, por exemplo)
3. **Compara** o estado do Git com o estado do cluster
4. **Aplica** as mudancas no cluster (novo Deployment com a nova imagem)
5. **Monitora** a saude dos recursos apos a aplicacao
6. **Corrige** drift se `selfHeal` estiver habilitado

### O que o Argo CD nao faz

- Nao executa build de imagens Docker
- Nao roda testes automatizados
- Nao faz push de imagens para registries
- Nao modifica arquivos no Git
- Nao interage com pipelines de CI

---

## Pipeline CI Tipico com GitHub Actions

Abaixo esta um exemplo didatico de pipeline CI usando GitHub Actions que se integra com o modelo GitOps.

### Estrutura do workflow

```yaml
# .github/workflows/ci.yaml
#
# Pipeline CI que builda a aplicacao e atualiza o YAML no Git
# O Argo CD detecta a mudanca no YAML e faz o deploy automaticamente

name: CI Pipeline

# TRIGGER: quando rodar esta pipeline
on:
  push:
    branches:
      - main
    # IMPORTANTE: filtrar paths para evitar loop infinito
    # A pipeline roda APENAS quando codigo-fonte muda
    # NAO roda quando manifests YAML mudam (evita loop)
    paths:
      - 'src/**'
      - 'Dockerfile'
      - 'package.json'

# Jobs da pipeline
jobs:
  build-and-update:
    runs-on: ubuntu-latest

    steps:
      # -----------------------------------------------
      # Etapa 1: Checkout do codigo
      # -----------------------------------------------
      # Baixa o codigo do repositorio para o runner
      - name: Checkout
        uses: actions/checkout@v4

      # -----------------------------------------------
      # Etapa 2: Setup do ambiente
      # -----------------------------------------------
      # Configura a versao do Node.js necessaria
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      # -----------------------------------------------
      # Etapa 3: Instalar dependencias
      # -----------------------------------------------
      - name: Install dependencies
        run: npm ci

      # -----------------------------------------------
      # Etapa 4: Executar testes
      # -----------------------------------------------
      # Se os testes falharem, a pipeline para aqui
      # Nenhuma imagem e gerada, nenhum YAML e atualizado
      - name: Run tests
        run: npm test

      # -----------------------------------------------
      # Etapa 5: Gerar tag da imagem
      # -----------------------------------------------
      # Usa o SHA curto do commit como tag da imagem
      # Isso garante que cada commit gera uma tag unica
      - name: Generate image tag
        id: tag
        run: echo "TAG=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT

      # -----------------------------------------------
      # Etapa 6: Build da imagem Docker
      # -----------------------------------------------
      - name: Build Docker image
        run: |
          docker build -t ghcr.io/usuario/minha-app:${{ steps.tag.outputs.TAG }} .

      # -----------------------------------------------
      # Etapa 7: Push da imagem para o registry
      # -----------------------------------------------
      # Envia a imagem para o GitHub Container Registry
      - name: Push Docker image
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/usuario/minha-app:${{ steps.tag.outputs.TAG }}

      # -----------------------------------------------
      # Etapa 8: Atualizar tag no YAML do manifesto
      # -----------------------------------------------
      # Usa uma action que atualiza campos especificos em YAML
      # Isso muda a tag da imagem no Deployment
      - name: Update YAML manifest
        uses: fjogeleit/yaml-update-action@main
        with:
          # Caminho do arquivo YAML a atualizar
          valueFile: 'k8s/manifests/deployment.yaml'
          # Campo YAML a atualizar (dot notation)
          propertyPath: 'spec.template.spec.containers[0].image'
          # Novo valor (imagem com a nova tag)
          value: 'ghcr.io/usuario/minha-app:${{ steps.tag.outputs.TAG }}'
          # Mensagem do commit automatico
          commitChange: true
          message: 'ci: update image to ${{ steps.tag.outputs.TAG }}'
          # Branch de destino
          branch: main
```

### Explicacao das etapas criticas

#### Geracao da tag (SHA do commit)

Usar o SHA curto do commit como tag da imagem Docker e uma pratica comum porque:

- **Unicidade:** cada commit gera uma tag diferente
- **Rastreabilidade:** a tag permite rastrear exatamente qual codigo esta em cada imagem
- **Imutabilidade:** o SHA nunca muda (diferente de tags como `latest`)

```bash
# Gerar SHA curto do commit (ex: abc1234)
git rev-parse --short HEAD
```

#### Atualizacao do YAML (yaml-update-action)

A action `yaml-update-action` modifica um campo especifico dentro do YAML sem alterar o resto do arquivo. Isso e mais seguro do que usar `sed` porque:

- Respeita a estrutura YAML
- Nao quebra indentacao
- Atualiza apenas o campo especificado

#### Commit automatico

A action faz um commit automatico com a mensagem configurada. Esse commit e o que aciona o Argo CD no proximo ciclo de polling.

---

## Fluxo Completo: Codigo ao Cluster

O fluxo completo desde uma alteracao no codigo ate a aplicacao no cluster envolve cinco sistemas:

```
┌──────────────────────────────────────────────────────────────────┐
│              Fluxo Completo: Codigo ao Cluster                    │
│                                                                   │
│   [1] CODIGO                                                     │
│   Desenvolvedor altera src/index.js                              │
│   git commit + git push (branch main)                            │
│       |                                                           │
│       v                                                           │
│   [2] CI (GitHub Actions)                                        │
│   - Checkout do codigo                                           │
│   - npm install + npm test                                       │
│   - docker build (gera imagem com tag abc1234)                   │
│   - docker push (envia para ghcr.io)                             │
│       |                                                           │
│       v                                                           │
│   [3] REGISTRY (ghcr.io / Docker Hub)                            │
│   Imagem armazenada: ghcr.io/usuario/app:abc1234                │
│       |                                                           │
│       v                                                           │
│   [4] GIT (YAML atualizado)                                     │
│   CI faz commit automatico:                                      │
│   deployment.yaml -> image: ghcr.io/usuario/app:abc1234         │
│       |                                                           │
│       v                                                           │
│   [5] ARGO CD -> CLUSTER                                         │
│   - Detecta mudanca no YAML (polling ou webhook)                 │
│   - Compara Git vs Cluster                                       │
│   - Aplica novo Deployment no cluster                            │
│   - Pods atualizam para a nova imagem                            │
│   - Application: Synced + Healthy                                │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Tempo estimado de cada etapa

| Etapa | Tempo estimado | Observacao |
|-------|----------------|------------|
| Push do desenvolvedor | Instantaneo | Depende da internet |
| CI (build + test + push) | 2 a 10 minutos | Depende do projeto |
| Commit automatico do YAML | 5 a 15 segundos | Feito pela action |
| Argo CD detectar mudanca | 0 a 180 segundos | Polling padrao |
| Argo CD aplicar no cluster | 5 a 30 segundos | Depende dos recursos |
| Pods atualizados (rollout) | 10 a 60 segundos | Depende da estrategia |
| **Total** | **~3 a 14 minutos** | Maior parte e o CI |

---

## Simulacao Local com Script

Para fins didaticos, o projeto inclui um script que **simula** o que uma pipeline CI faria: atualizar um arquivo YAML e fazer commit.

### O script `03-simulate-ci.sh`

Localizado em `scripts/03-simulate-ci.sh`, o script:

1. Recebe uma nova versao como parametro
2. Atualiza o valor da versao no ConfigMap (conteudo HTML)
3. Faz `git add` e `git commit` automaticamente
4. Instrui o usuario a fazer `git push`

### Como usar

```bash
# Simular atualizacao para v2
bash scripts/03-simulate-ci.sh v2

# Simular atualizacao para v3
bash scripts/03-simulate-ci.sh v3
```

### O que acontece apos o push

```
1. Voce executa: bash scripts/03-simulate-ci.sh v2
2. Script atualiza o ConfigMap YAML com a nova versao
3. Script faz git commit automatico
4. Voce faz: git push

5. Argo CD detecta a mudanca (~180s de polling)
6. Application fica "OutOfSync"
7. Se AutoSync habilitado: sincroniza automaticamente
8. Se sync manual: execute "argocd app sync demo-nginx"

9. ConfigMap atualizado no cluster
10. Pods recarregam a nova configuracao
```

### Diferenca entre simulacao e CI real

| Aspecto | Simulacao local (script) | CI real (GitHub Actions) |
|---------|--------------------------|--------------------------|
| Build de imagem | Nao faz | Sim (docker build + push) |
| Testes | Nao executa | Sim (npm test, etc.) |
| Atualiza YAML | Sim (ConfigMap) | Sim (Deployment image tag) |
| Commit automatico | Sim | Sim |
| Push automatico | Nao (usuario faz manualmente) | Sim (automatico) |
| Objetivo | Demonstrar o fluxo GitOps | Deploy real de producao |

---

## Problema de Loop Infinito e Como Evitar

Um dos problemas mais comuns ao integrar CI com GitOps e o **loop infinito de commits**.

### Como o loop acontece

```
┌─────────────────────────────────────────────────────────┐
│                  Loop Infinito                            │
│                                                           │
│   1. Desenvolvedor faz push (altera src/)                │
│       |                                                   │
│       v                                                   │
│   2. CI roda: build, test, push image                    │
│       |                                                   │
│       v                                                   │
│   3. CI faz commit automatico (atualiza YAML)            │
│       |                                                   │
│       v                                                   │
│   4. Push do commit automatico aciona a CI NOVAMENTE!    │
│       |                                                   │
│       v                                                   │
│   5. CI roda de novo: build, test, push image            │
│       |                                                   │
│       v                                                   │
│   6. CI faz commit automatico (YAML ja esta igual)       │
│       |                                                   │
│       v                                                   │
│   ... e assim por diante (LOOP!)                         │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

O problema: o commit automatico da CI (etapa 3) e um push na branch `main`, o que aciona a pipeline novamente (etapa 4), criando um ciclo infinito.

### Solucao 1: Filtrar paths no trigger (recomendada)

A solucao mais simples e eficaz e configurar o trigger da pipeline para rodar **apenas quando determinados paths mudam**:

```yaml
on:
  push:
    branches:
      - main
    paths:
      # APENAS estas mudancas acionam a pipeline
      - 'src/**'
      - 'Dockerfile'
      - 'package.json'
      - 'package-lock.json'
      # EXCLUIDO implicitamente:
      # - 'k8s/**'  (manifests YAML)
      # - 'docs/**' (documentacao)
```

Com essa configuracao:

- Push em `src/index.js` -> **ACIONA** a CI
- Push em `k8s/manifests/deployment.yaml` -> **NAO ACIONA** a CI

O commit automatico da CI altera apenas arquivos em `k8s/`, que nao estao no filtro de paths. Portanto, nao aciona a pipeline novamente.

### Solucao 2: Usar token de bot

Outra abordagem e fazer o commit automatico com um token de bot especifico e configurar o workflow para ignorar commits desse bot:

```yaml
on:
  push:
    branches:
      - main

jobs:
  build:
    # Nao roda se o commit foi feito pelo bot
    if: github.actor != 'github-actions[bot]'
    runs-on: ubuntu-latest
    steps:
      # ...
```

### Solucao 3: Usar [skip ci] na mensagem

Incluir `[skip ci]` na mensagem do commit automatico:

```yaml
- name: Update YAML manifest
  uses: fjogeleit/yaml-update-action@main
  with:
    valueFile: 'k8s/manifests/deployment.yaml'
    propertyPath: 'spec.template.spec.containers[0].image'
    value: 'ghcr.io/usuario/app:${{ steps.tag.outputs.TAG }}'
    commitChange: true
    message: 'ci: update image to ${{ steps.tag.outputs.TAG }} [skip ci]'
    branch: main
```

### Comparacao das solucoes

| Solucao | Complexidade | Confiabilidade | Recomendacao |
|---------|-------------|----------------|--------------|
| Filtrar paths | Baixa | Alta | Preferida |
| Token de bot | Media | Alta | Alternativa |
| [skip ci] | Baixa | Media (depende do CI) | Complemento |

---

## Estrategia Avancada: Repositorios Separados

Em projetos de producao, e comum separar o codigo-fonte da aplicacao dos manifests Kubernetes em **repositorios diferentes**.

### Modelo mono-repositorio (o que usamos no projeto)

```
meu-repo/
├── src/                    # Codigo-fonte da aplicacao
│   ├── index.js
│   └── app.js
├── Dockerfile              # Build da imagem
├── k8s/                    # Manifests Kubernetes
│   └── manifests/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
└── .github/
    └── workflows/
        └── ci.yaml         # Pipeline CI
```

Nesse modelo, codigo e manifests vivem no mesmo repositorio. A CI precisa filtrar paths para evitar loops.

### Modelo multi-repositorio (recomendado para producao)

```
REPOSITORIO 1: app-codigo
├── src/
│   ├── index.js
│   └── app.js
├── Dockerfile
├── tests/
└── .github/
    └── workflows/
        └── ci.yaml

REPOSITORIO 2: app-manifests (observado pelo Argo CD)
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/
    ├── staging/
    └── production/
```

### Fluxo com repositorios separados

```
┌─────────────────────────────────────────────────────────────────┐
│           Fluxo com Repositorios Separados                       │
│                                                                   │
│   REPO 1 (app-codigo)                                            │
│   1. Desenvolvedor faz push em src/                              │
│   2. CI roda no REPO 1: build, test, push image                 │
│   3. CI faz commit no REPO 2 (atualiza tag da imagem)           │
│                                                                   │
│   REPO 2 (app-manifests) <-- Observado pelo Argo CD             │
│   4. Commit da CI chega com nova tag                             │
│   5. Argo CD detecta mudanca                                    │
│   6. Argo CD sincroniza com o cluster                            │
│                                                                   │
│   Vantagens:                                                     │
│   - Zero risco de loop infinito (repos diferentes)              │
│   - Separacao clara de responsabilidades                         │
│   - Equipes diferentes podem gerenciar cada repo                │
│   - Permissoes granulares (devs no repo 1, ops no repo 2)      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Tabela comparativa

| Aspecto | Mono-repositorio | Multi-repositorio |
|---------|------------------|-------------------|
| **Complexidade** | Menor (tudo junto) | Maior (dois repos para gerenciar) |
| **Risco de loop** | Precisa filtrar paths | Zero (repos separados) |
| **Separacao de responsabilidades** | Parcial | Completa |
| **Permissoes** | Mesmas para codigo e manifests | Granulares por repositorio |
| **Cenario ideal** | Projetos pequenos, estudo | Producao, equipes grandes |
| **Configuracao do Argo CD** | Source aponta para path no mono-repo | Source aponta para o repo de manifests |

---

## Diagrama ASCII do Fluxo CI/CD Completo

```
┌────────────────────────────────────────────────────────────────────────┐
│                    FLUXO CI/CD COMPLETO COM GITOPS                      │
│                                                                         │
│                                                                         │
│   DESENVOLVEDOR                                                        │
│   ┌────────────────┐                                                   │
│   │ 1. Altera      │                                                   │
│   │    codigo       │                                                   │
│   │ 2. git commit  │                                                   │
│   │ 3. git push    │                                                   │
│   └───────┬────────┘                                                   │
│           │                                                             │
│           v                                                             │
│   GITHUB (Repositorio)                                                 │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Branch main recebe o push                                      │   │
│   │ Trigger: paths 'src/**' ou 'Dockerfile'                        │   │
│   └───────┬────────────────────────────────────────────────────────┘   │
│           │                                                             │
│           v                                                             │
│   CI (GitHub Actions)                                                  │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                                                                │   │
│   │   [checkout] --> [setup] --> [install] --> [test]              │   │
│   │                                              │                 │   │
│   │                                       Testes passaram?        │   │
│   │                                          /       \             │   │
│   │                                        Sim       Nao           │   │
│   │                                         │         │            │   │
│   │                                         v      [FALHA]         │   │
│   │                                    [build image]   (para aqui) │   │
│   │                                         │                      │   │
│   │                                         v                      │   │
│   │                                    [push image]                │   │
│   │                                    ghcr.io/user/app:abc1234   │   │
│   │                                         │                      │   │
│   │                                         v                      │   │
│   │                                    [update YAML]               │   │
│   │                                    image: app:abc1234         │   │
│   │                                         │                      │   │
│   │                                         v                      │   │
│   │                                    [commit + push]             │   │
│   │                                    "ci: update image"         │   │
│   │                                                                │   │
│   └────────────────────────────────────────┬───────────────────────┘   │
│                                            │                            │
│           ┌────────────────────────────────┘                            │
│           │                                                             │
│           v                                                             │
│   CONTAINER REGISTRY (ghcr.io / Docker Hub)                            │
│   ┌────────────────────────────────────────┐                           │
│   │ ghcr.io/usuario/minha-app:abc1234      │                           │
│   │ (imagem Docker armazenada)             │                           │
│   └────────────────────────────────────────┘                           │
│                                                                         │
│           │ (YAML atualizado no Git)                                   │
│           v                                                             │
│   ARGO CD (dentro do cluster)                                          │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                                                                │   │
│   │   [polling ~180s] --> Detecta novo commit no YAML             │   │
│   │                              │                                 │   │
│   │                              v                                 │   │
│   │                      [Compara Git vs Cluster]                 │   │
│   │                        image: abc1234 (Git)                   │   │
│   │                        image: old-tag  (Cluster)              │   │
│   │                              │                                 │   │
│   │                              v                                 │   │
│   │                      [OutOfSync detectado]                    │   │
│   │                              │                                 │   │
│   │                              v                                 │   │
│   │                      [Aplica novo Deployment]                 │   │
│   │                              │                                 │   │
│   │                              v                                 │   │
│   │                      [Rollout: novos pods criados]            │   │
│   │                              │                                 │   │
│   │                              v                                 │   │
│   │                      [Synced + Healthy]                       │   │
│   │                                                                │   │
│   └────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│           │                                                             │
│           v                                                             │
│   CLUSTER KUBERNETES                                                   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                                                                │   │
│   │   Namespace: demo-app                                          │   │
│   │                                                                │   │
│   │   Deployment: demo-nginx (image: ghcr.io/user/app:abc1234)   │   │
│   │   ├── Pod 1 (Running - nova imagem)                           │   │
│   │   ├── Pod 2 (Running - nova imagem)                           │   │
│   │   └── Pod 3 (Running - nova imagem)                           │   │
│   │                                                                │   │
│   │   Service: demo-nginx-svc                                      │   │
│   │                                                                │   │
│   └────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **Separacao CI/CD** | CI cuida de build/test/push; CD (Argo CD) cuida do deploy e monitoramento |
| **CI** | Pipeline que builda, testa, gera imagem Docker e atualiza o YAML no Git |
| **CD (Argo CD)** | Observa o Git e sincroniza o cluster automaticamente |
| **Tag por SHA** | Usar o SHA curto do commit como tag da imagem Docker (unicidade e rastreabilidade) |
| **yaml-update-action** | GitHub Action que atualiza campos especificos em arquivos YAML |
| **Loop infinito** | Problema onde o commit da CI aciona a CI novamente em ciclo |
| **Filtro de paths** | Solucao preferida: acionar CI apenas para mudancas em `src/` |
| **Mono-repositorio** | Codigo e manifests no mesmo repo (simples, requer filtro de paths) |
| **Multi-repositorio** | Codigo e manifests em repos separados (producao, zero risco de loop) |
| **Simulacao local** | Script `03-simulate-ci.sh` que simula o commit da CI para fins didaticos |
| **Fluxo completo** | Codigo -> CI -> Registry -> Git (YAML) -> Argo CD -> Cluster |

---

## Referencias

- [Argo CD - CI/CD Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/ci_automation/)
- [GitHub Actions - Workflow Triggers](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [GitHub Actions - Path Filtering](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore)
- [yaml-update-action (GitHub)](https://github.com/fjogeleit/yaml-update-action)
- [GitOps with Argo CD - Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Argo CD - Webhook Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/)
