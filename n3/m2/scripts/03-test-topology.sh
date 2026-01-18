#!/bin/bash
# Script: Testar Distribuição e Topology
# Uso: ./03-test-topology.sh
# Descrição: Verifica distribuição de pods entre zonas e nós

set -e  # Exit on error
set -u  # Exit on undefined variable

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Verificar se cluster existe
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cluster não está acessível."
    exit 1
fi

# Verificar se namespace existe
if ! kubectl get namespace karpenter-demo &> /dev/null; then
    print_error "Namespace karpenter-demo não existe. Execute ./02-apply-manifests.sh primeiro."
    exit 1
fi

print_header "TESTE DE DISTRIBUIÇÃO E TOPOLOGY"

# ==========================================
# 1. Informações dos Nós
# ==========================================
print_header "1. INFORMAÇÕES DOS NÓS"

print_info "Nós do cluster:"
kubectl get nodes -L topology.kubernetes.io/zone,node.kubernetes.io/instance-type,disk-type,karpenter.sh/capacity-type

echo ""
print_info "Recursos dos nós:"
kubectl top nodes 2>/dev/null || print_warning "Metrics server não disponível. Instale com: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"

# ==========================================
# 2. Distribuição de Pods
# ==========================================
print_header "2. DISTRIBUIÇÃO DE PODS"

print_info "Todos os pods:"
kubectl get pods -n karpenter-demo -o wide --sort-by='.spec.nodeName'

echo ""
print_info "Contagem de pods por nó:"
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    count=$(kubectl get pods -n karpenter-demo --field-selector spec.nodeName=${node} --no-headers 2>/dev/null | wc -l)
    zone=$(kubectl get node ${node} -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')
    instance_type=$(kubectl get node ${node} -o jsonpath='{.metadata.labels.node\.kubernetes\.io/instance-type}')
    echo "  ${node} (${zone}, ${instance_type}): ${count} pods"
done

# ==========================================
# 3. Topology Spread - Distribuição por Zona
# ==========================================
print_header "3. TOPOLOGY SPREAD - DISTRIBUIÇÃO POR ZONA"

print_info "Deployment: demo-api-topology"
if kubectl get deployment demo-api-topology -n karpenter-demo &> /dev/null; then
    # Contar pods por zona
    echo ""
    print_info "Pods por zona:"
    for zone in zone-a zone-b zone-c; do
        # Obter pods na zona
        pod_count=0
        for pod in $(kubectl get pods -n karpenter-demo -l version=topology -o jsonpath='{.items[*].metadata.name}'); do
            pod_node=$(kubectl get pod ${pod} -n karpenter-demo -o jsonpath='{.spec.nodeName}')
            if [ ! -z "${pod_node}" ]; then
                node_zone=$(kubectl get node ${pod_node} -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')
                if [ "${node_zone}" == "${zone}" ]; then
                    ((pod_count++))
                fi
            fi
        done
        echo "  ${zone}: ${pod_count} pods"
    done

    # Calcular skew
    echo ""
    print_info "Análise de skew (maxSkew configurado: 1):"
    zones=($(kubectl get pods -n karpenter-demo -l version=topology -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | \
             xargs -I {} kubectl get node {} -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}' | \
             sort | uniq -c | awk '{print $1}'))

    if [ ${#zones[@]} -gt 0 ]; then
        min_pods=${zones[0]}
        max_pods=${zones[0]}
        for count in "${zones[@]}"; do
            if [ ${count} -lt ${min_pods} ]; then
                min_pods=${count}
            fi
            if [ ${count} -gt ${max_pods} ]; then
                max_pods=${count}
            fi
        done
        skew=$((max_pods - min_pods))
        echo "  Mínimo: ${min_pods} pods"
        echo "  Máximo: ${max_pods} pods"
        echo "  Skew: ${skew}"

        if [ ${skew} -le 1 ]; then
            print_success "Skew dentro do limite (maxSkew: 1)"
        else
            print_warning "Skew FORA do limite esperado (maxSkew: 1)"
        fi
    fi
else
    print_warning "Deployment demo-api-topology não encontrado"
fi

# ==========================================
# 4. Node Affinity - Verificar Nós Selecionados
# ==========================================
print_header "4. NODE AFFINITY - VERIFICAÇÃO"

print_info "Deployment: demo-api-affinity"
if kubectl get deployment demo-api-affinity -n karpenter-demo &> /dev/null; then
    echo ""
    print_info "Pods e características dos nós:"
    kubectl get pods -n karpenter-demo -l version=affinity -o custom-columns=\
POD:.metadata.name,\
NODE:.spec.nodeName,\
STATUS:.status.phase | while read -r line; do
        echo "  ${line}"
    done

    echo ""
    print_info "Verificando node affinity (preferências):"
    # Contar pods em nós on-demand
    on_demand_count=0
    for pod in $(kubectl get pods -n karpenter-demo -l version=affinity -o jsonpath='{.items[*].metadata.name}'); do
        pod_node=$(kubectl get pod ${pod} -n karpenter-demo -o jsonpath='{.spec.nodeName}')
        if [ ! -z "${pod_node}" ]; then
            capacity_type=$(kubectl get node ${pod_node} -o jsonpath='{.metadata.labels.karpenter\.sh/capacity-type}')
            if [ "${capacity_type}" == "on-demand" ]; then
                ((on_demand_count++))
            fi
        fi
    done
    total_pods=$(kubectl get pods -n karpenter-demo -l version=affinity --no-headers | wc -l)
    echo "  Pods em nós on-demand: ${on_demand_count}/${total_pods}"

    if [ ${on_demand_count} -eq ${total_pods} ]; then
        print_success "Todos pods em nós on-demand (requerimento atendido)"
    else
        print_warning "Alguns pods não estão em nós on-demand"
    fi
else
    print_warning "Deployment demo-api-affinity não encontrado"
fi

# ==========================================
# 5. Pod Anti-Affinity - Verificar Isolamento
# ==========================================
print_header "5. POD ANTI-AFFINITY - VERIFICAÇÃO"

print_info "Deployment: demo-api-anti-affinity"
if kubectl get deployment demo-api-anti-affinity -n karpenter-demo &> /dev/null; then
    echo ""
    print_info "Pods por nó:"
    kubectl get pods -n karpenter-demo -l version=anti-affinity \
        -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName \
        --sort-by='.spec.nodeName'

    echo ""
    print_info "Verificando anti-affinity (1 pod por nó):"
    # Verificar se há mais de 1 pod no mesmo nó
    violation=0
    for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        count=$(kubectl get pods -n karpenter-demo -l version=anti-affinity --field-selector spec.nodeName=${node} --no-headers 2>/dev/null | wc -l)
        if [ ${count} -gt 1 ]; then
            print_warning "Violação: ${node} tem ${count} pods"
            ((violation++))
        fi
    done

    if [ ${violation} -eq 0 ]; then
        print_success "Anti-affinity respeitada: máximo 1 pod por nó"
    else
        print_error "Anti-affinity violada em ${violation} nó(s)"
    fi
else
    print_warning "Deployment demo-api-anti-affinity não encontrado"
fi

# ==========================================
# 6. PodDisruptionBudgets
# ==========================================
print_header "6. PODDISRUPTIONBUDGETS"

print_info "Status dos PDBs:"
kubectl get pdb -n karpenter-demo

echo ""
print_info "Detalhes dos PDBs:"
kubectl get pdb -n karpenter-demo -o custom-columns=\
NAME:.metadata.name,\
MIN-AVAILABLE:.spec.minAvailable,\
MAX-UNAVAILABLE:.spec.maxUnavailable,\
CURRENT:.status.currentHealthy,\
DESIRED:.status.desiredHealthy,\
ALLOWED-DISRUPTIONS:.status.disruptionsAllowed

# ==========================================
# 7. Eventos de Scheduling
# ==========================================
print_header "7. EVENTOS DE SCHEDULING"

print_info "Eventos recentes (últimos 10):"
kubectl get events -n karpenter-demo --sort-by='.lastTimestamp' | tail -n 10

echo ""
print_info "Eventos de scheduling failures (se houver):"
kubectl get events -n karpenter-demo --field-selector reason=FailedScheduling

# ==========================================
# 8. Resumo e Recomendações
# ==========================================
print_header "8. RESUMO"

print_success "Teste concluído!"
echo ""
print_info "Comandos úteis para exploração:"
echo "  - Descrever pod: kubectl describe pod <pod-name> -n karpenter-demo"
echo "  - Ver eventos: kubectl get events -n karpenter-demo --sort-by='.lastTimestamp'"
echo "  - Watch pods: kubectl get pods -n karpenter-demo -w"
echo "  - Logs: kubectl logs -n karpenter-demo -l app=demo-api --tail=50"
echo ""
print_info "Experimentos sugeridos:"
echo "  - Escalar deployment: kubectl scale deployment demo-api-topology --replicas=9 -n karpenter-demo"
echo "  - Deletar pod: kubectl delete pod <pod-name> -n karpenter-demo"
echo "  - Drenar nó: kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data"
