<!-- markdownlint-disable -->

# Entendendo Secrets no Kubernetes

## Contexto

Secrets são objetos do Kubernetes projetados para armazenar dados sensíveis como senhas, tokens, chaves SSH e certificados. Este documento explica como criar, usar e gerenciar Secrets de forma segura.

---

## O que são Secrets?

Secrets permitem armazenar e gerenciar informações sensíveis separadamente dos manifestos de aplicação, reduzindo o risco de exposição acidental de dados confidenciais.

### Diferença: Secret vs ConfigMap

| Aspecto | Secret | ConfigMap |
|---------|--------|-----------|
| **Propósito** | Dados sensíveis (senhas, tokens) | Configurações não sensíveis |
| **Codificação** | Base64 obrigatório | Texto plano |
| **Segurança** | Pode ser criptografado em repouso | Sem criptografia |
| **Visibilidade** | Oculto em `kubectl describe` | Visível em `kubectl describe` |
| **Uso típico** | DB_PASSWORD, API_KEY, certificados | APP_NAME, LOG_LEVEL, features |

---

## Por que Base64?

### Base64 NÃO é Criptografia!

Base64 é apenas **codificação reversível**, não oferece segurança por si só:

```bash
# Codificar
echo -n "password123" | base64
# Output: cGFzc3dvcmQxMjM=

# Decodificar (qualquer um pode fazer!)
echo "cGFzc3dvcmQxMjM=" | base64 -d
# Output: password123
```

### Por que o Kubernetes usa Base64?

1. **Suporte a dados binários**: Permite armazenar certificados, chaves SSH, etc.
2. **Evita problemas com caracteres especiais**: YAML não lida bem com caracteres especiais em strings
3. **Formato uniforme**: Consistência na API do Kubernetes
4. **Facilita transmissão**: Evita problemas de encoding em diferentes sistemas

**IMPORTANTE**: A segurança real vem de controles de acesso (RBAC), criptografia em repouso e ferramentas externas, não do Base64!

---

## Criando Senhas para Secrets

### Método 1: PowerShell (Windows)

#### Gerar senha aleatória

```powershell
# Função para gerar senha aleatória
function New-RandomPassword {
    param([int]$Length = 16)
    -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $Length | % {[char]$_})
}

# Gerar senha
$password = New-RandomPassword -Length 20
Write-Host "Senha gerada: $password"
```

#### Codificar para Base64

```powershell
# Codificar string para Base64
function ConvertTo-Base64 {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    [Convert]::ToBase64String($bytes)
}

# Exemplo
$password = "MySecureDB2025!"
$base64 = ConvertTo-Base64 -Text $password
Write-Host "Base64: $base64"
```

#### Decodificar Base64

```powershell
# Decodificar Base64 para string
function ConvertFrom-Base64 {
    param([string]$Base64)
    $bytes = [System.Convert]::FromBase64String($Base64)
    [System.Text.Encoding]::UTF8.GetString($bytes)
}

# Exemplo
$decoded = ConvertFrom-Base64 -Base64 "TXlTZWN1cmVEQjIwMjUh"
Write-Host "Decodificado: $decoded"
```

### Método 2: Bash (Linux/Mac)

#### Gerar senha aleatória

```bash
# Usando openssl
openssl rand -base64 16

# Ou usando /dev/urandom
tr -dc A-Za-z0-9 </dev/urandom | head -c 20; echo
```

#### Codificar para Base64

```bash
# Codificar string
echo -n "MySecureDB2025!" | base64

# IMPORTANTE: use -n para não incluir newline!
```

#### Decodificar Base64

```bash
# Decodificar
echo "TXlTZWN1cmVEQjIwMjUh" | base64 -d
```

---

## Criando o Arquivo Secret

### Opção 1: Usando `data` (valores em Base64)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-api-secret
  namespace: demo
  labels:
    app.kubernetes.io/name: demo-api
    app.kubernetes.io/component: secret
type: Opaque
data:
  # Valores já codificados em base64
  DB_HOST: bG9jYWxob3N0                              # "localhost"
  DB_USER: ZGVtb191c2Vy                              # "demo_user"
  DB_PASSWORD: c3VwZXJfc2VjcmV0X3Bhc3N3b3JkXzEyMw==  # "super_secret_password_123"
  API_KEY: YXBpX2tleV9leGFtcGxlXzEyMzQ1              # "api_key_example_12345"
```

### Opção 2: Usando `stringData` (Kubernetes codifica automaticamente)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-api-secret
  namespace: demo
type: Opaque
stringData:
  # Valores em texto plano - Kubernetes codifica automaticamente!
  DB_HOST: "localhost"
  DB_USER: "demo_user"
  DB_PASSWORD: "super_secret_password_123"
  API_KEY: "api_key_example_12345"
```

**Vantagem do stringData**:

- Mais fácil de escrever e ler
- Kubernetes converte automaticamente para base64 ao criar o Secret
- Após criação, aparece em `data` (base64) no cluster

**Desvantagem**:

- Valores ficam em texto plano no arquivo YAML
- Risco maior se commitar acidentalmente no Git

---

## Tipos de Secrets

### Opaque (Genérico)

Tipo padrão para dados arbitrários:

```yaml
type: Opaque
data:
  username: dXNlcg==
  password: cGFzcw==
```

### kubernetes.io/tls

Para certificados TLS:

```yaml
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # Certificado
  tls.key: LS0tLS1CRUdJTi...  # Chave privada
```

### kubernetes.io/dockerconfigjson

Para credenciais de registry Docker:

```yaml
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6...
```

### kubernetes.io/basic-auth

Para autenticação básica:

```yaml
type: kubernetes.io/basic-auth
stringData:
  username: admin
  password: secret123
```

### kubernetes.io/ssh-auth

Para chaves SSH:

```yaml
type: kubernetes.io/ssh-auth
data:
  ssh-privatekey: LS0tLS1CRUdJTi...
```

---

## Aplicando e Verificando Secrets

### Criar Secret

```bash
# Aplicar manifest
kubectl apply -f manifests/03-secret.yaml

# Verificar criação
kubectl get secret -n demo
```

Saída esperada:
```
NAME              TYPE     DATA   AGE
demo-api-secret   Opaque   4      10s
```

### Ver detalhes (valores ocultos)

```bash
kubectl describe secret demo-api-secret -n demo
```

Saída:
```
Name:         demo-api-secret
Namespace:    demo
Type:         Opaque

Data
====
API_KEY:      21 bytes
DB_HOST:      9 bytes
DB_PASSWORD:  25 bytes
DB_USER:      9 bytes
```

**Nota**: `describe` mostra apenas o tamanho, não os valores!

### Ver YAML completo

```bash
kubectl get secret demo-api-secret -n demo -o yaml
```

Saída mostrará valores em base64:
```yaml
apiVersion: v1
data:
  API_KEY: YXBpX2tleV9leGFtcGxlXzEyMzQ1
  DB_HOST: bG9jYWxob3N0
  DB_PASSWORD: c3VwZXJfc2VjcmV0X3Bhc3N3b3JkXzEyMw==
  DB_USER: ZGVtb191c2Vy
kind: Secret
metadata:
  name: demo-api-secret
  namespace: demo
type: Opaque
```

---

## Decodificando Valores do Secret

### PowerShell

```powershell
# Obter valor em base64
$base64 = kubectl get secret demo-api-secret -n demo -o jsonpath='{.data.DB_PASSWORD}'

# Decodificar
$bytes = [System.Convert]::FromBase64String($base64)
$password = [System.Text.Encoding]::UTF8.GetString($bytes)
Write-Host "DB_PASSWORD: $password"
```

### Bash

```bash
# Decodificar DB_PASSWORD
kubectl get secret demo-api-secret -n demo -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
echo ""

# Decodificar API_KEY
kubectl get secret demo-api-secret -n demo -o jsonpath='{.data.API_KEY}' | base64 -d
echo ""

# Decodificar todos os valores
kubectl get secret demo-api-secret -n demo -o json | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
```

### Ver todos os valores decodificados (com jq)

```bash
# Instalar jq primeiro (se não tiver)
# Windows: choco install jq
# Mac: brew install jq
# Linux: apt-get install jq

kubectl get secret demo-api-secret -n demo -o json | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
```

---

## Usando Secrets nos Pods

### Opção 1: Como variáveis de ambiente individuais

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
spec:
  containers:
  - name: app
    image: demo-api:v1
    env:
    # Injetar cada variável individualmente
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: demo-api-secret
          key: DB_HOST
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: demo-api-secret
          key: DB_PASSWORD
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: demo-api-secret
          key: API_KEY
```

**O que acontece:**
- Kubernetes decodifica automaticamente o base64
- Container recebe `DB_PASSWORD="super_secret_password_123"` (texto plano)
- Aplicação acessa via `process.env.DB_PASSWORD`

### Opção 2: Todas as chaves como variáveis de ambiente

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
spec:
  containers:
  - name: app
    image: demo-api:v1
    envFrom:
    # Injetar TODAS as chaves do Secret como variáveis
    - secretRef:
        name: demo-api-secret
```

**Resultado**: Todas as chaves viram variáveis de ambiente automaticamente.

### Opção 3: Como arquivos montados (Volume)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
spec:
  containers:
  - name: app
    image: demo-api:v1
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: demo-api-secret
```

**Resultado**:
- Cada chave vira um arquivo em `/etc/secrets/`
- `/etc/secrets/DB_PASSWORD` contém "super_secret_password_123"
- `/etc/secrets/API_KEY` contém "api_key_example_12345"
- Valores já decodificados

---

## Criando Secrets via kubectl

### Método imperativo (sem arquivo YAML)

```bash
# Criar Secret diretamente
kubectl create secret generic demo-api-secret \
  --from-literal=DB_HOST=localhost \
  --from-literal=DB_USER=demo_user \
  --from-literal=DB_PASSWORD=super_secret_password_123 \
  --from-literal=API_KEY=api_key_example_12345 \
  -n demo

# Criar Secret de arquivo
kubectl create secret generic app-config \
  --from-file=config.json \
  -n demo

# Criar Secret TLS
kubectl create secret tls my-tls-secret \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key \
  -n demo
```

---

## Script Completo para Gerar Secrets

### PowerShell

Salve como `generate-secrets.ps1`:

```powershell
# generate-secrets.ps1
# Script para gerar senhas aleatórias e codificar em Base64

function New-RandomPassword {
    param([int]$Length = 16)
    $chars = (65..90) + (97..122) + (48..57)  # A-Z, a-z, 0-9
    -join ($chars | Get-Random -Count $Length | ForEach-Object {[char]$_})
}

function ConvertTo-Base64 {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    [Convert]::ToBase64String($bytes)
}

Write-Host "=== Gerador de Secrets para Kubernetes ===" -ForegroundColor Green
Write-Host ""

# Gerar senhas
$dbHost = "localhost"
$dbUser = "demo_user"
$dbPassword = New-RandomPassword -Length 24
$apiKey = "api-key-$(New-RandomPassword -Length 32)"

Write-Host "Valores em texto plano (GUARDE EM LOCAL SEGURO):" -ForegroundColor Yellow
Write-Host "DB_HOST: $dbHost"
Write-Host "DB_USER: $dbUser"
Write-Host "DB_PASSWORD: $dbPassword"
Write-Host "API_KEY: $apiKey"
Write-Host ""

Write-Host "Valores em Base64 (copie para o Secret YAML):" -ForegroundColor Cyan
Write-Host "DB_HOST: $(ConvertTo-Base64 $dbHost)"
Write-Host "DB_USER: $(ConvertTo-Base64 $dbUser)"
Write-Host "DB_PASSWORD: $(ConvertTo-Base64 $dbPassword)"
Write-Host "API_KEY: $(ConvertTo-Base64 $apiKey)"
Write-Host ""

# Gerar arquivo YAML
$yaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: demo-api-secret
  namespace: demo
  labels:
    app.kubernetes.io/name: demo-api
    app.kubernetes.io/component: secret
type: Opaque
data:
  DB_HOST: $(ConvertTo-Base64 $dbHost)
  DB_USER: $(ConvertTo-Base64 $dbUser)
  DB_PASSWORD: $(ConvertTo-Base64 $dbPassword)
  API_KEY: $(ConvertTo-Base64 $apiKey)
"@

$outputFile = "03-secret-generated.yaml"
$yaml | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Arquivo YAML gerado: $outputFile" -ForegroundColor Green
```

Execute:
```powershell
.\generate-secrets.ps1
```

### Bash

Salve como `generate-secrets.sh`:

```bash
#!/bin/bash
# generate-secrets.sh
# Script para gerar senhas aleatórias e codificar em Base64

echo "=== Gerador de Secrets para Kubernetes ==="
echo ""

# Gerar senhas
DB_HOST="localhost"
DB_USER="demo_user"
DB_PASSWORD=$(openssl rand -base64 18)
API_KEY="api-key-$(openssl rand -hex 16)"

echo "Valores em texto plano (GUARDE EM LOCAL SEGURO):"
echo "DB_HOST: $DB_HOST"
echo "DB_USER: $DB_USER"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "API_KEY: $API_KEY"
echo ""

echo "Valores em Base64 (copie para o Secret YAML):"
echo "DB_HOST: $(echo -n "$DB_HOST" | base64)"
echo "DB_USER: $(echo -n "$DB_USER" | base64)"
echo "DB_PASSWORD: $(echo -n "$DB_PASSWORD" | base64)"
echo "API_KEY: $(echo -n "$API_KEY" | base64)"
echo ""

# Gerar arquivo YAML
cat > 03-secret-generated.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: demo-api-secret
  namespace: demo
  labels:
    app.kubernetes.io/name: demo-api
    app.kubernetes.io/component: secret
type: Opaque
data:
  DB_HOST: $(echo -n "$DB_HOST" | base64)
  DB_USER: $(echo -n "$DB_USER" | base64)
  DB_PASSWORD: $(echo -n "$DB_PASSWORD" | base64)
  API_KEY: $(echo -n "$API_KEY" | base64)
EOF

echo "Arquivo YAML gerado: 03-secret-generated.yaml"
```

Execute:
```bash
chmod +x generate-secrets.sh
./generate-secrets.sh
```

---

## Segurança de Secrets

### Base64 NÃO oferece segurança!

Qualquer pessoa com acesso ao cluster pode decodificar:

```bash
kubectl get secret demo-api-secret -n demo -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

### Boas Práticas

#### 1. Nunca commitar Secrets no Git

```gitignore
# .gitignore
*secret*.yaml
*secret*.yml
03-secret.yaml
```

Alternativa: Commitar apenas templates com placeholders:

```yaml
# 03-secret.yaml.example
apiVersion: v1
kind: Secret
metadata:
  name: demo-api-secret
type: Opaque
stringData:
  DB_PASSWORD: "<REPLACE_ME>"
  API_KEY: "<REPLACE_ME>"
```

#### 2. Use RBAC para restringir acesso

```yaml
# Apenas ServiceAccounts específicos podem ler secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: demo
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
```

#### 3. Habilite Encryption at Rest

Configure o kube-apiserver para criptografar dados no etcd:

```yaml
# encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: <base64-encoded-32-byte-key>
    - identity: {}
```

#### 4. Use ferramentas externas para produção

**Sealed Secrets (Bitnami)**:
- Criptografa secrets para commit seguro no Git
- Apenas o cluster consegue descriptografar

**External Secrets Operator**:
- Sincroniza secrets de:
  - HashiCorp Vault
  - AWS Secrets Manager
  - Azure Key Vault
  - GCP Secret Manager

**SOPS (Mozilla)**:
- Criptografa arquivos YAML completos
- Integra com AWS KMS, GCP KMS, Azure Key Vault

#### 5. Rotação regular de Secrets

```bash
# 1. Gerar novo secret
kubectl create secret generic demo-api-secret-v2 --from-literal=DB_PASSWORD=new_password -n demo

# 2. Atualizar Deployment para usar novo secret
kubectl set env deployment/demo-api --from=secret/demo-api-secret-v2 -n demo

# 3. Deletar secret antigo
kubectl delete secret demo-api-secret -n demo

# 4. Renomear novo secret
kubectl get secret demo-api-secret-v2 -n demo -o yaml | sed 's/demo-api-secret-v2/demo-api-secret/' | kubectl apply -f -
```

#### 6. Auditoria de acesso

```bash
# Ver quem acessou secrets (requer audit logging habilitado)
kubectl get events --field-selector involvedObject.kind=Secret -n demo
```

---

## Troubleshooting

### Secret não monta no Pod

```bash
# 1. Verificar se o Secret existe
kubectl get secret demo-api-secret -n demo

# 2. Verificar se o namespace está correto
kubectl describe pod <pod-name> -n demo

# 3. Ver eventos do pod
kubectl get events -n demo --field-selector involvedObject.name=<pod-name>
```

### Valores não decodificam corretamente

```bash
# Verificar encoding do arquivo YAML
file manifests/03-secret.yaml

# Deve ser UTF-8, não UTF-16 ou outros
```

### Secret grande demais

Secrets têm limite de 1MB. Para dados maiores, use Volumes ou object storage (S3, GCS).

---

## Comparação: Diferentes Métodos de Injeção

| Método | Vantagens | Desvantagens | Quando usar |
|--------|-----------|--------------|-------------|
| **Variáveis de ambiente** | Fácil, padrão 12-factor app | Pode vazar em logs/dumps | Maioria dos casos |
| **Volume montado** | Atualização automática, seguro | Mais complexo | Certificados, configs grandes |
| **envFrom** | Menos verboso | Injeta tudo (pode poluir) | Muitas variáveis relacionadas |

---

## Comandos Úteis - Referência Rápida

```bash
# Criar
kubectl create secret generic <name> --from-literal=key=value -n <ns>
kubectl apply -f secret.yaml

# Listar
kubectl get secrets -n <ns>
kubectl get secret <name> -n <ns> -o yaml

# Detalhar (não mostra valores)
kubectl describe secret <name> -n <ns>

# Decodificar valor
kubectl get secret <name> -n <ns> -o jsonpath='{.data.KEY}' | base64 -d

# Editar
kubectl edit secret <name> -n <ns>

# Deletar
kubectl delete secret <name> -n <ns>

# Criar de arquivo
kubectl create secret generic <name> --from-file=./file.txt -n <ns>

# Criar TLS
kubectl create secret tls <name> --cert=cert.crt --key=cert.key -n <ns>
```

---

## Resumo

| Conceito | Descrição |
|----------|-----------|
| **Secret** | Objeto Kubernetes para dados sensíveis |
| **Base64** | Codificação (NÃO criptografia) |
| **type: Opaque** | Tipo genérico para dados arbitrários |
| **data** | Valores em base64 |
| **stringData** | Valores em texto plano (K8s codifica) |
| **secretKeyRef** | Referência para usar no Pod |
| **RBAC** | Controle de acesso a Secrets |
| **Encryption at Rest** | Criptografia real no etcd |

Secrets são fundamentais para segurança no Kubernetes, mas devem ser combinados com RBAC, criptografia e ferramentas externas para proteção adequada em produção.