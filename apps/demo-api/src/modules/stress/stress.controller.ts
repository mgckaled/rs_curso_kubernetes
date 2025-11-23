import { Controller, Get, Post, Query } from '@nestjs/common';
import { StressService } from './stress.service.js';

@Controller('stress')
export class StressController {
  constructor(private readonly stressService: StressService) { }

  // Consome CPU por N segundos (para testar HPA)
  @Get('cpu')
  stressCpu (@Query('duration') duration: string) {
    const seconds = parseInt(duration, 10) || 10;
    return this.stressService.stressCpu(seconds);
  }

  // Aloca N MB de memória (para testar HPA)
  @Get('memory')
  stressMemory (@Query('mb') mb: string) {
    const megabytes = parseInt(mb, 10) || 100;
    return this.stressService.stressMemory(megabytes);
  }

  // Escrita intensiva em arquivo (alto consumo de CPU via streams)
  @Post('write')
  stressWrite () {
    return this.stressService.stressWrite();
  }
}
