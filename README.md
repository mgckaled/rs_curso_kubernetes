# Formação Kubernetes

Repositório pessoal de registro, referência e suporte para fins de aprendizado, consulta e acompanhamento do Curso de Formação em Kuberbetes, desenvolvido pela Faculdade de Tecnologia Rocketseat (FTR).

---

## Nível 1 - Fundamentos do Kubernetes

### Módulo 1 - Introdução a Conceitos Fundamentais

#### Bloco A - Conhecendo o Kubernetes

Introdução teórica e prática ao Kubernetes: arquitetura de clusters, componentes principais (Control Plane, Worker Nodes) e configuração de ambiente local com Kind.

- **Projeto:** [`n1/m1/b-a/`](./n1/m1/b-a/)
- **Conteúdo:** Configuração de cluster Kind com 1 control-plane + 1 worker

#### Bloco B - Orquestrando Containers

Prática com os principais objetos do Kubernetes: Pods, Namespaces, ReplicaSets, Deployments e Services. Demonstração de conceitos como efemeridade, replicação, rolling updates e exposição de aplicações.

- **Projeto:** [`n1/m1/b-b/`](./n1/m1/b-b/)
- **Conteúdo:** Manifests YAML comentados (namespace, pod, replicaset, deployment, service)

---

### Módulo 2 - Aprofundando no Workloads e Configurações

#### Bloco A - Explorando Deployment e Cenários em uma Aplicação Real

Deploy de aplicação NestJS com estratégias de atualização (RollingUpdate e Recreate), uso de ConfigMap para variáveis não sensíveis, Secret para dados confidenciais, e práticas de rollback e versionamento.

- **Projeto:** [`n1/m2/b-a/`](./n1/m2/b-a/)
- **Conteúdo:** Namespace, ConfigMap, Secret, Deployment (RollingUpdate/Recreate), Service ClusterIP

#### Bloco B - Conhecendo o HPA

Escalonamento automático com Horizontal Pod Autoscaler: instalação do Metrics Server, configuração de HPA v1 (CPU) e v2 (CPU + Memory), políticas de behavior para controle de velocidade de scale up/down, e testes de estresse com Fortio.

- **Projeto:** [`n1/m2/b-b/`](./n1/m2/b-b/)
- **Conteúdo:** Metrics Server, HPA v1/v2, behavior policies, Fortio para load testing

#### Bloco C - Probes e Self Healing

Monitoramento de saúde com Startup, Readiness e Liveness Probes. Configuração de probes HTTP, TCP e Exec para detecção automática de falhas e auto-recuperação de containers.

- **Projeto:** [`n1/m2/b-c/`](./n1/m2/b-c/)
- **Conteúdo:** Startup/Readiness/Liveness Probes, HTTP/Exec probes, self-healing
