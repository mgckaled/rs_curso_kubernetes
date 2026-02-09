#!/bin/bash
# =============================================================================
# Script de Simulacao CI - Atualiza versao da app via Git
# Nivel 4 - Modulo 1 - GitOps e ArgoCD - Aula 7
# =============================================================================
#
# Este script SIMULA o que uma pipeline CI (GitHub Actions) faria:
#   1. Recebe uma nova versao como parametro
#   2. Atualiza a versao no ConfigMap (index.html)
#   3. Faz git add + git commit
#   4. Instrui o usuario a fazer git push
#
# Apos o push, o Argo CD detecta a mudanca (~180s de polling)
# e sincroniza automaticamente o novo estado no cluster.
#
# Uso: bash scripts/03-simulate-ci.sh v2
#      bash scripts/03-simulate-ci.sh v3
#
# Em producao, isso seria feito por:
#   - GitHub Actions com yaml-update-action
#   - Build de imagem Docker -> push no registry -> atualiza tag no YAML
# =============================================================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGMAP_FILE="$PROJECT_DIR/apps/demo-nginx/configmap.yaml"

# ------------------------------------------
# Validar parametros
# ------------------------------------------
if [ -z "$1" ]; then
  echo -e "${RED}Uso: bash scripts/03-simulate-ci.sh <versao>${NC}"
  echo -e "${RED}Exemplo: bash scripts/03-simulate-ci.sh v2${NC}"
  exit 1
fi

NEW_VERSION="$1"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Simulacao CI - Atualizando versao da app       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ------------------------------------------
# 1. Verificar arquivo ConfigMap existe
# ------------------------------------------
echo -e "${YELLOW}[1/4] Verificando arquivo ConfigMap...${NC}"

if [ ! -f "$CONFIGMAP_FILE" ]; then
  echo -e "${RED}Arquivo nao encontrado: ${CONFIGMAP_FILE}${NC}"
  exit 1
fi

# Obter versao atual
CURRENT_VERSION=$(grep -oP '<div class="version">\K[^<]+' "$CONFIGMAP_FILE" 2>/dev/null || echo "desconhecida")
echo -e "${GREEN}  Versao atual: ${CYAN}${CURRENT_VERSION}${NC}"
echo -e "${GREEN}  Nova versao:  ${CYAN}${NEW_VERSION}${NC}"
echo ""

# ------------------------------------------
# 2. Atualizar versao no ConfigMap
# ------------------------------------------
echo -e "${YELLOW}[2/4] Atualizando versao no ConfigMap...${NC}"

# Substituir a versao no HTML dentro do ConfigMap
sed -i "s|<div class=\"version\">.*</div>|<div class=\"version\">${NEW_VERSION}</div>|" "$CONFIGMAP_FILE"

echo -e "${GREEN}  ConfigMap atualizado: ${CYAN}${CONFIGMAP_FILE}${NC}"
echo ""

# ------------------------------------------
# 3. Verificar mudanca
# ------------------------------------------
echo -e "${YELLOW}[3/4] Verificando mudanca...${NC}"

cd "$PROJECT_DIR/../../../"  # Raiz do repositorio git
DIFF=$(git diff --stat -- "n4/m1/b-gitops/apps/demo-nginx/configmap.yaml" 2>/dev/null)

if [ -z "$DIFF" ]; then
  echo -e "${YELLOW}  Nenhuma mudanca detectada. A versao ja era '${NEW_VERSION}'.${NC}"
  exit 0
fi

echo -e "${GREEN}  Mudanca detectada:${NC}"
echo "$DIFF"
echo ""

# ------------------------------------------
# 4. Commit automatico
# ------------------------------------------
echo -e "${YELLOW}[4/4] Fazendo commit...${NC}"

git add "n4/m1/b-gitops/apps/demo-nginx/configmap.yaml"
git commit -m "feat(n4-m1): update demo-nginx to ${NEW_VERSION}

Simulated CI pipeline - version bump from ${CURRENT_VERSION} to ${NEW_VERSION}" 2>/dev/null

echo -e "${GREEN}  Commit criado.${NC}"
echo ""

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Simulacao CI concluida!                        ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}Proximo passo:${NC}"
echo -e "  Faca push para o GitHub:"
echo -e "  ${CYAN}git push${NC}"
echo ""
echo -e "${GREEN}O que acontece depois:${NC}"
echo -e "  1. Argo CD detecta a mudanca no Git (~180 segundos)"
echo -e "  2. Application fica 'OutOfSync'"
echo -e "  3. Se AutoSync estiver habilitado, sincroniza automaticamente"
echo -e "  4. Se sync manual, faca: ${CYAN}argocd app sync demo-nginx${NC}"
echo ""
echo -e "${GREEN}Para forcar refresh imediato:${NC}"
echo -e "  ${CYAN}argocd app get demo-nginx --refresh${NC}"
echo ""
echo -e "${GREEN}Para verificar na UI:${NC}"
echo -e "  Acesse ${CYAN}https://localhost:8080${NC} e observe a Application"
