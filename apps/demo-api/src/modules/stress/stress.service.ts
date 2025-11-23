import { Injectable } from '@nestjs/common';
import { createWriteStream } from 'node:fs';
import { join } from 'node:path';

@Injectable()
export class StressService {
  // Consome CPU por N segundos
  stressCpu (seconds: number) {
    const startTime = Date.now();
    const endTime = startTime + seconds * 1000;

    // Loop intensivo de CPU
    while (Date.now() < endTime) {
      Math.sqrt(Math.random() * 999999999);
    }

    const elapsed = Date.now() - startTime;

    return {
      status: 'completed',
      type: 'cpu',
      requestedDuration: `${seconds}s`,
      actualDuration: `${elapsed}ms`,
      timestamp: new Date().toISOString(),
    };
  }

  // Aloca N MB de memória
  stressMemory (megabytes: number) {
    const startTime = Date.now();

    // Aloca array de bytes
    const bytes = megabytes * 1024 * 1024;
    const buffer = Buffer.alloc(bytes, 'x');

    // Mantém referência para evitar GC
    const size = buffer.length;

    const elapsed = Date.now() - startTime;

    return {
      status: 'allocated',
      type: 'memory',
      requestedSize: `${megabytes}MB`,
      actualSize: `${(size / 1024 / 1024).toFixed(2)}MB`,
      allocationTime: `${elapsed}ms`,
      timestamp: new Date().toISOString(),
      warning: 'Memory will be released after response',
    };
  }

  // Escrita intensiva em arquivo (simula alto consumo de CPU)
  async stressWrite () {
    const startTime = Date.now();
    const filePath = join('/tmp', `stress-${Date.now()}.txt`);
    const iterations = 100000;

    return new Promise((resolve) => {
      const stream = createWriteStream(filePath);

      for (let i = 0; i < iterations; i++) {
        stream.write(`Line ${i}: ${Math.random().toString(36).repeat(100)}\n`);
      }

      stream.end(() => {
        const elapsed = Date.now() - startTime;

        resolve({
          status: 'completed',
          type: 'write',
          filePath,
          linesWritten: iterations,
          duration: `${elapsed}ms`,
          timestamp: new Date().toISOString(),
        });
      });
    });
  }
}