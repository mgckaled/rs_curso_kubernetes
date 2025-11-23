import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { HealthModule } from './modules/health/health.module.js';
import { StressModule } from './modules/stress/stress.module.js';
import { EnvModule } from './modules/env/env.module.js';
import { FilesModule } from './modules/files/files.module.js';

@Module({
  imports: [HealthModule, StressModule, EnvModule, FilesModule],
  controllers: [AppController],
})
export class AppModule { }
