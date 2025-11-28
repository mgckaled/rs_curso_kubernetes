import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DrizzlePGModule } from '@knaadh/nestjs-drizzle-pg';
import { AppController } from './app.controller.js';
import { HealthModule } from './modules/health/health.module.js';
import { StressModule } from './modules/stress/stress.module.js';
import { EnvModule } from './modules/env/env.module.js';
import { FilesModule } from './modules/files/files.module.js';
import { UsersModule } from './users/users.module.js';
import { MetricsModule } from './metrics/metrics.module.js';
import * as schema from './db/schema.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DrizzlePGModule.register({
      tag: 'DRIZZLE_PROVIDER',
      pg: {
        connection: 'client',
        config: {
          connectionString: process.env.DATABASE_URL,
        },
      },
      config: { schema: { ...schema } },
    }),
    HealthModule,
    StressModule,
    EnvModule,
    FilesModule,
    UsersModule,
    MetricsModule,
  ],
  controllers: [AppController],
})
export class AppModule { }
