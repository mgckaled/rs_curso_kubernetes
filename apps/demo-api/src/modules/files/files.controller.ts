import { Controller, Get, Post, Delete, Param, Body } from '@nestjs/common';
import { FilesService } from './files.service.js';

@Controller('files')
export class FilesController {
  constructor(private readonly filesService: FilesService) { }

  // Lista arquivos no volume
  @Get()
  listFiles () {
    return this.filesService.listFiles();
  }

  // Lê conteúdo de um arquivo
  @Get(':name')
  readFile (@Param('name') name: string) {
    return this.filesService.readFile(name);
  }

  // Cria/atualiza arquivo
  @Post()
  writeFile (@Body() body: { name: string; content: string }) {
    return this.filesService.writeFile(body.name, body.content);
  }

  // Remove arquivo
  @Delete(':name')
  deleteFile (@Param('name') name: string) {
    return this.filesService.deleteFile(name);
  }
}