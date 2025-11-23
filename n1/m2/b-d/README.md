# Bloco D - Entendendo mais sobre Volumes

## Objetivos

- Entender a diferença entre volumes efêmeros e persistentes
- Criar StorageClass para gerenciamento de volumes
- Provisionar PersistentVolume (PV) e PersistentVolumeClaim (PVC)
- Montar volumes em Deployments
- Testar persistência de dados entre restarts de pods

---

## Estrutura de Arquivos

```txt
manifests/
├── 01-storageclass.yaml            # StorageClass local para Kind
├── 02-persistentvolume.yaml        # PV com hostPath (10Gi)
├── 03-persistentvolumeclaim.yaml   # PVC para aplicação (5Gi)
├── 04-deployment-volume.yaml       # Deployment com volume persistente
├── 05-deployment-emptydir.yaml     # Deployment com volume efêmero
└── 06-service.yaml                 # Service para testes
```

---

## Conceitos Importantes

### Hierarquia de Volumes

```plaintext
┌─────────────────────────────────────────────────────────┐
│                     StorageClass                        │
│  Define COMO os volumes são provisionados               │
│  (provisioner, reclaimPolicy, volumeBindingMode)        │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   PersistentVolume (PV)                 │
│  RESERVA espaço no cluster                              │
│  (capacity, accessModes, hostPath/nfs/cloud)            │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│               PersistentVolumeClaim (PVC)               │
│  REQUISITA espaço para a aplicação                      │
│  (resources.requests.storage, accessModes)              │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     Pod/Deployment                      │
│  USA o volume via volumeMounts                          │
│  (mountPath, name)                                      │
└─────────────────────────────────────────────────────────┘
```

### Tipos de Volume

| Tipo | Persistência | Ciclo de Vida | Uso |
|------|--------------|---------------|-----|
| **emptyDir** | Efêmero | Mesmo do Pod | Cache, temp files |
| **hostPath** | Persiste no node | Independente | Dev/teste single-node |
| **PVC** | Persiste | Independente | Produção, dados críticos |

### Access Modes (Modos de Acesso)

| Modo | Abreviação | Descrição |
|------|------------|-----------|
| ReadWriteOnce | RWO | Leitura/escrita por um único node |
| ReadOnlyMany | ROX | Apenas leitura por múltiplos nodes |
| ReadWriteMany | RWX | Leitura/escrita por múltiplos nodes |

### Reclaim Policies (Políticas de Recuperação)

| Política | Comportamento |
|----------|---------------|
| **Retain** | PV mantido após delete do PVC (dados preservados) |
| **Delete** | PV deletado junto com PVC (dados perdidos) |
| **Recycle** | Deprecated - limpava dados e reutilizava |

---

## Pré-requisitos

### 1. Aplicar Namespace do Bloco A

```bash
kubectl apply -f ../b-a/manifests/01-namespace.yaml
kubectl apply -f ../b-a/manifests/02-configmap.yaml
kubectl apply -f ../b-a/manifests/03-secret.yaml
```

### 2. Criar diretório no node do Kind

```bash
# Acessar o node do Kind
docker exec -it k8s-lab-worker mkdir -p /mnt/data

# Verificar se foi criado
docker exec -it k8s-lab-worker ls -la /mnt/
```

### 3. Build da Imagem (se ainda não fez)

```bash
cd apps/demo-api
docker build -t demo-api:v1 .
kind load docker-image demo-api:v1 --name k8s-lab
```

---

## Prática 1: StorageClass

```bash
# Aplicar StorageClass
kubectl apply -f manifests/01-storageclass.yaml

# Verificar StorageClasses (inclui o default do Kind)
kubectl get storageclass

# Ver detalhes
kubectl describe storageclass local-storage
```

---

## Prática 2: PersistentVolume

```bash
# Criar PersistentVolume
kubectl apply -f manifests/02-persistentvolume.yaml

# Verificar PV criado
kubectl get pv

# Ver detalhes
kubectl describe pv demo-api-pv
```

> **Status esperado:** `Available` (aguardando um PVC)

---

## Prática 3: PersistentVolumeClaim

```bash
# Criar PersistentVolumeClaim
kubectl apply -f manifests/03-persistentvolumeclaim.yaml

# Verificar PVC
kubectl get pvc -n demo

# Verificar binding com PV
kubectl get pv
```

> **Status esperado:** PVC `Bound`, PV `Bound`

---

## Prática 4: Deployment com Volume Persistente

```bash
# Aplicar Deployment
kubectl apply -f manifests/04-deployment-volume.yaml

# Verificar pod
kubectl get pods -n demo

# Aplicar Service
kubectl apply -f manifests/06-service.yaml

# Port-forward para testar
kubectl port-forward svc/demo-api-volume-service 3000:80 -n demo
```

### Testar Persistência

```bash
# Terminal 1: Port-forward
kubectl port-forward svc/demo-api-volume-service 3000:80 -n demo

# Terminal 2: Criar arquivo
curl -X POST http://localhost:3000/files \
  -H "Content-Type: application/json" \
  -d '{"name": "teste.txt", "content": "Dados persistentes!"}'

# Listar arquivos
curl http://localhost:3000/files

# Deletar o pod (simula crash)
kubectl delete pod -n demo -l app.kubernetes.io/name=demo-api-volume

# Aguardar novo pod
kubectl get pods -n demo -w

# Verificar se arquivo ainda existe (persistiu!)
curl http://localhost:3000/files
```

---

## Prática 5: Deployment com emptyDir (Volume Efêmero)

```bash
# Aplicar Deployment com emptyDir
kubectl apply -f manifests/05-deployment-emptydir.yaml

# Port-forward
kubectl port-forward deploy/demo-api-emptydir 3001:3000 -n demo
```

### Testar Efemeridade

```bash
# Criar arquivo
curl -X POST http://localhost:3001/files \
  -H "Content-Type: application/json" \
  -d '{"name": "temporario.txt", "content": "Dados temporários!"}'

# Verificar arquivo existe
curl http://localhost:3001/files

# Deletar o pod
kubectl delete pod -n demo -l app.kubernetes.io/name=demo-api-emptydir

# Aguardar novo pod
kubectl get pods -n demo -w

# Verificar se arquivo SUMIU (emptyDir é efêmero!)
curl http://localhost:3001/files
```

---

## Prática 6: Verificar Dados no Node

```bash
# Acessar o node do Kind
docker exec -it k8s-lab-worker /bin/sh

# Listar arquivos no volume
ls -la /mnt/data/

# Ver conteúdo de um arquivo
cat /mnt/data/teste.txt

# Sair
exit
```

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `kubectl get storageclass` | Listar StorageClasses |
| `kubectl get pv` | Listar PersistentVolumes |
| `kubectl get pvc -n demo` | Listar PVCs no namespace |
| `kubectl describe pv <name>` | Detalhes do PV |
| `kubectl describe pvc <name> -n demo` | Detalhes do PVC |
| `kubectl exec -it <pod> -- ls /app/uploads` | Listar arquivos no volume |

---

## Troubleshooting

### PVC fica em Pending

```bash
# Verificar eventos do PVC
kubectl describe pvc demo-api-pvc -n demo

# Causas comuns:
# - StorageClass não existe
# - PV não disponível com capacidade suficiente
# - Access mode incompatível
```

### PV fica em Released (não Available)

```bash
# Após deletar PVC, PV com Retain fica em Released
# Para reutilizar, precisa remover o claimRef

kubectl patch pv demo-api-pv -p '{"spec":{"claimRef": null}}'
```

### Dados não persistem

```bash
# Verificar se o volume está montado corretamente
kubectl describe pod <pod-name> -n demo | grep -A10 "Mounts:"

# Verificar se está usando PVC e não emptyDir
kubectl get deployment demo-api-volume -n demo -o yaml | grep -A20 "volumes:"
```

---

## Checklist

- [ ] StorageClass `local-storage` criado
- [ ] PersistentVolume `demo-api-pv` criado e Available
- [ ] PersistentVolumeClaim `demo-api-pvc` criado e Bound
- [ ] Deployment com volume montado em `/app/uploads`
- [ ] Arquivo criado via API `/files`
- [ ] Pod deletado e recriado - arquivo persistiu
- [ ] emptyDir testado - arquivo perdido após restart
- [ ] Dados verificados diretamente no node
