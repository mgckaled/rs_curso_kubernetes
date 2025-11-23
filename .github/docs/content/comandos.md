# Comandos

kind create cluster --name=first-cluster

kubectl cluster-info --context kind-first-cluster

kubectl get nodes

kubectl get pods -n kube-system

kind create cluster --config kind.yaml --name=first-cluster
