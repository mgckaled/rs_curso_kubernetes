# Plano de Implementação: Adaptação demo-api para N2 e N3

## Sumário Executivo

Plano detalhado para adaptar a `demo-api` existente adicionando suporte a banco de dados (Drizzle ORM + PostgreSQL), métricas Prometheus e preparar para N2 e N3.

**Tempo estimado total**: 6-8 horas
**Abordagem**: Incremental, sem breaking changes

## Fase 0: Preparação (15 minutos)

### Criar Branch de Desenvolvimento

```bash
cd apps/demo-api
git checkout -b feature/n2-database-metrics
```

### Backup do Estado Atual

```bash
# Commit estado atual (se houver mudanças)
git add .
git commit -m "chore: checkpoint antes de adaptar para N2/N3"
```

## Fase 1: Instalação de Dependências (10 minutos)

### 1.1 Dependencies (Produção)

Execute cada comando **separadamente** para evitar conflitos:

```bash
# Navegue para o diretório da demo-api
cd apps/demo-api

# Database - Drizzle ORM + PostgreSQL
pnpm add @knaadh/nestjs-drizzle-pg

pnpm add drizzle-orm

pnpm add pg

# Validation (para DTOs)
pnpm add class-validator

pnpm add class-transformer

# Config (para variáveis de ambiente)
pnpm add @nestjs/config

# Metrics - Prometheus
pnpm add @willsoto/nestjs-prometheus

pnpm add prom-client
```

### 1.2 DevDependencies (Desenvolvimento)

Execute cada comando **separadamente**:

```bash
# Database tools
pnpm add -D drizzle-kit

pnpm add -D @types/pg

# Runtime para migrations
pnpm add -D tsx

# Dotenv para desenvolvimento local
pnpm add -D dotenv
```

### 1.3 Verificação

```bash
# Verificar se tudo foi instalado
pnpm list --depth=0 | grep -E "drizzle|prometheus|class-|@nestjs/config"
```

**Versões esperadas**:
- `@knaadh/nestjs-drizzle-pg`: ^1.0.0+
- `drizzle-orm`: ^0.36.0+
- `drizzle-kit`: ^0.28.0+
- `pg`: ^8.13.0+
- `@willsoto/nestjs-prometheus`: ^6.0.0+
- `prom-client`: ^15.0.0+
- `class-validator`: ^0.14.0+
- `class-transformer`: ^0.5.1+
- `@nestjs/config`: ^3.0.0+

## Fase 2: Configuração Base (30 minutos)

### 2.1 Criar Estrutura de Diretórios

```bash
# Dentro de apps/demo-api
mkdir -p src/db
mkdir -p src/modules/database
mkdir -p src/modules/database/users
mkdir -p src/modules/database/users/dto
mkdir -p src/modules/metrics
mkdir -p drizzle
```

### 2.2 Configurar Environment Variables

```bash
# Criar .env.example
cat > .env.example << 'EOF'
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/demo_api

# Volumes
VOLUME_PATH=/app/data
EOF

# Copiar para .env (desenvolvimento local)
cp .env.example .env
```

### 2.3 Atualizar .gitignore

```bash
cat >> .gitignore << 'EOF'

# Environment
.env
.env.local
.env.*.local

# Database
drizzle/
EOF
```

### 2.4 Configurar Drizzle Kit

```typescript
// drizzle.config.ts (criar na raiz de apps/demo-api)
import { defineConfig } from 'drizzle-kit';
import 'dotenv/config';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  verbose: true,
  strict: true,
});
```

### 2.5 Adicionar Scripts ao package.json

```json
{
  "scripts": {
    "build": "nest build",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main.js",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "tsx src/db/migrate.ts",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push",
    "db:drop": "drizzle-kit drop"
  }
}
```

## Fase 3: Database Schema (45 minutos)

### 3.1 Criar Schema Base

```typescript
// src/db/schema.ts
import { pgTable, text, timestamp, boolean, integer } from 'drizzle-orm/pg-core';

/**
 * Users Table
 * Tabela de usuários para demonstração de StatefulSet e persistência
 */
export const users = pgTable('users', {
  id: text('id')
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),

  email: text('email')
    .notNull()
    .unique(),

  name: text('name')
    .notNull(),

  isActive: boolean('is_active')
    .default(true)
    .notNull(),

  createdAt: timestamp('created_at', { mode: 'date' })
    .defaultNow()
    .notNull(),

  updatedAt: timestamp('updated_at', { mode: 'date' })
    .defaultNow()
    .notNull(),
});

/**
 * Logs Table (opcional - para demonstrar observabilidade)
 * Armazena logs da aplicação para análise
 */
export const logs = pgTable('logs', {
  id: text('id')
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),

  level: text('level', { enum: ['info', 'warn', 'error', 'debug'] })
    .notNull(),

  message: text('message')
    .notNull(),

  metadata: text('metadata'), // JSON stringified

  createdAt: timestamp('created_at', { mode: 'date' })
    .defaultNow()
    .notNull(),
});

// Type inference para TypeScript
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Log = typeof logs.$inferSelect;
export type NewLog = typeof logs.$inferInsert;
```

### 3.2 Criar Migration Runner

```typescript
// src/db/migrate.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { Pool } from 'pg';
import 'dotenv/config';

async function main() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  const db = drizzle(pool);

  console.log('⏳ Running migrations...');

  try {
    await migrate(db, { migrationsFolder: './drizzle' });
    console.log('✅ Migrations completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Migration script failed:', err);
  process.exit(1);
});
```

### 3.3 Gerar Primeira Migration

```bash
# Gerar SQL migrations
pnpm db:generate
```

## Fase 4: Módulo Database (90 minutos)

### 4.1 DTOs

```typescript
// src/modules/database/users/dto/create-user.dto.ts
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  name: string;
}
```

```typescript
// src/modules/database/users/dto/update-user.dto.ts
import { IsEmail, IsOptional, IsString, MinLength, IsBoolean } from 'class-validator';

export class UpdateUserDto {
  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @MinLength(2)
  @IsOptional()
  name?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
```

### 4.2 Users Service

```typescript
// src/modules/database/users/users.service.ts
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { eq } from 'drizzle-orm';
import * as schema from '../../../db/schema.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';

@Injectable()
export class UsersService {
  constructor(
    @Inject('DB') private db: NodePgDatabase<typeof schema>,
  ) {}

  async create(createUserDto: CreateUserDto) {
    const [user] = await this.db
      .insert(schema.users)
      .values(createUserDto)
      .returning();

    return user;
  }

  async findAll() {
    return this.db.select().from(schema.users);
  }

  async findOne(id: string) {
    const [user] = await this.db
      .select()
      .from(schema.users)
      .where(eq(schema.users.id, id));

    if (!user) {
      throw new NotFoundException(\`User with ID \${id} not found\`);
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const [user] = await this.db
      .update(schema.users)
      .set({ ...updateUserDto, updatedAt: new Date() })
      .where(eq(schema.users.id, id))
      .returning();

    if (!user) {
      throw new NotFoundException(\`User with ID \${id} not found\`);
    }

    return user;
  }

  async remove(id: string) {
    const [user] = await this.db
      .delete(schema.users)
      .where(eq(schema.users.id, id))
      .returning();

    if (!user) {
      throw new NotFoundException(\`User with ID \${id} not found\`);
    }

    return user;
  }

  async count(): Promise<number> {
    const result = await this.db
      .select({ count: schema.users.id })
      .from(schema.users);

    return result.length;
  }
}
```

### 4.3 Users Controller

```typescript
// src/modules/database/users/users.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string) {
    await this.usersService.remove(id);
  }
}
```

### 4.4 Users Module

```typescript
// src/modules/database/users/users.module.ts
import { Module } from '@nestjs/common';
import { UsersController } from './users.controller.js';
import { UsersService } from './users.service.js';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

### 4.5 Database Module

```typescript
// src/modules/database/database.module.ts
import { Module } from '@nestjs/common';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [UsersModule],
  exports: [UsersModule],
})
export class DatabaseModule {}
```

## Fase 5: Módulo Metrics (60 minutos)

### 5.1 Metrics Module

```typescript
// src/modules/metrics/metrics.module.ts
import { Module } from '@nestjs/common';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';
import { MetricsController } from './metrics.controller.js';

@Module({
  imports: [
    PrometheusModule.register({
      defaultMetrics: {
        enabled: true,
        config: {
          prefix: 'demo_api_',
        },
      },
      defaultLabels: {
        app: 'demo-api',
      },
    }),
  ],
  controllers: [MetricsController],
})
export class MetricsModule {}
```

### 5.2 Metrics Controller

```typescript
// src/modules/metrics/metrics.controller.ts
import { Controller, Get } from '@nestjs/common';
import { PrometheusController } from '@willsoto/nestjs-prometheus';

@Controller()
export class MetricsController extends PrometheusController {}
```

## Fase 6: Integração no App Module (15 minutos)

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DrizzlePGModule } from '@knaadh/nestjs-drizzle-pg';
import { AppController } from './app.controller.js';
import { HealthModule } from './modules/health/health.module.js';
import { StressModule } from './modules/stress/stress.module.js';
import { EnvModule } from './modules/env/env.module.js';
import { FilesModule } from './modules/files/files.module.js';
import { DatabaseModule } from './modules/database/database.module.js';
import { MetricsModule } from './modules/metrics/metrics.module.js';
import * as schema from './db/schema.js';

@Module({
  imports: [
    // Config (precisa ser primeiro)
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Database (Drizzle)
    DrizzlePGModule.register({
      tag: 'DB',
      pg: {
        connection: 'pool',
        config: {
          connectionString: process.env.DATABASE_URL,
          max: 10,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 2000,
        },
      },
      config: {
        schema: { ...schema },
        logger: process.env.NODE_ENV === 'development',
      },
    }),

    // Modules existentes (N1)
    HealthModule,
    StressModule,
    EnvModule,
    FilesModule,

    // Novos modules (N2)
    DatabaseModule,
    MetricsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
```

## Fase 7: Testes Locais (30 minutos)

### 7.1 Subir PostgreSQL Local (Docker)

```bash
# Criar docker-compose para desenvolvimento
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:17-alpine
    container_name: demo-api-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: demo_api
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

# Subir banco
docker compose -f docker-compose.dev.yml up -d
```

### 7.2 Rodar Migrations

```bash
# Aplicar migrations
pnpm db:migrate
```

### 7.3 Testar Aplicação

```bash
# Iniciar em modo dev
pnpm start:dev
```

### 7.4 Testar Endpoints

```bash
# Health check (N1 - deve continuar funcionando)
curl http://localhost:3000/health

# Criar usuário (N2 - novo)
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User"}'

# Listar usuários
curl http://localhost:3000/users

# Métricas Prometheus (N2 - novo)
curl http://localhost:3000/metrics
```

## Fase 8: Atualizar Dockerfile (20 minutos)

```dockerfile
# apps/demo-api/Dockerfile
# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Instala pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copia arquivos de dependência
COPY package.json pnpm-lock.yaml ./

# Instala dependências
RUN pnpm install --frozen-lockfile

# Copia código fonte
COPY . .

# Build da aplicação
RUN pnpm build

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

# Instala pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copia arquivos de dependência
COPY package.json pnpm-lock.yaml ./

# Instala apenas dependências de produção
RUN pnpm install --frozen-lockfile --prod

# Copia build do stage anterior
COPY --from=builder /app/dist ./dist

# Copia schema e migrations (NOVO)
COPY --from=builder /app/src/db ./src/db
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/drizzle.config.ts ./drizzle.config.ts

# Cria diretório para volumes
RUN mkdir -p /app/data

# Usuário não-root (segurança)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 -G nodejs && \
    chown -R nestjs:nodejs /app

USER nestjs

# Porta da aplicação
EXPOSE 3000

# Variáveis de ambiente padrão
ENV NODE_ENV=production
ENV PORT=3000
ENV VOLUME_PATH=/app/data

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando de inicialização
CMD ["node", "dist/main.js"]
```

## Fase 9: Atualizar Documentação (30 minutos)

### 9.1 Atualizar README

```markdown
<!-- Adicionar em apps/demo-api/README.md -->

## Novos Endpoints (N2)

### Database

| Método | Rota | Descrição | Body |
|--------|------|-----------|------|
| POST | `/users` | Criar usuário | `{ email, name }` |
| GET | `/users` | Listar todos usuários | - |
| GET | `/users/:id` | Buscar por ID | - |
| PUT | `/users/:id` | Atualizar usuário | `{ email?, name?, isActive? }` |
| DELETE | `/users/:id` | Deletar usuário | - |

### Observabilidade

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/metrics` | Métricas Prometheus |

## Desenvolvimento Local

### Pré-requisitos

- Node.js 22+
- pnpm 10+
- Docker + Docker Compose
- PostgreSQL 17 (via Docker)

### Setup

```bash
# Instalar dependências
pnpm install

# Subir banco de dados
docker compose -f docker-compose.dev.yml up -d

# Aplicar migrations
pnpm db:migrate

# Iniciar em modo dev
pnpm start:dev
```

### Scripts Disponíveis

```bash
pnpm build          # Build de produção
pnpm start:dev      # Dev mode (hot reload)
pnpm start:prod     # Produção

# Database
pnpm db:generate    # Gerar migrations
pnpm db:migrate     # Aplicar migrations
pnpm db:studio      # Abrir Drizzle Studio
pnpm db:push        # Push schema (dev only)
```
```

## Fase 10: Commit e Validação (15 minutos)

```bash
# Adicionar tudo
git add .

# Commit detalhado
git commit -m "feat(n2): add database (Drizzle) and metrics (Prometheus) modules

- Add Drizzle ORM integration with PostgreSQL
- Add Users CRUD module (for StatefulSet demos)
- Add Prometheus metrics endpoint
- Update Dockerfile for database support
- Add docker-compose for local development
- Update documentation with new endpoints

Refs: N2-M2-A (StatefulSet), N2-M1 (Observability)
"

# Push (se quiser)
git push origin feature/n2-database-metrics
```

### Validação Final

```bash
# Build de produção
pnpm build

# Verificar se não há erros TypeScript
echo $?  # Deve ser 0

# Testar Docker build
docker build -t demo-api:test .

# Rodar container de teste
docker run --rm -p 3000:3000 \
  -e DATABASE_URL="postgresql://user:pass@host/db" \
  demo-api:test
```

## Checklist de Implementação

### Fase 0: Preparação
- [ ] Branch criada
- [ ] Backup do estado atual

### Fase 1: Dependências
- [ ] Drizzle instalado
- [ ] PostgreSQL driver instalado
- [ ] Prometheus instalado
- [ ] Validation instalado
- [ ] Config instalado
- [ ] DevDeps instalados

### Fase 2: Configuração
- [ ] Estrutura de diretórios criada
- [ ] .env configurado
- [ ] .gitignore atualizado
- [ ] drizzle.config.ts criado
- [ ] Scripts adicionados ao package.json

### Fase 3: Schema
- [ ] schema.ts criado
- [ ] migrate.ts criado
- [ ] Primeira migration gerada

### Fase 4: Database Module
- [ ] DTOs criados
- [ ] UsersService implementado
- [ ] UsersController implementado
- [ ] UsersModule criado
- [ ] DatabaseModule criado

### Fase 5: Metrics
- [ ] MetricsModule criado
- [ ] MetricsController criado

### Fase 6: Integração
- [ ] AppModule atualizado
- [ ] ConfigModule integrado
- [ ] DrizzlePGModule configurado

### Fase 7: Testes Locais
- [ ] PostgreSQL rodando (Docker)
- [ ] Migrations aplicadas
- [ ] App iniciando sem erros
- [ ] Endpoints testados
- [ ] Métricas funcionando

### Fase 8: Docker
- [ ] Dockerfile atualizado
- [ ] Build Docker OK
- [ ] Container rodando

### Fase 9: Documentação
- [ ] README atualizado
- [ ] Endpoints documentados
- [ ] Setup local documentado

### Fase 10: Validação
- [ ] Build de produção OK
- [ ] TypeScript sem erros
- [ ] Docker build OK
- [ ] Commit realizado

## Resumo de Comandos

### Instalação (executar separadamente)

```bash
# Dependencies
pnpm add @knaadh/nestjs-drizzle-pg drizzle-orm pg class-validator class-transformer @nestjs/config @willsoto/nestjs-prometheus prom-client

# DevDependencies
pnpm add -D drizzle-kit @types/pg tsx dotenv
```

### Desenvolvimento

```bash
# Banco local
docker compose -f docker-compose.dev.yml up -d

# Migrations
pnpm db:generate
pnpm db:migrate

# Dev mode
pnpm start:dev

# Studio (GUI)
pnpm db:studio
```

### Produção

```bash
# Build
pnpm build

# Docker
docker build -t demo-api:n2 .
docker run -p 3000:3000 demo-api:n2
```

## Estimativa de Tempo Total

| Fase | Tempo | Acumulado |
|------|-------|-----------|
| 0 - Preparação | 15min | 15min |
| 1 - Dependências | 10min | 25min |
| 2 - Configuração | 30min | 55min |
| 3 - Schema | 45min | 1h40min |
| 4 - Database Module | 90min | 3h10min |
| 5 - Metrics | 60min | 4h10min |
| 6 - Integração | 15min | 4h25min |
| 7 - Testes | 30min | 4h55min |
| 8 - Docker | 20min | 5h15min |
| 9 - Docs | 30min | 5h45min |
| 10 - Validação | 15min | 6h |
| **TOTAL** | **~6 horas** | - |

## Próximos Passos (Pós-Implementação)

1. **Criar manifestos K8s para N2**
   - StatefulSet com PostgreSQL
   - PVC para persistência
   - ConfigMap para DATABASE_URL

2. **Setup CI/CD (N2-M2-B)**
   - GitHub Actions workflow
   - Docker build automatizado
   - Deploy no EKS

3. **Guias didáticos**
   - Passo-a-passo StatefulSet
   - Tutorial de observabilidade
   - Troubleshooting comum

## Suporte e Troubleshooting

### Problemas Comuns

**Erro: Cannot find module '@knaadh/nestjs-drizzle-pg'**
```bash
pnpm install
pnpm build
```

**Erro: ECONNREFUSED ao conectar PostgreSQL**
```bash
# Verificar se PostgreSQL está rodando
docker ps | grep postgres

# Verificar DATABASE_URL no .env
cat .env | grep DATABASE_URL
```

**TypeScript errors após instalar dependências**
```bash
# Limpar cache
rm -rf node_modules dist
pnpm install
pnpm build
```

## Referências

- [Drizzle ORM Docs](https://orm.drizzle.team/)
- [NestJS Drizzle](https://github.com/knaadh/nestjs-drizzle)
- [NestJS Prometheus](https://github.com/willsoto/nestjs-prometheus)
- [Drizzle Kit](https://orm.drizzle.team/kit-docs/overview)
