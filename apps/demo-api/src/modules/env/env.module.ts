import { Module } from '@nestjs/common';
import { EnvController } from './env.controller.js';

@Module({
  controllers: [EnvController],
})
export class EnvModule { }