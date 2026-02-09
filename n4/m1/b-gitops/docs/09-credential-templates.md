<!-- markdownlint-disable -->

# Credential Templates do Argo CD - Aula 10

Documentacao sobre Credential Templates no Argo CD, cobrindo o
problema de registrar repositorios individualmente, a solucao com
pattern matching por organizacao, autenticacao via SSH, e o
comportamento de delete cascade vs non-cascade.

---

## Indice

1. [O Problema: Registro Individual de Repositorios](#o-problema-registro-individual-de-repositorios)
2. [A Solucao: Credential Templates](#a-solucao-credential-templates)
3. [Diferenca: Secret "repository" vs "repo-creds"](#diferenca-secret-repository-vs-repo-creds)
4. [Como Funciona o Pattern Matching](#como-funciona-o-pattern-matching)
5. [Autenticacao via SSH](#autenticacao-via-ssh)
6. [Delete Cascade vs Non-Cascade](#delete-cascade-vs-non-cascade)
7. [Exemplo YAML do Credential Template](#exemplo-yaml-do-credential-template)
8. [Resumo](#resumo)
9. [Referencias](#referencias)

---

## O Problema: Registro Individual de Repositorios

Por padrao, o Argo CD exige que cada repositorio Git seja
registrado individualmente. Quando uma Application referencia
um repositorio, o Argo CD precisa saber como autenticar-se
nesse repositorio para clonar os manifests.

### Registro individual

```bash
# Registrar repositorio 1
argocd repo add git@github.com:minha-org/repo-a.git --ssh-private-key-path ~/.ssh/id_ed25519

# Registrar repositorio 2
argocd repo add git@github.com:minha-org/repo-b.git --ssh-private-key-path ~/.ssh/id_ed25519

# Registrar repositorio 3
argocd repo add git@github.com:minha-org/repo-c.git --ssh-private-key-path ~/.ssh/id_ed25519
```

### Por que isso nao escala

| Problema | Descricao |
|----------|-----------|
| **Repeticao** | O mesmo comando e executado N vezes, mudando apenas o nome do repositorio |
| **Mesma credencial** | Em muitos casos, todos os repositorios da mesma organizacao usam a mesma chave SSH ou token |
| **Esquecimento** | Ao criar um novo repositorio, e facil esquecer de registra-lo no Argo CD |
| **Manutencao** | Se a chave SSH for rotacionada, e necessario atualizar cada registro individualmente |
| **Escala** | Uma organizacao com 50 repositorios precisaria de 50 registros manuais |

---

## A Solucao: Credential Templates

Os **Credential Templates** permitem registrar credenciais
**uma unica vez** para toda uma organizacao (ou prefixo de URL).
Quando o Argo CD precisar acessar qualquer repositorio que
corresponda ao padrao (pattern), ele usara automaticamente as
credenciais do template.

### Conceito

```
Sem Credential Templates:
  repo-a.git --> credencial-a (registro individual)
  repo-b.git --> credencial-b (registro individual)
  repo-c.git --> credencial-c (registro individual)

Com Credential Templates:
  git@github.com:minha-org/* --> credencial-unica (1 template)
    |
    +-- repo-a.git (usa automaticamente)
    +-- repo-b.git (usa automaticamente)
    +-- repo-c.git (usa automaticamente)
    +-- repo-d.git (novo repo, ja funciona!)
```

### Beneficios

- **Uma credencial para toda a organizacao:** registre uma vez,
  cobre todos os repositorios
- **Novos repositorios funcionam automaticamente:** nao precisa
  registrar cada novo repositorio individualmente
- **Rotacao simplificada:** ao trocar a chave SSH, atualize
  apenas o Credential Template
- **Menos Secrets:** em vez de N Secrets (um por repositorio),
  apenas 1 Secret cobre tudo

---

## Diferenca: Secret "repository" vs "repo-creds"

O Argo CD usa **labels** em Secrets do Kubernetes para distinguir
entre registros individuais de repositorio e Credential Templates.
A diferenca esta na label `argocd.argoproj.io/secret-type`.

### Secret do tipo "repository"

Registra **um unico repositorio** com suas credenciais especificas.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-individual
  namespace: argocd
  labels:
    # Label que identifica este Secret como um repositorio individual
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  # Tipo de conexao (git ou helm)
  type: git
  # URL exata do repositorio
  url: git@github.com:minha-org/repo-a.git
  # Chave SSH privada para autenticacao
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...conteudo da chave...
    -----END OPENSSH PRIVATE KEY-----
```

### Secret do tipo "repo-creds"

Registra um **Credential Template** que cobre todos os
repositorios que correspondam ao padrao de URL.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: creds-minha-org
  namespace: argocd
  labels:
    # Label que identifica este Secret como um Credential Template
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  # Tipo de conexao
  type: git
  # URL base (pattern) - cobre todos os repos desta organizacao
  url: git@github.com:minha-org
  # Chave SSH usada para todos os repos da organizacao
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...conteudo da chave...
    -----END OPENSSH PRIVATE KEY-----
```

### Comparacao direta

| Aspecto | repository | repo-creds |
|---------|-----------|-----------|
| **Label** | `argocd.argoproj.io/secret-type: repository` | `argocd.argoproj.io/secret-type: repo-creds` |
| **Cobertura** | 1 repositorio especifico | Todos os repos que correspondem a URL base |
| **URL** | URL completa do repositorio | URL base (prefixo) da organizacao |
| **Quando usar** | Repositorio com credencial unica/diferente | Organizacao com credencial compartilhada |
| **Escalabilidade** | Nao escala (1 Secret por repo) | Escala (1 Secret para N repos) |

### Precedencia

Se existir tanto um registro individual (repository) quanto um
Credential Template (repo-creds) para o mesmo repositorio, o
**registro individual tem precedencia**. Isso permite criar
excecoes: a maioria dos repos usa o template, mas um repo
especifico pode ter credenciais diferentes.

---

## Como Funciona o Pattern Matching

O Credential Template usa a URL base como **padrao de
correspondencia** (pattern). O Argo CD verifica se a URL do
repositorio referenciado pela Application **comeca com** a URL
base do template.

### Exemplo de correspondencia

```
URL base do template: git@github.com:minha-org

Repositorios que correspondem:
  git@github.com:minha-org/repo-a.git        (corresponde)
  git@github.com:minha-org/repo-b.git        (corresponde)
  git@github.com:minha-org/infra-config.git  (corresponde)
  git@github.com:minha-org/frontend.git      (corresponde)

Repositorios que NAO correspondem:
  git@github.com:outra-org/repo-x.git        (organizacao diferente)
  https://github.com/minha-org/repo-a.git    (protocolo diferente: HTTPS vs SSH)
  git@gitlab.com:minha-org/repo-a.git        (host diferente: GitLab vs GitHub)
```

### Regra de correspondencia

A correspondencia e feita por **prefixo de string**. O Argo CD
verifica se a URL do repositorio comeca exatamente com a URL
base definida no Credential Template. Por isso:

- O protocolo importa (`git@` vs `https://`)
- O host importa (`github.com` vs `gitlab.com`)
- A organizacao importa (`minha-org` vs `outra-org`)

---

## Autenticacao via SSH

O metodo mais comum para autenticar repositorios privados no
Argo CD e o **SSH** (Secure Shell). Ele usa um par de chaves
criptograficas: uma chave privada (armazenada no Argo CD) e
uma chave publica (registrada no GitHub/GitLab).

### Como gerar uma chave SSH

```bash
# Gerar um par de chaves Ed25519 (recomendado)
# -t: tipo do algoritmo (ed25519 e moderno e seguro)
# -C: comentario identificador (geralmente o email)
# -f: caminho onde salvar a chave
ssh-keygen -t ed25519 -C "argocd@minha-org" -f ~/.ssh/argocd_key
```

Esse comando gera dois arquivos:

| Arquivo | Tipo | Onde usar |
|---------|------|-----------|
| `~/.ssh/argocd_key` | Chave privada | Armazenar no Secret do Argo CD (no campo `sshPrivateKey`) |
| `~/.ssh/argocd_key.pub` | Chave publica | Adicionar no GitHub como Deploy Key |

### Como adicionar a chave publica no GitHub

1. Acesse o repositorio no GitHub (ou as configuracoes da
   organizacao)
2. Va em **Settings** -> **Deploy keys** (para repo individual)
   ou **Settings** -> **SSH and GPG keys** (para conta/org)
3. Clique em **Add deploy key**
4. Cole o conteudo de `~/.ssh/argocd_key.pub`
5. Marque **Allow write access** apenas se o Argo CD precisar
   escrever no repositorio (geralmente nao e necessario)
6. Clique em **Add key**

### Verificar o conteudo da chave publica

```bash
# Exibir a chave publica para copiar
cat ~/.ssh/argocd_key.pub
```

Saida tipica:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... argocd@minha-org
```

### Registrar a chave privada no Argo CD

A chave privada pode ser registrada de duas formas:

**Via CLI:**

```bash
# Registrar repositorio individual com chave SSH
argocd repo add git@github.com:minha-org/repo-a.git \
  --ssh-private-key-path ~/.ssh/argocd_key

# Registrar Credential Template com chave SSH
argocd repocreds add git@github.com:minha-org \
  --ssh-private-key-path ~/.ssh/argocd_key
```

**Via YAML (Secret):**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: creds-minha-org-ssh
  namespace: argocd
  labels:
    # Tipo repo-creds para Credential Template
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  type: git
  url: git@github.com:minha-org
  # Conteudo completo da chave privada
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAA...
    ...conteudo da chave privada...
    -----END OPENSSH PRIVATE KEY-----
```

> **Atencao:** nunca versione a chave privada no Git. Em ambiente
> de producao, use ferramentas como Sealed Secrets, External
> Secrets ou Vault para gerenciar Secrets de forma segura.

---

## Delete Cascade vs Non-Cascade

Ao deletar uma Application do Argo CD, ha dois comportamentos
possiveis: **cascade** (padrao) e **non-cascade**. A diferenca
e critica e pode causar perda de recursos em producao se nao
compreendida corretamente.

### Cascade (padrao)

O comportamento padrao ao deletar uma Application e o **cascade**.
Ele deleta tanto a Application **quanto todos os recursos
Kubernetes** que ela gerencia no cluster de destino.

```
Antes do delete cascade:
  Application "demo-app" (existe no Argo CD)
    |
    +-- Deployment "demo-api" (existe no cluster)
    +-- Service "demo-api-svc" (existe no cluster)
    +-- ConfigMap "demo-config" (existe no cluster)

Apos delete cascade:
  Application "demo-app" (DELETADA)
    |
    +-- Deployment "demo-api" (DELETADO)
    +-- Service "demo-api-svc" (DELETADO)
    +-- ConfigMap "demo-config" (DELETADO)
```

Comando:

```bash
# Delete com cascade (padrao - nao precisa especificar)
argocd app delete demo-app

# Ou explicitamente
argocd app delete demo-app --cascade=true
```

### Non-Cascade

O delete non-cascade remove **apenas a Application** do Argo CD,
mas **mantem todos os recursos Kubernetes** no cluster de destino.
Os recursos continuam rodando, apenas nao sao mais gerenciados
pelo Argo CD.

```
Antes do delete non-cascade:
  Application "demo-app" (existe no Argo CD)
    |
    +-- Deployment "demo-api" (existe no cluster)
    +-- Service "demo-api-svc" (existe no cluster)
    +-- ConfigMap "demo-config" (existe no cluster)

Apos delete non-cascade:
  Application "demo-app" (DELETADA)
    |
    +-- Deployment "demo-api" (PERMANECE no cluster)
    +-- Service "demo-api-svc" (PERMANECE no cluster)
    +-- ConfigMap "demo-config" (PERMANECE no cluster)
```

Comando:

```bash
# Delete sem cascade (mantem recursos no cluster)
argocd app delete demo-app --cascade=false
```

### Quando usar cada um

| Cenario | Modo recomendado | Justificativa |
|---------|-----------------|---------------|
| **Remover aplicacao completamente** | Cascade (padrao) | Voce quer que a aplicacao e seus recursos deixem de existir |
| **Migrar gerenciamento para outro Argo CD** | Non-cascade | Recursos devem continuar rodando enquanto o novo Argo CD assume |
| **Trocar de repositorio Git** | Non-cascade | Manter recursos ativos, recriar Application apontando para novo repo |
| **Limpeza de ambiente de teste** | Cascade | Remover tudo para liberar recursos |
| **Desassociar do Argo CD sem downtime** | Non-cascade | Aplicacao continua rodando, so perde o gerenciamento GitOps |
| **Transferir ownership entre projetos** | Non-cascade | Recursos permanecem, nova Application em outro AppProject assume |

### Cuidados importantes

- **Cascade e destrutivo:** certifique-se de que deseja remover
  os recursos do cluster antes de executar
- **Non-cascade gera recursos "orfaos":** os recursos continuam
  existindo mas sem gerenciamento GitOps. Ninguem mais monitora
  drift ou faz reconciliacao
- **Em producao:** sempre confirme com a equipe antes de executar
  delete cascade. Considere usar non-cascade primeiro e verificar
  antes de limpar manualmente

---

## Exemplo YAML do Credential Template

Abaixo, um exemplo completo de Credential Template usando
autenticacao SSH, com comentarios explicativos:

```yaml
# Recurso do tipo Secret (padrao Kubernetes)
apiVersion: v1
kind: Secret
metadata:
  # Nome descritivo do Credential Template
  name: creds-github-minha-org
  # Deve estar no namespace do Argo CD
  namespace: argocd
  labels:
    # Label OBRIGATORIA que identifica este Secret
    # como um Credential Template (repo-creds)
    # Se essa label estiver errada ou ausente,
    # o Argo CD nao reconhece o Secret como template
    argocd.argoproj.io/secret-type: repo-creds
# Tipo Opaque (Secret generico do Kubernetes)
type: Opaque
# stringData permite inserir valores em texto puro
# (Kubernetes converte para base64 automaticamente)
stringData:
  # Tipo de repositorio (git ou helm)
  type: git
  # URL base da organizacao no GitHub
  # TODOS os repositorios que comecam com essa URL
  # usarao automaticamente as credenciais abaixo
  url: git@github.com:minha-org
  # Chave SSH privada para autenticacao
  # Gerada com: ssh-keygen -t ed25519 -C "argocd" -f argocd_key
  # A chave publica correspondente deve estar registrada no GitHub
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
    c2gtZWQyNTUxOQAAACBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    AAAAQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxAAAA
    DmFyZ29jZEBtaW5oYS1vcmcBAgMEBQ==
    -----END OPENSSH PRIVATE KEY-----
```

### Aplicar o Credential Template

```bash
# Aplicar o Secret no cluster
kubectl apply -f credential-template.yaml

# Verificar que o Argo CD reconheceu o template
argocd repocreds list
```

### Alternativa via CLI

```bash
# Criar Credential Template via CLI (sem YAML)
argocd repocreds add git@github.com:minha-org \
  --ssh-private-key-path ~/.ssh/argocd_key
```

---

## Resumo

| Conceito | Descricao |
|----------|-----------|
| **Credential Template** | Secret que fornece credenciais automaticamente para todos os repos de uma organizacao |
| **Label repo-creds** | `argocd.argoproj.io/secret-type: repo-creds` identifica o Secret como template |
| **Label repository** | `argocd.argoproj.io/secret-type: repository` identifica o Secret como registro individual |
| **Pattern matching** | URL base do template cobre todos os repos que comecam com aquela URL |
| **Precedencia** | Registro individual (repository) tem prioridade sobre template (repo-creds) |
| **SSH** | Metodo de autenticacao usando par de chaves (privada no Argo CD, publica no GitHub) |
| **Cascade (padrao)** | Deleta Application E todos os recursos Kubernetes gerenciados |
| **Non-cascade** | Deleta apenas a Application, recursos Kubernetes permanecem no cluster |
| **argocd repocreds add** | Comando CLI para criar Credential Templates |
| **argocd app delete --cascade=false** | Comando CLI para delete non-cascade |

---

## Referencias

- [Argo CD - Repository Credentials](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repository-credentials)
- [Argo CD - Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [Argo CD - SSH Key Authentication](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/#ssh-private-key-credential)
- [Argo CD - App Deletion](https://argo-cd.readthedocs.io/en/stable/user-guide/app_deletion/)
- [GitHub - Deploy Keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys)
