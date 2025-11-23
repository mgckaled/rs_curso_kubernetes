import { Injectable } from '@nestjs/common';
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
  unlinkSync,
  statSync,
} from 'node:fs';
import { join } from 'node:path';

@Injectable()
export class FilesService {
  // Diretório do volume (configurável via env)
  private readonly volumePath =
    process.env.VOLUME_PATH ?? '/app/data';

  constructor() {
    // Garante que o diretório existe
    if (!existsSync(this.volumePath)) {
      mkdirSync(this.volumePath, { recursive: true });
    }
  }

  // Lista arquivos no volume
  listFiles () {
    try {
      const files = readdirSync(this.volumePath).map((name) => {
        const filePath = join(this.volumePath, name);
        const stats = statSync(filePath);

        return {
          name,
          size: stats.size,
          isDirectory: stats.isDirectory(),
          modified: stats.mtime.toISOString(),
        };
      });

      return {
        path: this.volumePath,
        count: files.length,
        files,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      return {
        error: 'Failed to list files',
        message: (error as Error).message,
        path: this.volumePath,
      };
    }
  }

  // Lê conteúdo de um arquivo
  readFile (name: string) {
    const filePath = join(this.volumePath, name);

    try {
      if (!existsSync(filePath)) {
        return {
          error: 'File not found',
          name,
          path: filePath,
        };
      }

      const content = readFileSync(filePath, 'utf-8');
      const stats = statSync(filePath);

      return {
        name,
        path: filePath,
        size: stats.size,
        content,
        modified: stats.mtime.toISOString(),
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      return {
        error: 'Failed to read file',
        message: (error as Error).message,
        name,
      };
    }
  }

  // Cria ou atualiza arquivo
  writeFile (name: string, content: string) {
    const filePath = join(this.volumePath, name);

    try {
      const existed = existsSync(filePath);
      writeFileSync(filePath, content, 'utf-8');
      const stats = statSync(filePath);

      return {
        status: existed ? 'updated' : 'created',
        name,
        path: filePath,
        size: stats.size,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      return {
        error: 'Failed to write file',
        message: (error as Error).message,
        name,
      };
    }
  }

  // Remove arquivo
  deleteFile (name: string) {
    const filePath = join(this.volumePath, name);

    try {
      if (!existsSync(filePath)) {
        return {
          error: 'File not found',
          name,
          path: filePath,
        };
      }

      unlinkSync(filePath);

      return {
        status: 'deleted',
        name,
        path: filePath,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      return {
        error: 'Failed to delete file',
        message: (error as Error).message,
        name,
      };
    }
  }
}