# Plano: Demo API para Testes K8s

## Objetivo

Aplicação backend universal para testar **todos** os recursos K8s do Módulo 2, Nível 1.

---

## Stack

| Tecnologia | Versão | Justificativa |
|------------|--------|---------------|
| Node.js | 22.x | Disponível no ambiente |
| Nest.js | 11.x | Framework estruturado |
| Fastify | adapter | Performance superior |
| pnpm | 10.x | Gerenciador de pacotes |
| TypeScript | 5.x | Tipagem |

---

## Cobertura de Recursos K8s

### Bloco A - Deployment e Cenários Reais

| Recurso | Endpoint/Feature | Descrição |
|---------|------------------|-----------|
| Dockerfile | - | Multi-stage build otimizado |
| ConfigMap | `GET /env` | Exibe variáveis não sensíveis |
| Secret | `GET /env` | Exibe variáveis sensíveis (mascaradas) |
| imagePullPolicy | - | Configurado no Deployment |
| Rolling Update | - | Estratégia no Deployment |
| Rollback | - | Via `kubectl rollout` |

### Bloco B - HPA

| Recurso | Endpoint | Descrição |
|---------|----------|-----------|
| CPU Stress | `GET /stress/cpu?duration=10` | Consome CPU por N segundos |
| Memory Stress | `GET /stress/memory?mb=100` | Aloca N MB de memória |
| File Write | `POST /stress/write` | Escrita intensiva (streams) |
| Metrics | - | Requer Metrics Server |

### Bloco C - Probes e Self Healing

| Recurso | Endpoint | Descrição |
|---------|----------|-----------|
| Startup Probe | `GET /health` | Verifica se app iniciou |
| Liveness Probe | `GET /health` | Verifica se app está viva |
| Readiness Probe | `GET /ready` | Verifica se app está pronta |
| Simulate Error | `GET /health/unstable` | Falha aleatória (50%) |
| Simulate Delay | `GET /health/slow?ms=5000` | Delay configurável |
| Crash | `POST /crash` | Força crash do pod |

### Bloco D - Volumes

| Recurso | Endpoint | Descrição |
|---------|----------|-----------|
| List Files | `GET /files` | Lista arquivos no volume |
| Read File | `GET /files/:name` | Lê arquivo do volume |
| Write File | `POST /files` | Escreve arquivo no volume |
| Delete File | `DELETE /files/:name` | Remove arquivo do volume |

---

## Estrutura do Projeto

```txt
apps/
└── demo-api/
    ├── src/
    │   ├── main.ts                 # Bootstrap com Fastify
    │   ├── app.module.ts           # Módulo raiz
    │   ├── app.controller.ts       # Controller raiz
    │   └── modules/
    │       ├── health/             # Probes (Bloco C)
    │       │   ├── health.module.ts
    │       │   ├── health.controller.ts
    │       │   └── health.service.ts
    │       ├── stress/             # HPA (Bloco B)
    │       │   ├── stress.module.ts
    │       │   ├── stress.controller.ts
    │       │   └── stress.service.ts
    │       ├── env/                # ConfigMap/Secret (Bloco A)
    │       │   ├── env.module.ts
    │       │   └── env.controller.ts
    │       └── files/              # Volumes (Bloco D)
    │           ├── files.module.ts
    │           ├── files.controller.ts
    │           └── files.service.ts
    ├── Dockerfile
    ├── .dockerignore
    ├── package.json
    ├── tsconfig.json
    ├── tsconfig.build.json
    ├── nest-cli.json
    └── README.md
```

---

## Manifests K8s

```txt
n1/m2/
├── b-a/                    # Deployment e cenários
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── b-b/                    # HPA
│   ├── hpa-v1.yaml
│   └── hpa-v2.yaml
├── b-c/                    # Probes
│   └── deployment-probes.yaml
└── b-d/                    # Volumes
    ├── storageclass.yaml
    ├── pv.yaml
    ├── pvc.yaml
    └── deployment-volume.yaml
```

---

## Endpoints Completos

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
| GET | `/stress/memory?mb=N` | B | Aloca N MB de memória |
| POST | `/stress/write` | B | Escrita intensiva |
| GET | `/files` | D | Lista arquivos |
| GET | `/files/:name` | D | Lê arquivo |
| POST | `/files` | D | Cria arquivo |
| DELETE | `/files/:name` | D | Remove arquivo |

---

## Decisão: Database

Para o escopo do M2 N1, **não é necessário banco de dados**:

- ConfigMap/Secret: variáveis de ambiente são suficientes
- Volumes: arquivos no PVC simulam persistência
- HPA: stress de CPU/memória não requer DB

Banco de dados será necessário em módulos futuros (StatefulSet, N2).
