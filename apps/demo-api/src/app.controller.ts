import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getInfo() {
    return {
      app: 'demo-api',
      version: process.env.npm_package_version ?? '1.0.0',
      description: 'API universal para testes de recursos Kubernetes',
      endpoints: {
        health: '/health, /ready',
        stress: '/stress/cpu, /stress/memory, /stress/write',
        env: '/env',
        files: '/files',
      },
    };
  }
}
