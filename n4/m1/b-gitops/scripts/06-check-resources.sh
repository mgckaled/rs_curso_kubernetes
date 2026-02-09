#!/bin/bash
# =============================================================================
# Script de Verificacao de Recursos
# Nivel 4 - Modulo 1 - GitOps e ArgoCD
# =============================================================================
# Verifica consumo de RAM dos containers Docker (Kind nodes)
# e dos pods do Argo CD no cluster.
#
# Uso: bash scripts/06-check-resources.sh
# =============================================================================

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Verificacao de Recursos - GitOps com Argo CD  ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ------------------------------------------
# 1. Verificar containers Docker (Kind nodes)
# ------------------------------------------
echo -e "${YELLOW}[1/3] Consumo de memoria dos containers Docker (Kind nodes):${NC}"
echo "-------------------------------------------------------------"

if command -v docker &> /dev/null; then
  docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" \
    $(docker ps --filter "label=io.x-k8s.kind.cluster" -q 2>/dev/null) 2>/dev/null

  if [ $? -ne 0 ]; then
    echo -e "${RED}Nenhum container Kind encontrado.${NC}"
    echo "Voce precisa criar o cluster primeiro:"
    echo "  kind create cluster --config manifests/00-kind-cluster.yaml"
  fi
else
  echo -e "${RED}Docker nao encontrado. Verifique a instalacao.${NC}"
fi

echo ""

# ------------------------------------------
# 2. Verificar pods do Argo CD
# ------------------------------------------
echo -e "${YELLOW}[2/3] Pods do Argo CD (namespace argocd):${NC}"
echo "-------------------------------------------------------------"

if kubectl get namespace argocd &> /dev/null; then
  kubectl get pods -n argocd -o wide 2>/dev/null
  echo ""

  # Tentar mostrar consumo de recursos (requer metrics-server)
  echo -e "${YELLOW}Consumo de recursos (requer metrics-server):${NC}"
  kubectl top pods -n argocd 2>/dev/null || \
    echo -e "${YELLOW}Metrics server nao disponivel. Isso e normal em Kind sem metrics-server.${NC}"
else
  echo -e "${YELLOW}Namespace 'argocd' nao encontrado. Argo CD nao esta instalado.${NC}"
fi

echo ""

# ------------------------------------------
# 3. Resumo dos clusters Kind
# ------------------------------------------
echo -e "${YELLOW}[3/3] Clusters Kind ativos:${NC}"
echo "-------------------------------------------------------------"

if command -v kind &> /dev/null; then
  CLUSTERS=$(kind get clusters 2>/dev/null)
  if [ -z "$CLUSTERS" ]; then
    echo -e "${GREEN}Nenhum cluster Kind ativo.${NC}"
  else
    echo "$CLUSTERS"
    echo ""
    echo -e "${BLUE}Contextos kubectl disponiveis:${NC}"
    kubectl config get-contexts 2>/dev/null
  fi
else
  echo -e "${RED}Kind nao encontrado. Verifique a instalacao.${NC}"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Limite recomendado: 2.5 GB de RAM total        ${NC}"
echo -e "${BLUE}================================================${NC}"
