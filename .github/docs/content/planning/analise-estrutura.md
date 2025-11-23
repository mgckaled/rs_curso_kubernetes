<!-- markdownlint-disable -->

# Análise de Estrutura do Repositório

## Contexto

Repositório de estudos para a **Formação Kubernetes da Rocketseat**, com 4 níveis de conteúdo estruturados em módulos e blocos.

---

## 1. Estrutura de Pastas

### Nomenclatura Abreviada

| Abreviação | Significado |
|------------|-------------|
| `n1`, `n2`... | Nível 1, Nível 2... |
| `m1`, `m2`... | Módulo 1, Módulo 2... |
| `b-a`, `b-b`... | Bloco A, Bloco B... |

### Estrutura Proposta

```txt
k8s/
├── .claude/
│   └── about.md
├── apps/
│   └── demo-api/           # Aplicação universal de testes
├── n1/
│   ├── m1/
│   │   ├── b-a/            # Conhecendo o Kubernetes
│   │   └── b-b/            # Orquestrando Containers
│   └── m2/
│       ├── b-a/            # Deployment
│       ├── b-b/            # HPA
│       ├── b-c/            # Probes
│       └── b-d/            # Volumes
├── n2/
│   ├── m1/
│   │   ├── b-a/            # K8s Gerenciado (EKS)
│   │   └── b-b/            # RBAC
│   └── m2/
│       ├── b-a/            # StatefulSet e DaemonSet
│       └── b-b/            # Pipeline
├── n3/
│   ├── m1/                 # Auto Escala (bloco único)
│   └── m2/
│       ├── b-a/            # Karpenter Roles
│       └── b-b/            # Karpenter Instalação
├── docs/
│   └── aws-setup/          # Guias de config na AWS Console
├── first-cluster/
│   └── kind.yaml
└── README.md
```

---

## 2. Monorepo vs Multi-repo

**Decisão: Monorepo**

| Aspecto | Justificativa |
|---------|---------------|
| Contexto | Mantém tudo junto para referência |
| Dependências | Manifests K8s não têm deps complexas |
| Navegação | Fácil buscar exemplos |
| Tamanho | Manifests YAML são leves |

---

## 3. Integração AWS

Configurações AWS serão feitas via **Console Web**, não via Terraform/IaC.

| Serviço | Impacto no Repo |
|---------|-----------------|
| EKS | Apenas manifests K8s |
| IAM Roles | Documentar em `docs/aws-setup/` |
| ECR | Não gera arquivos locais |
| ALB/Load Balancers | Annotations nos manifests |
