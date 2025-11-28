# Demo API

API universal para testes de recursos Kubernetes (Níveis 1, 2 e 3).

## Stack

- NestJS 11 com Fastify
- Drizzle ORM
- PostgreSQL 17
- Prometheus Metrics
- TypeScript 5.9
- Node.js 22+
- pnpm 10+

---

## Setup do Projeto

### 1. Instalar dependências

```bash
cd apps/demo-api
pnpm install
```

### 2. Configurar variáveis de ambiente

Copie o arquivo de exemplo e configure:

```bash
cp .env.example .env
```

Edite `.env` com suas configurações:

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://demo_user:demo_password@localhost:5432/demo_db
APP_NAME=demo-api
```

### 3. Iniciar PostgreSQL local

```bash
docker compose -f docker-compose.dev.yml up -d
```

### 4. Gerar e executar migrations

```bash
pnpm db:generate
pnpm db:migrate
```

Ou use `pnpm db:push` para sincronizar schema diretamente (desenvolvimento).

### 5. Iniciar aplicação

```bash
pnpm start:dev
```

---

## Endpoints

### Nível 1 (Fundamentos K8s)

| Método | Rota | Bloco | Descrição |
|--------|------|-------|-----------|
| GET | `/` | - | Info da aplicação |
| GET | `/health` | C | Liveness/Startup probe |
| GET | `/ready` | C | Readiness probe |
| GET | `/health/unstable` | C | Falha 50% das vezes |
| GET | `/health/slow?ms=N` | C | Delay de N ms |
| POST | `/crash` | C | Força crash (exit 1) |
| GET | `/env` | A | Lista variáveis de ambiente |
| GET | `/stress/cpu?duration=N` | B | Stress CPU por N segundos |
| GET | `/stress/memory?mb=N` | B | Aloca N MB |
| POST | `/stress/write` | B | Escrita intensiva |
| GET | `/files` | D | Lista arquivos |
| GET | `/files/:name` | D | Lê arquivo |
| POST | `/files` | D | Cria arquivo |
| DELETE | `/files/:name` | D | Remove arquivo |

### Nível 2/3 (Persistência e Observabilidade)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/users` | Criar usuário |
| GET | `/users` | Listar todos usuários |
| GET | `/users/:id` | Buscar usuário por ID |
| PATCH | `/users/:id` | Atualizar usuário |
| DELETE | `/users/:id` | Remover usuário |
| GET | `/metrics` | Métricas Prometheus |

---

## Scripts Disponíveis

```bash
pnpm build              # Build da aplicação
pnpm start              # Inicia aplicação
pnpm start:dev          # Inicia com hot-reload
pnpm start:debug        # Inicia com debug
pnpm start:prod         # Inicia em produção

pnpm db:generate        # Gera migrations
pnpm db:migrate         # Executa migrations
pnpm db:push            # Sincroniza schema (dev)
pnpm db:studio          # Abre Drizzle Studio
```

---

## Build e Deploy

### Docker Local

```bash
docker build -t demo-api:v1 .
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  demo-api:v1
```

### Docker com Compose

```bash
docker compose -f docker-compose.dev.yml up -d
docker build -t demo-api:v1 .
docker run --network demo-api_default -p 3000:3000 \
  -e DATABASE_URL=postgresql://demo_user:demo_password@postgres:5432/demo_db \
  demo-api:v1
```

---

## Recursos Kubernetes Cobertos

### Nível 1 - Fundamentos

- **Bloco A:** Deployment, ConfigMap, Secret, Rolling Update
- **Bloco B:** HPA, Metrics Server, Stress Test
- **Bloco C:** Probes (Startup, Liveness, Readiness), Self-Healing
- **Bloco D:** StorageClass, PersistentVolume, PersistentVolumeClaim

### Nível 2 - Cloud e Persistência

- **M1-A:** Deploy em Cloud Providers (DigitalOcean, AWS EKS)
- **M1-B:** RBAC, Service Accounts, Terraform
- **M2-A:** StatefulSet, PostgreSQL, DaemonSet, Operators
- **M2-B:** CI/CD com GitHub Actions

### Nível 3 - Auto Scaling

- **M1:** Cluster Autoscaler, HPA, Node Groups
- **M2:** Karpenter, NodePools, Topology Spread, Affinity

---

## Observabilidade

A aplicação expõe métricas Prometheus em `/metrics`:

- Métricas padrão do Node.js (memory, CPU, event loop)
- Métricas HTTP (request count, duration, status codes)
- Métricas customizadas da aplicação

Exemplo de scrape config para Prometheus:

```yaml
scrape_configs:
  - job_name: 'demo-api'
    static_configs:
      - targets: ['demo-api:3000']
    metrics_path: '/metrics'
```
