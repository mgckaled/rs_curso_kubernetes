#!/bin/bash

# Script para Simular Scale Down de Nodes
# Simula o comportamento do Cluster Autoscaler ao remover nodes
#
# O que este script faz:
# 1. Lista nodes disponiveis (exceto control-plane)
# 2. Seleciona um node para "scale down"
# 3. Adiciona taint NoSchedule (simula Cluster Autoscaler marcando node)
# 4. Drena o node (evict pods)
# 5. Aguarda pods serem recriados em outros nodes
# 6. Opcional: Remove o node do cluster (simulando delecao)
#
# Requisitos:
# - kubectl configurado e conectado ao cluster
# - Cluster com pelo menos 2 worker nodes
#
# Uso:
# ./simulate-node-scale-down.sh [node-name]
#
# Se node-name nao for especificado, o script lista nodes e pede para escolher

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuracoes
NAMESPACE="n3-m1-autoscale"
TAINT_KEY="node.kubernetes.io/scale-down"
TAINT_VALUE="scheduled"
TAINT_EFFECT="NoSchedule"

# Funcoes auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Lista worker nodes (exceto control-plane)
list_worker_nodes() {
    kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints[?(@.key=="node-role.kubernetes.io/control-plane")].key}{"\n"}{end}' | grep -v "node-role.kubernetes.io/control-plane" | awk '{print $1}'
}

# Conta numero de pods no node
count_pods_on_node() {
    local node=$1
    kubectl get pods -n $NAMESPACE -o wide --field-selector spec.nodeName=$node --no-headers 2>/dev/null | wc -l
}

# Seleciona node para scale down
select_node() {
    local target_node=$1

    if [ -z "$target_node" ]; then
        log_info "Listando worker nodes disponiveis:"
        echo ""

        # Lista nodes com contagem de pods
        local nodes=($(list_worker_nodes))
        local i=1

        if [ ${#nodes[@]} -eq 0 ]; then
            log_error "Nenhum worker node encontrado"
            exit 1
        fi

        if [ ${#nodes[@]} -eq 1 ]; then
            log_error "Apenas 1 worker node encontrado. Precisa de pelo menos 2 nodes para simular scale down."
            exit 1
        fi

        for node in "${nodes[@]}"; do
            local pod_count=$(count_pods_on_node $node)
            echo "  $i) $node (pods: $pod_count)"
            ((i++))
        done

        echo ""
        read -p "Selecione o node para scale down (1-${#nodes[@]}): " choice

        if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#nodes[@]} ]; then
            log_error "Escolha invalida"
            exit 1
        fi

        target_node="${nodes[$((choice-1))]}"
    fi

    # Verifica se node existe
    if ! kubectl get node $target_node &>/dev/null; then
        log_error "Node '$target_node' nao encontrado"
        exit 1
    fi

    # Verifica se nao e control-plane
    if kubectl get node $target_node -o jsonpath='{.spec.taints[?(@.key=="node-role.kubernetes.io/control-plane")].key}' | grep -q "node-role.kubernetes.io/control-plane"; then
        log_error "Nao e possivel fazer scale down do control-plane"
        exit 1
    fi

    echo $target_node
}

# Adiciona taint ao node
add_taint() {
    local node=$1
    log_info "Adicionando taint ao node $node..."
    log_info "Taint: $TAINT_KEY=$TAINT_VALUE:$TAINT_EFFECT"

    kubectl taint nodes $node $TAINT_KEY=$TAINT_VALUE:$TAINT_EFFECT --overwrite

    log_success "Taint adicionado. Novos pods nao serao agendados neste node."
}

# Drena o node
drain_node() {
    local node=$1
    log_info "Drenando node $node..."
    log_warning "Isso pode levar alguns minutos dependendo do numero de pods e PodDisruptionBudgets."

    kubectl drain $node \
        --ignore-daemonsets \
        --delete-emptydir-data \
        --force \
        --grace-period=30

    log_success "Node drenado com sucesso"
}

# Monitora realocacao de pods
monitor_pods() {
    log_info "Monitorando realocacao de pods..."
    echo ""

    local max_wait=60
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        local pending=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
        local running=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

        echo -ne "${BLUE}Pods Running: $running | Pods Pending: $pending | Elapsed: ${elapsed}s${NC}\r"

        if [ $pending -eq 0 ] && [ $running -gt 0 ]; then
            echo ""
            log_success "Todos pods foram realocados!"
            return 0
        fi

        sleep 2
        ((elapsed+=2))
    done

    echo ""
    log_warning "Timeout aguardando realocacao. Alguns pods podem ainda estar pending."
}

# Remove node do cluster (opcional)
delete_node() {
    local node=$1
    echo ""
    read -p "Deseja remover o node do cluster permanentemente? (s/N): " confirm

    if [[ $confirm =~ ^[Ss]$ ]]; then
        log_info "Removendo node $node do cluster..."
        kubectl delete node $node
        log_success "Node removido do cluster"
        log_warning "Em um ambiente real com Cluster Autoscaler, a VM seria terminada."
    else
        log_info "Node mantido no cluster (cordoned)"
        log_info "Para retornar o node ao estado normal:"
        echo "  kubectl uncordon $node"
        echo "  kubectl taint nodes $node $TAINT_KEY=$TAINT_VALUE:$TAINT_EFFECT-"
    fi
}

# Mostra status final
show_status() {
    echo ""
    log_info "=== Status Final ==="
    echo ""

    log_info "Nodes:"
    kubectl get nodes

    echo ""
    log_info "Pods no namespace $NAMESPACE:"
    kubectl get pods -n $NAMESPACE -o wide

    echo ""
    log_info "HPA:"
    kubectl get hpa -n $NAMESPACE
}

# Main
main() {
    local target_node=$1

    log_info "=== Simular Scale Down de Node ==="
    echo ""

    # Seleciona node
    target_node=$(select_node "$target_node")

    log_warning "Node selecionado: $target_node"
    log_warning "IMPORTANTE: Este processo ira evict todos pods deste node!"
    echo ""

    read -p "Continuar? (s/N): " confirm
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        log_info "Operacao cancelada"
        exit 0
    fi

    echo ""

    # 1. Adiciona taint (simula Cluster Autoscaler marcando node para remocao)
    add_taint $target_node

    echo ""
    log_info "Aguardando 5 segundos antes de drenar..."
    sleep 5

    # 2. Drena o node
    drain_node $target_node

    echo ""

    # 3. Monitora realocacao de pods
    monitor_pods

    # 4. Pergunta se quer remover node
    delete_node $target_node

    # 5. Mostra status final
    show_status

    echo ""
    log_success "Simulacao de scale down concluida!"
    echo ""
    log_info "Observacoes:"
    echo "  - Em um Cluster Autoscaler real, este processo seria automatico"
    echo "  - O Cluster Autoscaler respeita PodDisruptionBudgets durante drain"
    echo "  - Nodes sao marcados com taint antes de serem removidos"
    echo "  - Scale down geralmente tem um delay de 10-15 minutos"
}

# Executa main
main "$@"
