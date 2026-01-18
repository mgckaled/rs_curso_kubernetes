#!/bin/bash
# Script: Aplicar Manifests Kubernetes
# Uso: ./02-apply-manifests.sh [scenario]
# Cenários: all, topology, affinity, anti-affinity
# Descrição: Aplica manifests de implementação local

set -e  # Exit on error
set -u  # Exit on undefined variable

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print colorido
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFESTS_DIR="${PROJECT_DIR}/manifests/local-implementation"

# Cenário (default: all)
SCENARIO="${1:-all}"

print_info "Aplicando manifests - Cenário: ${SCENARIO}"

# Verificar se cluster existe
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cluster não está acessível. Execute ./01-setup-cluster.sh primeiro."
    exit 1
fi

# Verificar se namespace existe
if ! kubectl get namespace karpenter-demo &> /dev/null; then
    print_warning "Namespace karpenter-demo não existe. Criando..."
    kubectl apply -f "${MANIFESTS_DIR}/01-namespace.yaml"
fi

# Aplicar Priority Classes (sempre necessário)
print_info "Aplicando Priority Classes..."
kubectl apply -f "${MANIFESTS_DIR}/05-priority-class.yaml"
print_success "Priority Classes aplicadas"
echo ""

# Função para aplicar deployment específico
apply_deployment() {
    local deployment=$1
    local file=$2

    print_info "Aplicando ${deployment}..."
    kubectl apply -f "${file}"

    # Aguardar rollout
    print_info "Aguardando rollout de ${deployment}..."
    if kubectl rollout status deployment/${deployment} -n karpenter-demo --timeout=120s; then
        print_success "${deployment} pronto"
    else
        print_error "Timeout aguardando ${deployment}"
        return 1
    fi
    echo ""
}

# Aplicar cenários
case "${SCENARIO}" in
    all)
        print_info "Aplicando TODOS os cenários..."
        apply_deployment "demo-api-topology" "${MANIFESTS_DIR}/02-deployment-topology.yaml"
        apply_deployment "demo-api-affinity" "${MANIFESTS_DIR}/03-deployment-affinity.yaml"
        apply_deployment "demo-api-anti-affinity" "${MANIFESTS_DIR}/04-deployment-anti-affinity.yaml"
        ;;
    topology)
        apply_deployment "demo-api-topology" "${MANIFESTS_DIR}/02-deployment-topology.yaml"
        ;;
    affinity)
        apply_deployment "demo-api-affinity" "${MANIFESTS_DIR}/03-deployment-affinity.yaml"
        ;;
    anti-affinity)
        apply_deployment "demo-api-anti-affinity" "${MANIFESTS_DIR}/04-deployment-anti-affinity.yaml"
        ;;
    *)
        print_error "Cenário inválido: ${SCENARIO}"
        echo "Cenários disponíveis: all, topology, affinity, anti-affinity"
        exit 1
        ;;
esac

# Aplicar PodDisruptionBudgets
print_info "Aplicando PodDisruptionBudgets..."
kubectl apply -f "${MANIFESTS_DIR}/06-pdb.yaml"
print_success "PodDisruptionBudgets aplicados"
echo ""

# Aplicar Services
print_info "Aplicando Services..."
kubectl apply -f "${MANIFESTS_DIR}/07-service.yaml"
print_success "Services aplicados"
echo ""

# Resumo
print_success "Todos manifests aplicados!"
echo ""

print_info "Status dos recursos:"
echo ""

print_info "Deployments:"
kubectl get deployments -n karpenter-demo

echo ""
print_info "Pods:"
kubectl get pods -n karpenter-demo -o wide

echo ""
print_info "Services:"
kubectl get svc -n karpenter-demo

echo ""
print_info "PodDisruptionBudgets:"
kubectl get pdb -n karpenter-demo

echo ""
print_info "Priority Classes:"
kubectl get priorityclasses | grep -E "NAME|priority"

echo ""
print_success "Aplicação concluída!"
echo ""
print_info "Próximos passos:"
echo "  - Testar distribuição: ./03-test-topology.sh"
echo "  - Ver logs: kubectl logs -n karpenter-demo -l app=demo-api"
echo "  - Descrever pod: kubectl describe pod <pod-name> -n karpenter-demo"
