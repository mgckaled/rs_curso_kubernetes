#!/bin/bash

# Script de Monitoramento de Scaling
# Monitora em tempo real HPA, pods e nodes
#
# Mostra:
# - Status do HPA (replicas atuais/desejadas, metricas)
# - Lista de pods (status, node, uso de recursos)
# - Uso de recursos dos nodes
# - Eventos recentes relacionados a scaling
#
# Uso:
# ./monitor-scaling.sh

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuracoes
NAMESPACE="n3-m1-autoscale"
REFRESH_INTERVAL=2

# Limpa tela
clear_screen() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Monitoring - HPA & Node Auto Scaling                 ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Mostra timestamp
show_timestamp() {
    echo -e "${BLUE}Atualizado em: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Mostra HPA
show_hpa() {
    echo -e "${YELLOW}═══ HorizontalPodAutoscaler ═══${NC}"
    kubectl get hpa -n $NAMESPACE -o custom-columns=\
NAME:.metadata.name,\
REFERENCE:.spec.scaleTargetRef.name,\
TARGETS:.status.currentMetrics[*].resource.current.averageUtilization,\
MINPODS:.spec.minReplicas,\
MAXPODS:.spec.maxReplicas,\
REPLICAS:.status.currentReplicas,\
AGE:.metadata.creationTimestamp 2>/dev/null || echo "HPA nao encontrado"
    echo ""
}

# Mostra detalhes do HPA
show_hpa_details() {
    echo -e "${YELLOW}═══ HPA Metricas Detalhadas ═══${NC}"

    # CPU
    local cpu_current=$(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[0].status.currentMetrics[?(@.resource.name=="cpu")].resource.current.averageUtilization}' 2>/dev/null)
    local cpu_target=$(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[0].spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}' 2>/dev/null)

    if [ -n "$cpu_current" ]; then
        echo -e "CPU: ${GREEN}${cpu_current}%${NC} / ${CYAN}${cpu_target}%${NC} (target)"
    else
        echo -e "CPU: ${RED}N/A${NC}"
    fi

    # Memoria
    local mem_current=$(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[0].status.currentMetrics[?(@.resource.name=="memory")].resource.current.averageValue}' 2>/dev/null)
    local mem_target=$(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[0].spec.metrics[?(@.resource.name=="memory")].resource.target.averageValue}' 2>/dev/null)

    if [ -n "$mem_current" ]; then
        echo -e "Memory: ${GREEN}${mem_current}${NC} / ${CYAN}${mem_target}${NC} (target)"
    else
        echo -e "Memory: ${RED}N/A${NC}"
    fi

    echo ""
}

# Mostra pods
show_pods() {
    echo -e "${YELLOW}═══ Pods ═══${NC}"
    kubectl get pods -n $NAMESPACE -o wide --sort-by=.spec.nodeName 2>/dev/null || echo "Nenhum pod encontrado"
    echo ""
}

# Mostra uso de recursos dos pods (requer Metrics Server)
show_pod_resources() {
    echo -e "${YELLOW}═══ Uso de Recursos dos Pods ═══${NC}"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics Server nao disponivel ou pods sem metricas"
    echo ""
}

# Mostra nodes
show_nodes() {
    echo -e "${YELLOW}═══ Nodes ═══${NC}"
    kubectl get nodes -o wide 2>/dev/null || echo "Erro ao obter nodes"
    echo ""
}

# Mostra uso de recursos dos nodes
show_node_resources() {
    echo -e "${YELLOW}═══ Uso de Recursos dos Nodes ═══${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics Server nao disponivel"
    echo ""
}

# Mostra eventos recentes
show_events() {
    echo -e "${YELLOW}═══ Eventos Recentes (ultimos 5) ═══${NC}"
    kubectl get events -n $NAMESPACE \
        --sort-by='.lastTimestamp' \
        --field-selector type!=Normal \
        -o custom-columns=\
TIME:.lastTimestamp,\
TYPE:.type,\
REASON:.reason,\
MESSAGE:.message \
        2>/dev/null | tail -n 6 || echo "Nenhum evento encontrado"
    echo ""
}

# Mostra PodDisruptionBudget
show_pdb() {
    echo -e "${YELLOW}═══ PodDisruptionBudget ═══${NC}"
    kubectl get pdb -n $NAMESPACE -o custom-columns=\
NAME:.metadata.name,\
MIN-AVAILABLE:.spec.minAvailable,\
MAX-UNAVAILABLE:.spec.maxUnavailable,\
ALLOWED-DISRUPTIONS:.status.disruptionsAllowed,\
CURRENT:.status.currentHealthy,\
DESIRED:.status.desiredHealthy \
        2>/dev/null || echo "PDB nao encontrado"
    echo ""
}

# Mostra legenda
show_legend() {
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "Pressione ${RED}Ctrl+C${NC} para sair | Atualizando a cada ${REFRESH_INTERVAL}s"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
}

# Loop principal
main() {
    # Trap para cleanup
    trap 'echo -e "\n${YELLOW}Monitoramento encerrado${NC}"; exit 0' INT TERM

    # Verifica se namespace existe
    if ! kubectl get namespace $NAMESPACE &>/dev/null; then
        echo -e "${RED}Namespace $NAMESPACE nao encontrado${NC}"
        exit 1
    fi

    # Loop infinito
    while true; do
        clear_screen
        show_timestamp
        show_hpa
        show_hpa_details
        show_pods
        show_pod_resources
        show_nodes
        show_node_resources
        show_pdb
        show_events
        show_legend

        sleep $REFRESH_INTERVAL
    done
}

# Executa main
main
