# Orientações

## Configurações Atuais

- SystemInfo:
  - WindowsVersion: 2009
  - Windows 10 Home Single Language v22H2 (compilação 19045.6575)
  - OsArchitecture: 64 bits
  - CsProcessors: {Intel(R) Core(TM) i5-8265U CPU @1.60GHz}
  - CsTotalPhysicalMemory : 16977367040

- WSL:
  - Versão do WSL: 2.6.1.0
  - Versão do kernel: 6.6.87.2-1
  - Versão do WSLg: 1.0.66
  - Versão do MSRDC: 1.2.6353
  - Versão do Direct3D: 1.611.1-81528511
  - Versão do DXCore: 10.0.26100.1-240331-1435.ge-release
  - Versão do Windows: 10.0.19045.657

- Node v22.16.0 (minha máquina)

- pnpm v10.12.1

- Docker Desktop v4.52.0

- Versão Lens (Personal):
  - Lens: 2025.10.230725-latest
  - Electron: 38.2.2
  - Chrome: 140.0.7339.133
  - Node: 22.19.0

- kind v0.30.0 go1.24.6 windows/amd64

- kubeclt:
  - Client Version: v1.34.2
  - Kustomize Version: v5.7.1
  - Server Version: v1.34.0

## Recomendações para criação de projetos didáticos

- Focar na didática, aprendizado e explicação.
- considerar nos mínimos detalhes o contexto dos resumos das aulas.
- Seguir as melhores práticas (use context7 - mcp). Também vale consultas na web em fontes oficias e de confiança.
- Sequenciar e fornecer passo a passo detalhado (crie um arquivo .md para facilitar e registrar).
- Explicar cada comando de terminal necessário para implementação dos projetos didáticos.
- Explicação breve e linha por linha dos arquivos `.yaml` através de comentários.

## Recomendações Gerais

- Obedeça a formatação/lint na geração de arquivos markdown (`.md`)
- NÃO USAR emojis em quaisquer documentos `.md` gerados
- commits detalhados, porém não muito extenso
- não faça nenhum tipo de referências ao Claude Code nos texto de commit. sempre remover. ex: 🤖 Generated with [ClaudeCode](https://claude.com/claude-code) Co-Authored-By: Claude <noreply@anthropic.com>".
