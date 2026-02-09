#!/bin/bash
# =============================================================================
# Script de Setup - Cluster Staging (Multi-Cluster)
# Nivel 4 - Modulo 1 - GitOps e ArgoCD - Aula 8
# =============================================================================
#
# Este script automatiza:
#   1. Cria cluster Kind staging (1 control-plane apenas)
#   2. Cria namespace demo-app no cluster staging
#   3. Obtem o IP real do endpoint do cluster staging
#   4. Registra cluster staging no Argo CD
#   5. Exibe informacoes para configurar Applications
#
# PRE-REQUISITO: cluster principal (n4-m1-gitops) com Argo CD instalado
#
# Uso: bash scripts/02-setup-staging.sh
# Tempo estimado: 2-3 minutos
#
# ATENCAO: Este script consome ~500-700 MB de RAM adicionais.
# Se sua maquina nao tiver RAM suficiente, use a Opcao B (namespaces).
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

MAIN_CLUSTER="n4-m1-gitops"
STAGING_CLUSTER="n4-m1-staging"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Setup: Cluster Staging (Multi-Cluster)         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ------------------------------------------
# 1. Verificar cluster principal
# ------------------------------------------
echo -e "${YELLOW}[1/5] Verificando cluster principal...${NC}"

if ! kind get clusters 2>/dev/null | grep -q "$MAIN_CLUSTER"; then
  echo -e "${RED}Cluster principal '${MAIN_CLUSTER}' nao encontrado.${NC}"
  echo -e "${RED}Execute primeiro: bash scripts/01-setup-cluster.sh${NC}"
  exit 1
fi
echo -e "${GREEN}  Cluster principal encontrado.${NC}"

# Verificar se Argo CD esta rodando
kubectl config use-context "kind-${MAIN_CLUSTER}" &> /dev/null
if ! kubectl get namespace argocd &> /dev/null; then
  echo -e "${RED}Argo CD nao esta instalado no cluster principal.${NC}"
  exit 1
fi
echo -e "${GREEN}  Argo CD esta rodando.${NC}"
echo ""

# ------------------------------------------
# 2. Criar cluster staging
# ------------------------------------------
echo -e "${YELLOW}[2/5] Criando cluster staging '${STAGING_CLUSTER}'...${NC}"

if kind get clusters 2>/dev/null | grep -q "$STAGING_CLUSTER"; then
  echo -e "${YELLOW}  Cluster '${STAGING_CLUSTER}' ja existe. Pulando.${NC}"
else
  kind create cluster --config "$PROJECT_DIR/manifests/00-kind-cluster-staging.yaml"
  echo -e "${GREEN}  Cluster staging criado.${NC}"
fi
echo ""

# ------------------------------------------
# 3. Criar namespace demo-app no staging
# ------------------------------------------
echo -e "${YELLOW}[3/5] Criando namespace demo-app no staging...${NC}"

kubectl config use-context "kind-${STAGING_CLUSTER}" &> /dev/null
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
echo -e "${GREEN}  Namespace demo-app criado no staging.${NC}"
echo ""

# ------------------------------------------
# 4. Obter IP real do cluster staging
# ------------------------------------------
echo -e "${YELLOW}[4/5] Obtendo endpoint do cluster staging...${NC}"

# O endpoint padrao do Kind usa localhost (127.0.0.1)
# Isso NAO funciona para comunicacao entre clusters Docker
# Precisamos do IP real do container Docker

STAGING_CONTAINER="${STAGING_CLUSTER}-control-plane"
STAGING_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$STAGING_CONTAINER" 2>/dev/null)

if [ -z "$STAGING_IP" ]; then
  echo -e "${RED}Nao foi possivel obter IP do cluster staging.${NC}"
  echo -e "${RED}Verifique: docker ps${NC}"
  exit 1
fi

# A porta da API do Kubernetes no Kind e 6443
STAGING_URL="https://${STAGING_IP}:6443"
echo -e "${GREEN}  Endpoint do cluster staging: ${CYAN}${STAGING_URL}${NC}"
echo ""

# ------------------------------------------
# 5. Registrar no Argo CD
# ------------------------------------------
echo -e "${YELLOW}[5/5] Registrando cluster staging no Argo CD...${NC}"

# Voltar para o contexto do cluster principal
kubectl config use-context "kind-${MAIN_CLUSTER}" &> /dev/null

# Verificar se argocd CLI esta disponivel
if command -v argocd &> /dev/null; then
  echo -e "${CYAN}  Registrando via argocd CLI...${NC}"
  echo -e "${CYAN}  Certifique-se de estar logado: argocd login localhost:8080 --insecure${NC}"

  # Registrar cluster (requer argocd CLI logado)
  argocd cluster add "kind-${STAGING_CLUSTER}" --name staging -y 2>/dev/null \
    && echo -e "${GREEN}  Cluster staging registrado no Argo CD.${NC}" \
    || echo -e "${YELLOW}  Falha ao registrar via CLI. Registre manualmente (veja instrucoes abaixo).${NC}"
else
  echo -e "${YELLOW}  argocd CLI nao encontrado. Registre o cluster manualmente.${NC}"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Setup do Staging concluido!                    ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}Informacoes do cluster staging:${NC}"
echo -e "  Nome:     ${CYAN}${STAGING_CLUSTER}${NC}"
echo -e "  IP:       ${CYAN}${STAGING_IP}${NC}"
echo -e "  Endpoint: ${CYAN}${STAGING_URL}${NC}"
echo -e "  Contexto: ${CYAN}kind-${STAGING_CLUSTER}${NC}"
echo ""
echo -e "${GREEN}Para registrar manualmente no Argo CD (se CLI falhou):${NC}"
echo -e "  1. Abra a UI: ${CYAN}https://localhost:8080${NC}"
echo -e "  2. Navegue: Settings -> Clusters -> Add Cluster"
echo -e "  3. Use a URL: ${CYAN}${STAGING_URL}${NC}"
echo ""
echo -e "${GREEN}Para usar nos manifests do Argo CD:${NC}"
echo -e "  Substitua 'STAGING-CLUSTER-URL' por: ${CYAN}${STAGING_IP}:6443${NC}"
echo ""
echo -e "${GREEN}Verificar clusters registrados:${NC}"
echo -e "  ${CYAN}argocd cluster list${NC}"
echo ""
echo -e "${GREEN}Verificar contextos kubectl:${NC}"
echo -e "  ${CYAN}kubectl config get-contexts${NC}"
