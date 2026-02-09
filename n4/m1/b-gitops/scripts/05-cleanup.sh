#!/bin/bash
# =============================================================================
# Script de Limpeza Completa
# Nivel 4 - Modulo 1 - GitOps e ArgoCD
# =============================================================================
# Remove todos os clusters Kind criados por este projeto.
# Seguro para executar a qualquer momento.
#
# Uso: bash scripts/05-cleanup.sh
# =============================================================================

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Limpeza Completa - GitOps com Argo CD         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ------------------------------------------
# 1. Deletar cluster principal (n4-m1-gitops)
# ------------------------------------------
echo -e "${YELLOW}[1/3] Removendo cluster principal (n4-m1-gitops)...${NC}"

if kind get clusters 2>/dev/null | grep -q "n4-m1-gitops"; then
  kind delete cluster --name n4-m1-gitops
  echo -e "${GREEN}Cluster n4-m1-gitops removido com sucesso.${NC}"
else
  echo -e "${YELLOW}Cluster n4-m1-gitops nao encontrado. Pulando.${NC}"
fi

echo ""

# ------------------------------------------
# 2. Deletar cluster staging (n4-m1-staging)
# ------------------------------------------
echo -e "${YELLOW}[2/3] Removendo cluster staging (n4-m1-staging)...${NC}"

if kind get clusters 2>/dev/null | grep -q "n4-m1-staging"; then
  kind delete cluster --name n4-m1-staging
  echo -e "${GREEN}Cluster n4-m1-staging removido com sucesso.${NC}"
else
  echo -e "${YELLOW}Cluster n4-m1-staging nao encontrado. Pulando.${NC}"
fi

echo ""

# ------------------------------------------
# 3. Verificar limpeza
# ------------------------------------------
echo -e "${YELLOW}[3/3] Verificando limpeza...${NC}"
echo "-------------------------------------------------------------"

REMAINING=$(kind get clusters 2>/dev/null)
if [ -z "$REMAINING" ]; then
  echo -e "${GREEN}Todos os clusters Kind foram removidos.${NC}"
else
  echo -e "${YELLOW}Clusters Kind restantes:${NC}"
  echo "$REMAINING"
fi

echo ""
echo -e "${GREEN}Limpeza concluida.${NC}"
echo -e "${BLUE}Para verificar containers Docker restantes: docker ps${NC}"
