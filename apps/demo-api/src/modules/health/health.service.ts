import { Injectable } from '@nestjs/common';
import { HealthIndicatorService } from '@nestjs/terminus';

@Injectable()
export class HealthService {
  private isAppReady = false;

  constructor(private readonly healthIndicatorService: HealthIndicatorService) {
    // Simula tempo de inicialização (2s)
    setTimeout(() => {
      this.isAppReady = true;
      console.log('Application is now ready!');
    }, 2000);
  }

  // Verifica se a aplicação está viva (liveness)
  async isHealthy (key: string) {
    const indicator = this.healthIndicatorService.check(key);
    return indicator.up({ message: 'Application is healthy' });
  }

  // Verifica se a aplicação está pronta para receber tráfego (readiness)
  async isReady (key: string) {
    const indicator = this.healthIndicatorService.check(key);

    if (!this.isAppReady) {
      return indicator.down({ message: 'Application is not ready yet' });
    }

    return indicator.up({ message: 'Application is ready' });
  }

  // Falha aleatória (50% chance) - útil para testar self-healing
  unstableCheck () {
    const isHealthy = Math.random() > 0.5;

    if (!isHealthy) {
      return {
        status: 'error',
        message: 'Random failure occurred!',
        timestamp: new Date().toISOString(),
      };
    }

    return {
      status: 'ok',
      message: 'Check passed',
      timestamp: new Date().toISOString(),
    };
  }

  // Delay configurável - útil para testar timeout de probes
  async slowCheck (delayMs: number) {
    await new Promise((resolve) => setTimeout(resolve, delayMs));

    return {
      status: 'ok',
      message: `Responded after ${delayMs}ms delay`,
      timestamp: new Date().toISOString(),
    };
  }
}
