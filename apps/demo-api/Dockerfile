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

# Copia arquivos de migração do banco
COPY --from=builder /app/drizzle ./drizzle
COPY drizzle.config.ts ./
COPY src/db/schema.ts ./src/db/schema.ts
COPY src/db/migrate.ts ./src/db/migrate.ts

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

# Comando de inicialização
CMD ["node", "dist/main.js"]
