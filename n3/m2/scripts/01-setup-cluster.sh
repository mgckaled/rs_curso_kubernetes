#!/bin/bash
# Script: Setup Cluster Kind com labels simulando AWS
# Uso: ./01-setup-cluster.sh
# Descrição: Cria cluster Kind e aplica labels para simular ambiente AWS

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

# Nome do cluster
CLUSTER_NAME="karpenter-demo"

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFESTS_DIR="${PROJECT_DIR}/manifests"

print_info "Iniciando setup do cluster ${CLUSTER_NAME}..."

# Verificar se kind está instalado
if ! command -v kind &> /dev/null; then
    print_error "kind não está instalado. Instale em: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl não está instalado. Instale em: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Verificar se cluster já existe
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_warning "Cluster ${CLUSTER_NAME} já existe."
    read -p "Deseja deletar e recriar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deletando cluster existente..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        print_info "Mantendo cluster existente."
        exit 0
    fi
fi

# Criar cluster
print_info "Criando cluster Kind..."
kind create cluster --config "${MANIFESTS_DIR}/00-cluster-kind.yaml"

if [ $? -eq 0 ]; then
    print_success "Cluster criado com sucesso!"
else
    print_error "Falha ao criar cluster"
    exit 1
fi

# Aguardar cluster estar pronto
print_info "Aguardando cluster estar pronto..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Listar nós
print_info "Nós do cluster:"
kubectl get nodes -o wide

# Verificar labels automáticos do Kind
print_info "Verificando labels dos nós..."
echo ""
for node in $(kubectl get nodes -o name); do
    print_info "Labels do ${node}:"
    kubectl get ${node} --show-labels | tail -n 1
    echo ""
done

# Verificar recursos dos nós
print_info "Recursos disponíveis:"
kubectl describe nodes | grep -A 5 "Capacity:"

# Criar namespace
print_info "Criando namespace karpenter-demo..."
kubectl apply -f "${MANIFESTS_DIR}/local-implementation/01-namespace.yaml"

# Verificar namespace
kubectl get namespace karpenter-demo

print_success "Setup concluído!"
echo ""
print_info "Próximos passos:"
echo "  1. Aplicar manifests: ./02-apply-manifests.sh"
echo "  2. Testar distribuição: ./03-test-topology.sh"
echo "  3. Limpar ambiente: ./04-cleanup.sh"
echo ""
print_info "Comandos úteis:"
echo "  - Ver nós: kubectl get nodes --show-labels"
echo "  - Ver pods: kubectl get pods -n karpenter-demo -o wide"
echo "  - Contexto: kubectl config current-context"
