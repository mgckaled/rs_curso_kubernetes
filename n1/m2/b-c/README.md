# Bloco C - Probes e Self Healing

## Objetivos

- Entender as três probes do Kubernetes (Startup, Readiness, Liveness)
- Configurar probes HTTP, TCP e Exec
- Testar cenários de falha e recuperação automática
- Implementar self-healing na aplicação

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-deployment-probes.yaml       # Deployment com todas as probes configuradas
├── 02-deployment-startup.yaml      # Foco em Startup Probe (apps lentas)
├── 03-deployment-readiness.yaml    # Foco em Readiness Probe (dependências)
├── 04-deployment-liveness.yaml     # Foco em Liveness Probe (health check)
├── 05-deployment-exec-probe.yaml   # Probes usando comando exec
└── 06-service.yaml                 # Service para testes
```

---

## Conceitos Importantes

### As Três Probes

| Probe | Propósito | Quando Falha |
|-------|-----------|--------------|
| **Startup** | Verifica se a aplicação iniciou | Reinicia o container |
| **Readiness** | Verifica se está pronta para tráfego | Remove do Service (sem tráfego) |
| **Liveness** | Verifica se está saudável | Reinicia o container |

### Ordem de Execução

```plaintext
1. Container inicia
2. Startup Probe começa a verificar
3. Startup Probe passa → Liveness e Readiness começam
4. Readiness passa → Pod adicionado ao Service
5. Liveness monitora continuamente
```

### Tipos de Probe

| Tipo | Descrição | Uso |
|------|-----------|-----|
| **httpGet** | Requisição HTTP GET | APIs REST, endpoints de health |
| **tcpSocket** | Conexão TCP | Bancos de dados, serviços TCP |
| **exec** | Executa comando no container | Scripts customizados, arquivos |

### Parâmetros das Probes

| Parâmetro | Descrição | Default |
|-----------|-----------|---------|
| `initialDelaySeconds` | Tempo antes da primeira verificação | 0 |
| `periodSeconds` | Intervalo entre verificações | 10 |
| `timeoutSeconds` | Timeout para resposta | 1 |
| `successThreshold` | Sucessos consecutivos para considerar OK | 1 |
| `failureThreshold` | Falhas consecutivas para considerar falha | 3 |

---

## Pré-requisitos

### 1. Aplicar Namespace e ConfigMap do Bloco A

```bash
kubectl apply -f ../b-a/manifests/01-namespace.yaml
kubectl apply -f ../b-a/manifests/02-configmap.yaml
kubectl apply -f ../b-a/manifests/03-secret.yaml
```

### 2. Endpoints da demo-api para Probes

A demo-api possui endpoints específicos para testes:

| Endpoint | Comportamento |
|----------|---------------|
| `/health` | Sempre retorna 200 OK (liveness/startup) |
| `/ready` | Retorna 200 OK (readiness) |
| `/health/unstable` | 50% chance de erro (simula instabilidade) |
| `/health/slow?ms=N` | Delay de N ms antes de responder |
| `/crash` | Encerra o processo (testa restart) |

---

## Prática 1: Deployment com Todas as Probes

```bash
# Aplicar deployment completo
kubectl apply -f manifests/01-deployment-probes.yaml

# Verificar pods
kubectl get pods -n demo -w

# Ver eventos (probes em ação)
kubectl describe pod -n demo -l app.kubernetes.io/name=demo-api-probes

# Ver logs
kubectl logs -n demo -l app.kubernetes.io/name=demo-api-probes -f
```

---

## Prática 2: Startup Probe (Aplicações Lentas)

```bash
# Aplicar deployment com startup lento
kubectl apply -f manifests/02-deployment-startup.yaml

# Observar startup probe em ação
kubectl get pods -n demo -w

# Ver eventos detalhados
kubectl describe pod -n demo -l app.kubernetes.io/name=demo-api-startup
```

> **Dica:** O Startup Probe permite tempo total de inicialização = `failureThreshold × periodSeconds`

---

## Prática 3: Readiness Probe (Controle de Tráfego)

```bash
# Aplicar deployment com readiness
kubectl apply -f manifests/03-deployment-readiness.yaml

# Aplicar service
kubectl apply -f manifests/06-service.yaml

# Verificar endpoints do service
kubectl get endpoints demo-api-probes-service -n demo

# Simular pod não-ready (via port-forward em outro terminal)
kubectl port-forward deployment/demo-api-readiness 3000:3000 -n demo

# Chamar endpoint que falha readiness
curl http://localhost:3000/health/unstable
```

---

## Prática 4: Liveness Probe (Auto-recuperação)

```bash
# Aplicar deployment com liveness
kubectl apply -f manifests/04-deployment-liveness.yaml

# Observar restarts
kubectl get pods -n demo -w

# Forçar crash da aplicação
kubectl exec -n demo deploy/demo-api-liveness -- curl -s http://localhost:3000/crash

# Ver contador de restarts aumentar
kubectl get pods -n demo
```

---

## Prática 5: Exec Probe (Comandos Customizados)

```bash
# Aplicar deployment com exec probe
kubectl apply -f manifests/05-deployment-exec-probe.yaml

# Verificar funcionamento
kubectl get pods -n demo -w

# Ver detalhes do probe exec
kubectl describe pod -n demo -l app.kubernetes.io/name=demo-api-exec
```

---

## Cenários de Teste

### Teste 1: Simular Aplicação Instável

```bash
# Escalar para múltiplas réplicas
kubectl scale deployment demo-api-probes -n demo --replicas=3

# Observar comportamento com endpoint instável
kubectl get pods -n demo -w
```

### Teste 2: Simular Startup Lento

```bash
# Usar endpoint /health/slow para simular delay
# O deployment 02-deployment-startup.yaml usa esse endpoint
kubectl describe pod -n demo -l app.kubernetes.io/name=demo-api-startup
```

### Teste 3: Forçar Reinício via Crash

```bash
# Conectar no pod e forçar crash
kubectl exec -n demo deploy/demo-api-liveness -- curl -s http://localhost:3000/crash

# Observar restart automático
kubectl get pods -n demo -w
```

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `kubectl describe pod <name>` | Ver eventos das probes |
| `kubectl get pods -w` | Watch de status em tempo real |
| `kubectl logs <pod> --previous` | Logs do container anterior (após restart) |
| `kubectl get endpoints <svc>` | Ver IPs dos pods ready |

---

## Troubleshooting

### Probe falhando constantemente

```bash
# Verificar se o endpoint está correto
kubectl exec -n demo <pod> -- curl -s http://localhost:3000/health

# Verificar logs da aplicação
kubectl logs -n demo <pod>

# Aumentar timeoutSeconds se a aplicação é lenta
```

### Container em CrashLoopBackOff

```bash
# Ver logs do container anterior
kubectl logs -n demo <pod> --previous

# Verificar eventos
kubectl describe pod -n demo <pod>

# Ajustar initialDelaySeconds se aplicação demora para iniciar
```

---

## Checklist

- [ ] Deployment com probes aplicado
- [ ] Startup Probe funcionando
- [ ] Readiness Probe removendo pod do Service quando falha
- [ ] Liveness Probe reiniciando container quando falha
- [ ] Exec Probe executando comando customizado
- [ ] Cenário de crash testado com auto-recuperação
- [ ] Service roteando apenas para pods ready
