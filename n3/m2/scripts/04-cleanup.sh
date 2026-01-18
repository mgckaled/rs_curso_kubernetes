#!/bin/bash
# Script: Cleanup - Limpar Ambiente
# Uso: ./04-cleanup.sh [--full]
# Opções:
#   (sem opção): Deleta apenas recursos no namespace karpenter-demo
#   --full: Deleta cluster Kind completo
# Descrição: Remove recursos criados pelos scripts anteriores

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

# Modo de limpeza (padrão: namespace)
CLEANUP_MODE="${1:-namespace}"

print_info "Modo de limpeza: ${CLEANUP_MODE}"

case "${CLEANUP_MODE}" in
    --full)
        # Limpeza completa: deletar cluster Kind
        print_warning "Limpeza COMPLETA: deletar cluster ${CLUSTER_NAME}"
        echo ""
        print_warning "Isso irá:"
        echo "  - Deletar o cluster Kind completo"
        echo "  - Remover TODOS os recursos Kubernetes"
        echo "  - Não pode ser desfeito"
        echo ""
        read -p "Confirmar? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operação cancelada."
            exit 0
        fi

        # Verificar se cluster existe
        if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
            print_info "Deletando cluster ${CLUSTER_NAME}..."
            kind delete cluster --name "${CLUSTER_NAME}"

            if [ $? -eq 0 ]; then
                print_success "Cluster deletado com sucesso!"
            else
                print_error "Falha ao deletar cluster"
                exit 1
            fi
        else
            print_warning "Cluster ${CLUSTER_NAME} não existe"
        fi

        print_success "Limpeza completa concluída!"
        ;;

    namespace|--namespace)
        # Limpeza parcial: deletar apenas namespace
        print_info "Limpeza PARCIAL: deletar namespace karpenter-demo"

        # Verificar se cluster existe
        if ! kubectl cluster-info &> /dev/null; then
            print_error "Cluster não está acessível."
            exit 1
        fi

        # Verificar se namespace existe
        if ! kubectl get namespace karpenter-demo &> /dev/null; then
            print_warning "Namespace karpenter-demo não existe"
            exit 0
        fi

        echo ""
        print_info "Recursos atuais no namespace:"
        kubectl get all -n karpenter-demo
        echo ""
        kubectl get pdb -n karpenter-demo

        echo ""
        read -p "Confirmar deleção do namespace karpenter-demo? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operação cancelada."
            exit 0
        fi

        # Deletar namespace (cascata deleta todos recursos)
        print_info "Deletando namespace karpenter-demo..."
        kubectl delete namespace karpenter-demo

        if [ $? -eq 0 ]; then
            print_success "Namespace deletado com sucesso!"
        else
            print_error "Falha ao deletar namespace"
            exit 1
        fi

        # Priority Classes são cluster-scoped, deletar separadamente
        print_info "Deletando Priority Classes..."
        kubectl delete priorityclass high-priority medium-priority low-priority 2>/dev/null || print_warning "Priority Classes já foram deletadas"

        print_success "Limpeza do namespace concluída!"
        echo ""
        print_info "Cluster ${CLUSTER_NAME} ainda está rodando."
        print_info "Para deletar o cluster completo: ./04-cleanup.sh --full"
        ;;

    *)
        print_error "Opção inválida: ${CLEANUP_MODE}"
        echo ""
        echo "Uso: $0 [opção]"
        echo "Opções:"
        echo "  (sem opção) ou --namespace: Deleta apenas namespace karpenter-demo"
        echo "  --full: Deleta cluster Kind completo"
        exit 1
        ;;
esac

echo ""
print_info "Status atual:"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_info "Cluster ${CLUSTER_NAME}: EXISTE"
    kubectl get nodes 2>/dev/null || true
else
    print_info "Cluster ${CLUSTER_NAME}: NÃO EXISTE"
fi
