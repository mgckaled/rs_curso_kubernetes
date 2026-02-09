<!-- markdownlint-disable -->

# Instalacao do Argo CD - Aula 4

Guia detalhado de instalacao do Argo CD em um cluster Kind local,
cobrindo os tipos de instalacao disponiveis, componentes instalados,
acesso a interface web e resolucao de problemas comuns.

---

## Indice

1. [Tipos de Instalacao](#tipos-de-instalacao)
2. [Por que Usamos Non-HA Neste Projeto](#por-que-usamos-non-ha-neste-projeto)
3. [Componentes Instalados](#componentes-instalados)
4. [Passo a Passo da Instalacao](#passo-a-passo-da-instalacao)
5. [Acesso a Interface Web (UI)](#acesso-a-interface-web-ui)
6. [Credenciais Iniciais](#credenciais-iniciais)
7. [Verificacao da Instalacao](#verificacao-da-instalacao)
8. [Troubleshooting](#troubleshooting)
9. [Resumo](#resumo)
10. [Referencias](#referencias)

---

## Tipos de Instalacao

O Argo CD oferece tres manifests oficiais de instalacao, cada um
adequado a um cenario diferente. A escolha impacta diretamente no
consumo de recursos e nas funcionalidades disponiveis.

| Tipo | Manifest | Inclui UI | Alta Disponibilidade (HA) | Cenario Recomendado |
|------|----------|-----------|---------------------------|---------------------|
| **Non-HA (padrao)** | `install.yaml` | Sim | Nao | Desenvolvimento, estudo, ambientes locais |
| **HA (alta disponibilidade)** | `ha/install.yaml` | Sim | Sim | Producao com requisitos de resiliencia |
| **Core (minimalista)** | `core-install.yaml` | Nao | Nao | Ambientes com RAM extremamente limitada |

### Non-HA (install.yaml)

A instalacao padrao, que utilizamos neste projeto. Instala um unico
pod por componente, incluindo a interface web (UI) e o servidor
de autenticacao (dex-server). E a opcao ideal para estudo porque
oferece visibilidade completa pelo navegador.

```bash
# Comando de instalacao Non-HA
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### HA (ha/install.yaml)

A instalacao de alta disponibilidade replica os componentes criticos
(geralmente 3 replicas de server, repo-server e application-controller).
Esse modo e adequado para producao, onde a queda de um pod nao pode
interromper o servico. O consumo de RAM e significativamente maior.

```bash
# Comando de instalacao HA (NAO usado neste projeto)
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml
```

### Core (core-install.yaml)

A instalacao minimalista remove a interface web (argocd-server) e o
servidor de autenticacao (argocd-dex-server). Toda a interacao e feita
via CLI (`argocd`) ou diretamente com `kubectl`. E a opcao de menor
consumo, mas sacrifica a experiencia visual.

```bash
# Comando de instalacao Core (alternativa para pouca RAM)
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
```

---

## Por que Usamos Non-HA Neste Projeto

A escolha da instalacao Non-HA (`install.yaml`) se deve a tres fatores:

1. **Interface web (UI) necessaria para as praticas:** as aulas
   dependem da UI para visualizar estados de sincronizacao, explorar
   a arvore de recursos e acompanhar eventos. Sem a UI, a experiencia
   didatica seria muito prejudicada.

2. **Apenas 1 pod por componente:** diferentemente da instalacao HA
   (que cria 3 replicas de cada componente), a Non-HA roda um unico
   pod por componente. Isso reduz drasticamente o consumo de RAM,
   permitindo que o Argo CD funcione em clusters Kind locais com
   recursos limitados (2.5 GB de RAM para o WSL2).

3. **Sem necessidade de resiliencia:** em ambiente de estudo, a queda
   temporaria de um pod nao representa um problema critico. Basta
   aguardar o Kubernetes reiniciar o pod.

### Comparacao de consumo estimado

| Instalacao | Pods totais | RAM estimada (limits) |
|------------|-------------|----------------------|
| Non-HA | 7 pods (1 por componente) | ~1.4 Gi (com patches) |
| HA | ~21 pods (3 por componente) | ~4-6 Gi |
| Core | 4-5 pods (sem UI e dex) | ~0.8 Gi (com patches) |

---

## Componentes Instalados

Ao executar `kubectl apply -n argocd -f install.yaml`, o Argo CD
instala diversos recursos no cluster. Esta secao detalha cada
categoria.

### CRDs (Custom Resource Definitions)

Os CRDs estendem a API do Kubernetes com novos tipos de recursos
especificos do Argo CD. Sao instalados em nivel de cluster (nao sao
limitados a um namespace).

| CRD | Descricao | Comando de verificacao |
|-----|-----------|------------------------|
| `applications.argoproj.io` | Define uma aplicacao gerenciada pelo Argo CD (source + destination + syncPolicy) | `kubectl get crd applications.argoproj.io` |
| `applicationsets.argoproj.io` | Gera multiplas Applications a partir de templates e geradores | `kubectl get crd applicationsets.argoproj.io` |
| `appprojects.argoproj.io` | Agrupa Applications e define permissoes (repositorios, clusters, namespaces permitidos) | `kubectl get crd appprojects.argoproj.io` |

Para listar todos os CRDs do Argo CD de uma vez:

```bash
kubectl get crd | grep argoproj
```

Saida esperada:

```
applications.argoproj.io            <TIMESTAMP>
applicationsets.argoproj.io         <TIMESTAMP>
appprojects.argoproj.io             <TIMESTAMP>
```

### Deployments

Os Deployments sao os componentes principais do Argo CD. Cada um roda
como um pod separado dentro do namespace `argocd`.

| Deployment | Funcao |
|------------|--------|
| `argocd-server` | API REST/gRPC e interface web (UI). Ponto de entrada para navegador e CLI. |
| `argocd-repo-server` | Clona repositorios Git, renderiza manifests (Helm, Kustomize, YAML puro) e mantem cache local. |
| `argocd-application-controller` | Coracao do Argo CD. Monitora Applications, compara Git vs cluster e executa reconciliacao. |
| `argocd-redis` | Cache interno (Redis). Armazena dados de sessao e resultados de operacoes frequentes. |
| `argocd-dex-server` | Autenticacao externa via OIDC, SAML, LDAP. Em ambiente local, usa-se o usuario `admin` interno. |
| `argocd-applicationset-controller` | Gera Applications automaticamente a partir de ApplicationSets (templates). |
| `argocd-notifications-controller` | Envia notificacoes sobre mudancas de estado (Slack, email, webhook). |

Para listar todos os Deployments:

```bash
kubectl get deployments -n argocd
```

Saida esperada:

```
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
argocd-applicationset-controller   1/1     1            1           5m
argocd-dex-server                  1/1     1            1           5m
argocd-notifications-controller    1/1     1            1           5m
argocd-redis                       1/1     1            1           5m
argocd-repo-server                 1/1     1            1           5m
argocd-server                      1/1     1            1           5m
```

> **Nota:** o `argocd-application-controller` pode aparecer como
> StatefulSet em algumas versoes do Argo CD, em vez de Deployment.
> Para verificar: `kubectl get statefulsets -n argocd`

### Services

Os Services expoe os componentes internos do Argo CD para comunicacao
dentro do cluster e, no caso do argocd-server, para acesso externo
via port-forward.

| Service | Tipo | Porta | Usado para |
|---------|------|-------|------------|
| `argocd-server` | ClusterIP | 443 (HTTPS), 80 (HTTP) | Acesso a UI e API (via port-forward) |
| `argocd-repo-server` | ClusterIP | 8081 | Comunicacao interna com o controller |
| `argocd-redis` | ClusterIP | 6379 | Cache interno (acessado por server e controller) |
| `argocd-dex-server` | ClusterIP | 5556, 5557 | Autenticacao OIDC (comunicacao interna) |

Para listar todos os Services:

```bash
kubectl get svc -n argocd
```

### RBAC (Role-Based Access Control)

O Argo CD cria diversos recursos de RBAC para controlar permissoes
dos seus componentes dentro do cluster.

| Tipo de Recurso | Descricao | Escopo |
|-----------------|-----------|--------|
| **ServiceAccounts** | Identidade de cada componente (argocd-server, argocd-application-controller, etc.) | Namespace `argocd` |
| **Roles** | Permissoes dentro do namespace `argocd` (ler Secrets, ConfigMaps) | Namespace `argocd` |
| **RoleBindings** | Vincula Roles aos ServiceAccounts dentro do namespace | Namespace `argocd` |
| **ClusterRoles** | Permissoes em nivel de cluster (criar/ler/atualizar recursos em qualquer namespace) | Cluster inteiro |
| **ClusterRoleBindings** | Vincula ClusterRoles aos ServiceAccounts do Argo CD | Cluster inteiro |

O `argocd-application-controller` precisa de **ClusterRole** porque
ele gerencia recursos em multiplos namespaces (nao apenas no `argocd`).
Quando o Argo CD aplica um Deployment no namespace `demo-app`, por
exemplo, o controller precisa de permissao para criar, ler e atualizar
recursos nesse namespace.

Para listar os recursos RBAC do Argo CD:

```bash
# ServiceAccounts
kubectl get serviceaccounts -n argocd

# Roles e RoleBindings (dentro do namespace argocd)
kubectl get roles,rolebindings -n argocd

# ClusterRoles e ClusterRoleBindings (nivel de cluster)
kubectl get clusterroles,clusterrolebindings | grep argocd
```

---

## Passo a Passo da Instalacao

A instalacao completa envolve tres etapas fundamentais: criar o
namespace, aplicar o manifest e aguardar os pods ficarem prontos.

### Etapa 1: Criar o namespace argocd

O Argo CD espera um namespace chamado `argocd`. Todos os componentes
serao instalados nele.

```bash
kubectl create namespace argocd
```

Ou, usando o manifest do projeto:

```bash
kubectl apply -f manifests/01-namespace-argocd.yaml
```

### Etapa 2: Instalar o Argo CD (Non-HA)

Aplicar o manifest oficial direto do repositorio do Argo CD:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Esse comando cria todos os CRDs, Deployments, Services, ServiceAccounts,
Roles, ClusterRoles e ConfigMaps necessarios.

### Etapa 3: Aguardar os pods ficarem Ready

Apos a instalacao, o Kubernetes precisa baixar as imagens dos
containers e inicializar cada pod. Isso pode levar de 1 a 3 minutos
dependendo da velocidade da internet.

```bash
# Aguardar todos os deployments ficarem disponiveis (timeout de 5 min)
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
```

Para acompanhar o progresso em tempo real:

```bash
# Ver status dos pods continuamente (Ctrl+C para sair)
kubectl get pods -n argocd -w
```

> **Dica:** o script `scripts/01-setup-cluster.sh` do projeto
> automatiza todas essas etapas, incluindo a criacao do cluster Kind,
> instalacao do Argo CD e aplicacao de patches de recursos.

---

## Acesso a Interface Web (UI)

A interface web do Argo CD e servida pelo componente `argocd-server`.
Em um cluster local (Kind), o acesso e feito via `port-forward`, que
cria um tunel entre a sua maquina e o Service dentro do cluster.

### Comando de port-forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Esse comando faz o seguinte:

| Parametro | Significado |
|-----------|-------------|
| `svc/argocd-server` | Alvo: o Service chamado `argocd-server` |
| `-n argocd` | Namespace onde o Service esta |
| `8080:443` | Porta local `8080` redirecionada para a porta `443` do Service |

### Acessar no navegador

Apos executar o port-forward, abra o navegador e acesse:

```
https://localhost:8080
```

O navegador ira exibir um aviso de certificado autoassinado. Isso e
normal em ambientes locais. Clique em **"Avancado"** e depois em
**"Prosseguir para localhost (nao seguro)"** para continuar.

### Importante sobre o port-forward

- O terminal onde o port-forward esta rodando **deve permanecer
  aberto**. Fechar o terminal encerra o tunel.
- Se o port-forward cair, basta executar o comando novamente.
- A porta 8080 e arbitraria. Voce pode usar qualquer porta livre
  (ex: `9090:443`, `3000:443`).

---

## Credenciais Iniciais

Na primeira instalacao, o Argo CD gera automaticamente uma senha
para o usuario `admin`. Essa senha e armazenada em um Secret do
Kubernetes.

### Dados de acesso

| Campo | Valor |
|-------|-------|
| **Usuario** | `admin` |
| **Senha** | Armazenada no Secret `argocd-initial-admin-secret` |

### Obter a senha do admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Explicacao do comando:

- `get secret argocd-initial-admin-secret`: busca o Secret que contem a senha
- `-o jsonpath="{.data.password}"`: extrai apenas o campo `password` do Secret
- `| base64 -d`: decodifica o valor de base64 para texto legivel

### Sobre o Secret argocd-initial-admin-secret

- O Secret e criado automaticamente durante a instalacao.
- Ele contem **apenas** a senha inicial do usuario `admin`.
- Em producao, e recomendado deletar esse Secret apos configurar
  autenticacao SSO via dex-server.
- O Secret existe no namespace `argocd`.

### Exemplo de login via CLI (opcional)

Se voce tiver o CLI do Argo CD instalado (`argocd`), pode fazer
login pela linha de comando:

```bash
argocd login localhost:8080 --insecure --username admin --password '<senha>'
```

---

## Verificacao da Instalacao

Apos a instalacao, execute os comandos abaixo para confirmar que
tudo esta funcionando corretamente.

### Verificar pods

Todos os pods devem estar com status `Running` e `READY` mostrando
`1/1`:

```bash
kubectl get pods -n argocd
```

Saida esperada:

```
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          5m
argocd-applicationset-controller-xxxxx-xxxxx       1/1     Running   0          5m
argocd-dex-server-xxxxx-xxxxx                      1/1     Running   0          5m
argocd-notifications-controller-xxxxx-xxxxx        1/1     Running   0          5m
argocd-redis-xxxxx-xxxxx                           1/1     Running   0          5m
argocd-repo-server-xxxxx-xxxxx                     1/1     Running   0          5m
argocd-server-xxxxx-xxxxx                          1/1     Running   0          5m
```

### Verificar CRDs

Os tres CRDs do Argo CD devem estar registrados:

```bash
kubectl get crd | grep argoproj
```

### Verificar Services

Os Services devem estar criados e acessiveis:

```bash
kubectl get svc -n argocd
```

### Verificar o projeto default

O Argo CD cria automaticamente um AppProject chamado `default`:

```bash
kubectl get appproject -n argocd
```

### Verificacao completa em um unico comando

Para uma visao geral rapida de todos os recursos no namespace:

```bash
kubectl get all -n argocd
```

---

## Troubleshooting

### Pods em CrashLoopBackOff (problema de RAM)

**Sintoma:** um ou mais pods do Argo CD ficam alternando entre
`Running` e `CrashLoopBackOff`, com restarts frequentes.

**Causa provavel:** memoria insuficiente. O pod esta sendo encerrado
pelo Kubernetes porque ultrapassou o limite de memoria (`OOMKilled`).

**Diagnostico:**

```bash
# Verificar eventos do pod
kubectl describe pod <nome-do-pod> -n argocd

# Procurar por "OOMKilled" na saida
kubectl get pods -n argocd -o wide
```

**Solucao:**

1. Aplicar os patches de resource limits do projeto:

   ```bash
   # O script de setup ja aplica automaticamente
   bash scripts/01-setup-cluster.sh
   ```

2. Se o problema persistir, verificar se o Docker Desktop tem RAM
   suficiente alocada para o WSL2 (recomendado: 2.5 a 3 GB).

3. Fechar aplicacoes desnecessarias no Windows para liberar RAM.

4. Como ultimo recurso, usar a instalacao Core (sem UI):

   ```bash
   kubectl apply -n argocd \
     -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
   ```

### Port-forward falha ou nao conecta

**Sintoma:** ao executar `kubectl port-forward`, recebe erro de
conexao ou a pagina no navegador nao carrega.

**Diagnostico:**

```bash
# Verificar se o pod argocd-server esta Running
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server

# Verificar se o Service existe
kubectl get svc argocd-server -n argocd

# Verificar logs do argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

**Solucoes possiveis:**

| Problema | Solucao |
|----------|---------|
| Pod nao esta Running | Aguardar o pod inicializar ou verificar logs |
| Porta 8080 ja em uso | Usar outra porta: `kubectl port-forward svc/argocd-server -n argocd 9090:443` |
| Conexao recusada | Verificar se o cluster Kind esta rodando: `kind get clusters` |
| Timeout na conexao | Verificar se o contexto do kubectl esta correto: `kubectl config current-context` |

### Secret argocd-initial-admin-secret nao encontrado

**Sintoma:** ao tentar obter a senha do admin, recebe erro
`Error from server (NotFound): secrets "argocd-initial-admin-secret" not found`.

**Causas possiveis:**

1. **Instalacao ainda nao completou:** o Secret e criado alguns
   segundos apos a instalacao. Aguarde os pods ficarem Ready e
   tente novamente.

2. **Secret foi deletado manualmente:** em ambientes onde alguem
   ja configurou SSO, o Secret pode ter sido removido intencionalmente.

3. **Instalacao Core:** a instalacao Core pode nao gerar esse Secret
   em todas as versoes.

**Solucao:** se o Secret foi perdido, voce pode redefinir a senha
do admin usando o `argocd` CLI ou reinstalando o Argo CD:

```bash
# Opcao 1: Reinstalar o Argo CD (recria o Secret)
kubectl delete namespace argocd
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Opcao 2: Criar um novo Secret manualmente (bcrypt hash)
# A senha abaixo e "admin123" (apenas para ambiente de estudo)
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa"}}'
```

### Pods demoram muito para inicializar

**Sintoma:** os pods ficam em status `ContainerCreating` ou
`ImagePullBackOff` por varios minutos.

**Causa provavel:** download das imagens Docker esta lento ou falhou.

**Diagnostico:**

```bash
kubectl describe pod <nome-do-pod> -n argocd
```

Procure por eventos como `Failed to pull image` ou `ImagePullBackOff`.

**Solucao:**

- Verificar conexao com a internet.
- Aguardar (o Kubernetes faz retry automatico com backoff exponencial).
- Se usar proxy corporativo, configurar o Docker para usar o proxy.

---

## Resumo

| Etapa | Comando / Acao |
|-------|----------------|
| Criar namespace | `kubectl create namespace argocd` |
| Instalar Argo CD | `kubectl apply -n argocd -f <URL>/install.yaml` |
| Aguardar pods | `kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s` |
| Port-forward | `kubectl port-forward svc/argocd-server -n argocd 8080:443` |
| Obter senha | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Acessar UI | `https://localhost:8080` (usuario: `admin`) |
| Verificar pods | `kubectl get pods -n argocd` |
| Verificar CRDs | `kubectl get crd \| grep argoproj` |

### O que foi instalado

- 3 CRDs: `applications`, `applicationsets`, `appprojects`
- 7 Deployments: server, repo-server, application-controller, redis, dex-server, applicationset-controller, notifications-controller
- 4+ Services: server, repo-server, redis, dex-server
- Recursos RBAC: ServiceAccounts, Roles, RoleBindings, ClusterRoles, ClusterRoleBindings
- 1 AppProject padrao (`default`)
- 1 Secret com a senha inicial do admin

---

## Referencias

- [Argo CD - Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Argo CD - Installation](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/)
- [Argo CD - Core Installation](https://argo-cd.readthedocs.io/en/stable/operator-manual/core/)
- [Argo CD - GitHub Releases](https://github.com/argoproj/argo-cd/releases)
- [Kind - Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
