import { Controller, Get } from '@nestjs/common';

@Controller('env')
export class EnvController {
  // Lista variáveis de ambiente (ConfigMap e Secrets)
  @Get()
  getEnv () {
    // Variáveis esperadas do ConfigMap
    const configMapVars = {
      APP_NAME: process.env.APP_NAME ?? 'not set',
      APP_ENV: process.env.APP_ENV ?? 'not set',
      LOG_LEVEL: process.env.LOG_LEVEL ?? 'not set',
    };

    // Variáveis esperadas do Secret (mascaradas)
    const secretVars = {
      DB_HOST: process.env.DB_HOST ? '***' : 'not set',
      DB_USER: process.env.DB_USER ? '***' : 'not set',
      DB_PASSWORD: process.env.DB_PASSWORD ? '******' : 'not set',
      API_KEY: process.env.API_KEY ? '***' : 'not set',
    };

    // Variáveis do sistema
    const systemVars = {
      NODE_ENV: process.env.NODE_ENV ?? 'not set',
      PORT: process.env.PORT ?? '3000',
      HOSTNAME: process.env.HOSTNAME ?? 'unknown',
    };

    return {
      configMap: configMapVars,
      secrets: secretVars,
      system: systemVars,
      timestamp: new Date().toISOString(),
    };
  }

  // Lista todas as variáveis (cuidado: expõe secrets!)
  @Get('all')
  getAllEnv () {
    // Filtra variáveis sensíveis conhecidas
    const sensitiveKeys = ['PASSWORD', 'SECRET', 'KEY', 'TOKEN', 'CREDENTIAL'];

    const filtered = Object.entries(process.env).reduce(
      (acc, [key, value]) => {
        const isSensitive = sensitiveKeys.some((s) =>
          key.toUpperCase().includes(s),
        );
        acc[key] = isSensitive ? '******' : value;
        return acc;
      },
      {} as Record<string, string | undefined>,
    );

    return {
      count: Object.keys(filtered).length,
      variables: filtered,
      timestamp: new Date().toISOString(),
    };
  }
}