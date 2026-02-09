#!/bin/bash
# =============================================================================
# Script de Setup - Cluster Kind + Argo CD
# Nivel 4 - Modulo 1 - GitOps e ArgoCD
# =============================================================================
#
# Este script automatiza:
#   1. Verifica dependencias (docker, kind, kubectl)
#   2. Cria cluster Kind otimizado (1 control-plane)
#   3. Cria namespace argocd
#   4. Instala Argo CD (non-HA, com UI)
#   5. Aplica patches de resource limits
#   6. Aguarda todos os pods ficarem Ready
#   7. Exibe credenciais e instrucoes de acesso
#
# Uso: bash scripts/01-setup-cluster.sh
# Tempo estimado: 3-5 minutos
# =============================================================================

set -e  # Para execucao em caso de erro

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretorio base do projeto (relativo ao script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CLUSTER_NAME="n4-m1-gitops"
ARGOCD_NAMESPACE="argocd"
# URL do manifest oficial do Argo CD (non-HA)
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Setup: Cluster Kind + Argo CD                 ${NC}"
echo -e "${BLUE}  Projeto: GitOps com Argo CD (N4-M1)           ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ------------------------------------------
# 1. Verificar dependencias
# ------------------------------------------
echo -e "${YELLOW}[1/7] Verificando dependencias...${NC}"

MISSING=0

if ! command -v docker &> /dev/null; then
  echo -e "${RED}  Docker nao encontrado.${NC}"
  MISSING=1
fi

if ! command -v kind &> /dev/null; then
  echo -e "${RED}  Kind nao encontrado.${NC}"
  MISSING=1
fi

if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}  kubectl nao encontrado.${NC}"
  MISSING=1
fi

if [ $MISSING -eq 1 ]; then
  echo -e "${RED}Instale as dependencias faltantes e tente novamente.${NC}"
  exit 1
fi

echo -e "${GREEN}  Docker, Kind e kubectl encontrados.${NC}"

# Verificar se Docker esta rodando
if ! docker info &> /dev/null; then
  echo -e "${RED}  Docker nao esta rodando. Inicie o Docker Desktop.${NC}"
  exit 1
fi
echo -e "${GREEN}  Docker esta rodando.${NC}"
echo ""

# ------------------------------------------
# 2. Criar cluster Kind
# ------------------------------------------
echo -e "${YELLOW}[2/7] Criando cluster Kind '${CLUSTER_NAME}'...${NC}"

# Verificar se cluster ja existe
if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
  echo -e "${YELLOW}  Cluster '${CLUSTER_NAME}' ja existe. Pulando criacao.${NC}"
else
  kind create cluster --config "$PROJECT_DIR/manifests/00-kind-cluster.yaml"
  echo -e "${GREEN}  Cluster '${CLUSTER_NAME}' criado com sucesso.${NC}"
fi

# Garantir contexto correto
kubectl config use-context "kind-${CLUSTER_NAME}" &> /dev/null
echo ""

# ------------------------------------------
# 3. Criar namespace argocd
# ------------------------------------------
echo -e "${YELLOW}[3/7] Criando namespace '${ARGOCD_NAMESPACE}'...${NC}"

kubectl apply -f "$PROJECT_DIR/manifests/01-namespace-argocd.yaml"
echo -e "${GREEN}  Namespace '${ARGOCD_NAMESPACE}' criado.${NC}"
echo ""

# ------------------------------------------
# 4. Instalar Argo CD
# ------------------------------------------
echo -e "${YELLOW}[4/7] Instalando Argo CD (non-HA)...${NC}"
echo -e "${CYAN}  Baixando manifest de: ${ARGOCD_INSTALL_URL}${NC}"

kubectl apply -n argocd -f "$ARGOCD_INSTALL_URL"
echo -e "${GREEN}  Argo CD instalado.${NC}"
echo ""

# ------------------------------------------
# 5. Aplicar patches de resource limits
# ------------------------------------------
echo -e "${YELLOW}[5/7] Aplicando patches de resource limits...${NC}"
echo -e "${CYAN}  Otimizando para maquinas com RAM limitada (2.5 GB)${NC}"

# Aguardar deployments existirem antes de aplicar patches
echo -e "${CYAN}  Aguardando deployments do Argo CD serem criados...${NC}"
sleep 10

# Aplicar patches individualmente para cada deployment
DEPLOYMENTS=(
  "argocd-server"
  "argocd-repo-server"
  "argocd-application-controller"
  "argocd-redis"
  "argocd-dex-server"
  "argocd-applicationset-controller"
  "argocd-notifications-controller"
)

PATCH_FILE="$PROJECT_DIR/manifests/02-argocd-resource-patches.yaml"

for DEPLOY in "${DEPLOYMENTS[@]}"; do
  if kubectl get deployment "$DEPLOY" -n argocd &> /dev/null; then
    # Extrair o nome do container correto
    CONTAINER_NAME=$(kubectl get deployment "$DEPLOY" -n argocd \
      -o jsonpath='{.spec.template.spec.containers[0].name}')

    # Determinar requests e limits baseado no componente
    case "$DEPLOY" in
      "argocd-application-controller")
        REQ_CPU="100m"; REQ_MEM="128Mi"; LIM_CPU="500m"; LIM_MEM="512Mi" ;;
      "argocd-server"|"argocd-repo-server")
        REQ_CPU="50m"; REQ_MEM="64Mi"; LIM_CPU="250m"; LIM_MEM="256Mi" ;;
      "argocd-redis")
        REQ_CPU="50m"; REQ_MEM="32Mi"; LIM_CPU="150m"; LIM_MEM="128Mi" ;;
      "argocd-applicationset-controller")
        REQ_CPU="50m"; REQ_MEM="64Mi"; LIM_CPU="200m"; LIM_MEM="128Mi" ;;
      *)
        REQ_CPU="25m"; REQ_MEM="32Mi"; LIM_CPU="100m"; LIM_MEM="64Mi" ;;
    esac

    kubectl patch deployment "$DEPLOY" -n argocd --type='json' -p="[
      {\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/resources\", \"value\": {
        \"requests\": {\"cpu\": \"${REQ_CPU}\", \"memory\": \"${REQ_MEM}\"},
        \"limits\": {\"cpu\": \"${LIM_CPU}\", \"memory\": \"${LIM_MEM}\"}
      }}
    ]" 2>/dev/null && echo -e "${GREEN}  Patch aplicado: ${DEPLOY}${NC}" \
      || echo -e "${YELLOW}  Patch ignorado: ${DEPLOY} (pode nao existir nesta versao)${NC}"
  else
    echo -e "${YELLOW}  Deployment ${DEPLOY} nao encontrado. Pulando.${NC}"
  fi
done

echo ""

# ------------------------------------------
# 6. Aguardar pods ficarem Ready
# ------------------------------------------
echo -e "${YELLOW}[6/7] Aguardando pods do Argo CD ficarem Ready...${NC}"
echo -e "${CYAN}  Isso pode levar 1-3 minutos...${NC}"

kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s 2>/dev/null \
  && echo -e "${GREEN}  Todos os deployments estao disponiveis.${NC}" \
  || echo -e "${YELLOW}  Timeout aguardando deployments. Verifique: kubectl get pods -n argocd${NC}"

echo ""

# ------------------------------------------
# 7. Exibir credenciais e instrucoes
# ------------------------------------------
echo -e "${YELLOW}[7/7] Obtendo credenciais do Argo CD...${NC}"

# Obter senha do admin
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Setup concluido com sucesso!                   ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}Credenciais do Argo CD:${NC}"
echo -e "  Usuario: ${CYAN}admin${NC}"
echo -e "  Senha:   ${CYAN}${ADMIN_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}Para acessar a UI do Argo CD:${NC}"
echo -e "  1. Execute em outro terminal:"
echo -e "     ${CYAN}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "  2. Acesse no navegador:"
echo -e "     ${CYAN}https://localhost:8080${NC}"
echo -e "  3. Aceite o certificado autoassinado"
echo -e "  4. Login com as credenciais acima"
echo ""
echo -e "${GREEN}Para usar o CLI do Argo CD (opcional):${NC}"
echo -e "  ${CYAN}argocd login localhost:8080 --insecure --username admin --password '${ADMIN_PASSWORD}'${NC}"
echo ""
echo -e "${GREEN}Verificar pods:${NC}"
echo -e "  ${CYAN}kubectl get pods -n argocd${NC}"
echo ""
echo -e "${GREEN}Verificar CRDs do Argo CD:${NC}"
echo -e "  ${CYAN}kubectl get crd | grep argo${NC}"
echo ""
echo -e "${BLUE}================================================${NC}"
