import { Controller, Get, Post, Query } from '@nestjs/common';
import { HealthCheck, HealthCheckService } from '@nestjs/terminus';
import { HealthService } from './health.service.js';

@Controller()
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private healthService: HealthService,
  ) { }

  // Liveness & Startup Probe
  @Get('health')
  @HealthCheck()
  check () {
    return this.health.check([() => this.healthService.isHealthy('app')]);
  }

  // Readiness Probe
  @Get('ready')
  @HealthCheck()
  ready () {
    return this.health.check([() => this.healthService.isReady('app')]);
  }

  // Simula falha aleatória (50% chance)
  @Get('health/unstable')
  unstable () {
    return this.healthService.unstableCheck();
  }

  // Simula delay (para testar timeout de probes)
  @Get('health/slow')
  async slow (@Query('ms') ms: string) {
    const delay = parseInt(ms, 10) || 5000;
    return this.healthService.slowCheck(delay);
  }

  // Força crash do pod (para testar self-healing)
  @Post('crash')
  crash () {
    console.log('Crash requested! Exiting process...');
    setTimeout(() => process.exit(1), 100);
    return { message: 'Crashing in 100ms...' };
  }
}