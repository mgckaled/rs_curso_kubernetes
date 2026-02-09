#!/bin/bash
# =============================================================================
# Script de Monitoramento - Argo CD em tempo real
# Nivel 4 - Modulo 1 - GitOps e ArgoCD
# =============================================================================
#
# Exibe status em tempo real:
#   - Applications do Argo CD (sync status, health)
#   - Pods do Argo CD (namespace argocd)
#   - Pods da aplicacao demo (namespace demo-app)
#   - Eventos recentes
#
# Uso: bash scripts/04-monitor-argocd.sh
# Para sair: Ctrl+C
# =============================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Intervalo de atualizacao (segundos)
INTERVAL=5

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Monitor Argo CD - Atualizacao a cada ${INTERVAL}s       ${NC}"
echo -e "${BLUE}  Pressione Ctrl+C para sair                    ${NC}"
echo -e "${BLUE}================================================${NC}"

while true; do
  clear
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}  Monitor Argo CD - $(date '+%H:%M:%S')                  ${NC}"
  echo -e "${BLUE}================================================${NC}"
  echo ""

  # Applications do Argo CD
  echo -e "${YELLOW}--- Applications ---${NC}"
  kubectl get applications -n argocd \
    -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,PROJECT:.spec.project' \
    2>/dev/null || echo -e "${RED}Nenhuma Application encontrada.${NC}"
  echo ""

  # ApplicationSets
  echo -e "${YELLOW}--- ApplicationSets ---${NC}"
  kubectl get applicationsets -n argocd \
    -o custom-columns='NAME:.metadata.name,GENERATORS:.spec.generators[*]' \
    2>/dev/null || echo -e "${YELLOW}Nenhum ApplicationSet encontrado.${NC}"
  echo ""

  # Pods do Argo CD
  echo -e "${YELLOW}--- Pods Argo CD (argocd) ---${NC}"
  kubectl get pods -n argocd \
    -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount' \
    2>/dev/null || echo -e "${RED}Namespace argocd nao encontrado.${NC}"
  echo ""

  # Pods da aplicacao demo
  echo -e "${YELLOW}--- Pods App Demo (demo-app) ---${NC}"
  kubectl get pods -n demo-app 2>/dev/null \
    || echo -e "${YELLOW}Namespace demo-app nao encontrado ou vazio.${NC}"
  echo ""

  # AppProjects
  echo -e "${YELLOW}--- Projects ---${NC}"
  kubectl get appprojects -n argocd \
    -o custom-columns='NAME:.metadata.name,DESCRIPTION:.spec.description' \
    2>/dev/null || echo -e "${YELLOW}Nenhum Project encontrado.${NC}"
  echo ""

  # Eventos recentes (ultimos 3)
  echo -e "${YELLOW}--- Eventos Recentes (argocd) ---${NC}"
  kubectl get events -n argocd --sort-by='.lastTimestamp' 2>/dev/null \
    | tail -5 || echo -e "${YELLOW}Sem eventos.${NC}"

  sleep $INTERVAL
done
