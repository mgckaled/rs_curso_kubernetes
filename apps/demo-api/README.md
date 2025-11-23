# Demo API

API universal para testes de recursos Kubernetes (Módulo 2, Nível 1).

---

## Setup do Projeto

### 1. Inicializar o projeto

```bash
cd apps/demo-api
pnpm init
```

### 2. Instalar dependências de produção

```bash
pnpm add @nestjs/common @nestjs/core @nestjs/platform-fastify @nestjs/terminus fastify reflect-metadata rxjs
```

### 3. Instalar dependências de desenvolvimento

```bash
pnpm add -D @nestjs/cli @nestjs/schematics @nestjs/testing @types/node typescript
```

### 4. Scripts do package.json

Adicione manualmente ao `package.json`:

```json
{
  "scripts": {
    "build": "nest build",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:prod": "node dist/main"
  }
}
```

---

## Endpoints

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

---

## Build e Execução

### Desenvolvimento

```bash
pnpm start:dev
```

### Produção

```bash
pnpm build
pnpm start:prod
```

### Docker

```bash
docker build -t demo-api:v1 .
docker run -p 3000:3000 demo-api:v1
```

---

## Recursos K8s Cobertos

- **Bloco A:** Deployment, ConfigMap, Secret, Rolling Update
- **Bloco B:** HPA, Metrics Server, Stress Test
- **Bloco C:** Probes (Startup, Liveness, Readiness), Self-Healing
- **Bloco D:** StorageClass, PersistentVolume, PersistentVolumeClaim
