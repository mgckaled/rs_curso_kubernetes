import { pgTable, text, timestamp, integer } from 'drizzle-orm/pg-core';

// Tabela de usuários
export const users = pgTable('users', {
  id: text('id')
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Tabela de logs de operações (para demonstrar StatefulSet)
export const operationLogs = pgTable('operation_logs', {
  id: text('id')
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  operation: text('operation').notNull(),
  endpoint: text('endpoint').notNull(),
  statusCode: integer('status_code').notNull(),
  duration: integer('duration').notNull(),
  timestamp: timestamp('timestamp').defaultNow().notNull(),
  metadata: text('metadata'),
});

// Tipos inferidos para TypeScript
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type OperationLog = typeof operationLogs.$inferSelect;
export type NewOperationLog = typeof operationLogs.$inferInsert;
