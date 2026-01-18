#!/bin/bash

# Script de Stress Test para HPA
# Gera carga na API para testar escala automatica
#
# Requisitos:
# - kubectl configurado e conectado ao cluster
# - Port-forward ativo para o service (ou LoadBalancer/Ingress configurado)
#
# Uso:
# ./stress-test.sh [cpu|memory|both] [duracao_segundos]
#
# Exemplos:
# ./stress-test.sh cpu 60       # Stress CPU por 60 segundos
# ./stress-test.sh memory 30    # Stress memoria por 30 segundos
# ./stress-test.sh both 120     # Stress CPU e memoria por 120 segundos

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuracoes
NAMESPACE="n3-m1-autoscale"
SERVICE_NAME="demo-api"
PORT=8080

# Parametros
STRESS_TYPE=${1:-cpu}
DURATION=${2:-60}

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

# Verifica se kubectl esta instalado
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl nao encontrado. Instale kubectl primeiro."
        exit 1
    fi
}

# Verifica se curl esta instalado
check_curl() {
    if ! command -v curl &> /dev/null; then
        log_error "curl nao encontrado. Instale curl primeiro."
        exit 1
    fi
}

# Verifica se o port-forward esta ativo
check_port_forward() {
    if ! nc -z localhost $PORT &> /dev/null 2>&1; then
        log_warning "Port-forward nao detectado na porta $PORT"
        log_info "Iniciando port-forward automaticamente..."
        kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME $PORT:80 &
        PORT_FORWARD_PID=$!
        sleep 3

        if nc -z localhost $PORT &> /dev/null 2>&1; then
            log_success "Port-forward iniciado (PID: $PORT_FORWARD_PID)"
            return 0
        else
            log_error "Falha ao iniciar port-forward"
            return 1
        fi
    else
        log_success "Port-forward ja ativo na porta $PORT"
        PORT_FORWARD_PID=""
        return 0
    fi
}

# Stress CPU
stress_cpu() {
    local duration=$1
    log_info "Iniciando stress test de CPU por $duration segundos..."

    local end_time=$((SECONDS + duration))
    local request_count=0

    while [ $SECONDS -lt $end_time ]; do
        # Endpoint de stress CPU (5 segundos de carga)
        curl -s "http://localhost:$PORT/stress/cpu?duration=5" > /dev/null &
        ((request_count++))

        # Limita a 10 requests paralelos
        if [ $((request_count % 10)) -eq 0 ]; then
            wait
        fi

        # Progress bar
        local remaining=$((end_time - SECONDS))
        echo -ne "${BLUE}Tempo restante: ${remaining}s | Requests: ${request_count}${NC}\r"
    done

    wait
    echo ""
    log_success "Stress CPU concluido. Total de requests: $request_count"
}

# Stress Memory
stress_memory() {
    local duration=$1
    log_info "Iniciando stress test de memoria por $duration segundos..."

    local end_time=$((SECONDS + duration))
    local request_count=0

    while [ $SECONDS -lt $end_time ]; do
        # Endpoint de stress memoria (aloca 50MB)
        curl -s "http://localhost:$PORT/stress/memory?mb=50" > /dev/null &
        ((request_count++))

        # Limita a 5 requests paralelos (memoria consome mais)
        if [ $((request_count % 5)) -eq 0 ]; then
            wait
        fi

        # Progress bar
        local remaining=$((end_time - SECONDS))
        echo -ne "${BLUE}Tempo restante: ${remaining}s | Requests: ${request_count}${NC}\r"
    done

    wait
    echo ""
    log_success "Stress memoria concluido. Total de requests: $request_count"
}

# Stress CPU e Memoria combinados
stress_both() {
    local duration=$1
    log_info "Iniciando stress test combinado (CPU + memoria) por $duration segundos..."

    local end_time=$((SECONDS + duration))
    local request_count=0

    while [ $SECONDS -lt $end_time ]; do
        # Alterna entre CPU e memoria
        if [ $((request_count % 2)) -eq 0 ]; then
            curl -s "http://localhost:$PORT/stress/cpu?duration=3" > /dev/null &
        else
            curl -s "http://localhost:$PORT/stress/memory?mb=30" > /dev/null &
        fi
        ((request_count++))

        # Limita a 8 requests paralelos
        if [ $((request_count % 8)) -eq 0 ]; then
            wait
        fi

        # Progress bar
        local remaining=$((end_time - SECONDS))
        echo -ne "${BLUE}Tempo restante: ${remaining}s | Requests: ${request_count}${NC}\r"
    done

    wait
    echo ""
    log_success "Stress combinado concluido. Total de requests: $request_count"
}

# Monitor HPA em outra janela (opcional)
monitor_hpa() {
    log_info "Para monitorar o HPA em tempo real, execute em outra janela:"
    echo ""
    echo "  watch -n 2 'kubectl get hpa,pods -n $NAMESPACE'"
    echo ""
    echo "Ou:"
    echo "  kubectl get hpa -n $NAMESPACE -w"
    echo ""
}

# Cleanup
cleanup() {
    if [ -n "$PORT_FORWARD_PID" ]; then
        log_info "Encerrando port-forward (PID: $PORT_FORWARD_PID)..."
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Trap para cleanup
trap cleanup EXIT

# Main
main() {
    log_info "=== Stress Test HPA ==="
    echo ""

    # Verificacoes
    check_kubectl
    check_curl
    check_port_forward || exit 1

    echo ""
    monitor_hpa

    # Aguarda 3 segundos para usuario abrir monitor
    log_info "Aguardando 3 segundos para voce abrir o monitor..."
    sleep 3

    # Executa stress test
    case $STRESS_TYPE in
        cpu)
            stress_cpu $DURATION
            ;;
        memory)
            stress_memory $DURATION
            ;;
        both)
            stress_both $DURATION
            ;;
        *)
            log_error "Tipo de stress invalido: $STRESS_TYPE"
            log_info "Use: cpu, memory ou both"
            exit 1
            ;;
    esac

    echo ""
    log_info "Observacoes:"
    echo "  - HPA pode levar 15-30 segundos para reagir"
    echo "  - Scale down tem stabilization window de 300s (5 minutos)"
    echo "  - Use 'kubectl describe hpa -n $NAMESPACE' para detalhes"
    echo ""
    log_success "Stress test concluido!"
}

# Executa main
main
