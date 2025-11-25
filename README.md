# Curso/Formação Kubernetes

Repositório pessoal de registro, referência e suporte para fins de aprendizado, consulta e acompanhamento do Curso de Formação em Kuberbetes, desenvolvido pela Faculdade de Tecnologia Rocketseat (FTR).

---

## Nível 1 - Fundamentos do Kubernetes

- **Avaliação de Nível:** [Questionário](./.github/docs/content/assessments/n1/q_n1.md) (15 questões)

### Módulo 1 - Introdução a Conceitos Fundamentais

#### Bloco A - Conhecendo o Kubernetes

Introdução teórica e prática ao Kubernetes: arquitetura de clusters, componentes principais (Control Plane, Worker Nodes) e configuração de ambiente local com Kind.

- **Projeto:** [`n1/m1/b-a/`](./n1/m1/b-a/)
- **Conteúdo:** Configuração de cluster Kind com 1 control-plane + 1 worker
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m1/q_b-a.md) (12 questões)

#### Bloco B - Orquestrando Containers

Prática com os principais objetos do Kubernetes: Pods, Namespaces, ReplicaSets, Deployments e Services. Demonstração de conceitos como efemeridade, replicação, rolling updates e exposição de aplicações.

- **Projeto:** [`n1/m1/b-b/`](./n1/m1/b-b/)
- **Conteúdo:** Manifests YAML comentados (namespace, pod, replicaset, deployment, service)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m1/q_b-b.md) (10 questões)

---

### Módulo 2 - Aprofundando no Workloads e Configurações

#### Bloco A - Explorando Deployment e Cenários em uma Aplicação Real

Deploy de aplicação NestJS com estratégias de atualização (RollingUpdate e Recreate), uso de ConfigMap para variáveis não sensíveis, Secret para dados confidenciais, e práticas de rollback e versionamento.

- **Projeto:** [`n1/m2/b-a/`](./n1/m2/b-a/)
- **Conteúdo:** Namespace, ConfigMap, Secret, Deployment (RollingUpdate/Recreate), Service ClusterIP
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-a.md) (13 questões)

#### Bloco B - Conhecendo o HPA

Escalonamento automático com Horizontal Pod Autoscaler: instalação do Metrics Server, configuração de HPA v1 (CPU) e v2 (CPU + Memory), políticas de behavior para controle de velocidade de scale up/down, e testes de estresse com Fortio.

- **Projeto:** [`n1/m2/b-b/`](./n1/m2/b-b/)
- **Conteúdo:** Metrics Server, HPA v1/v2, behavior policies, Fortio para load testing
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-b.md) (12 questões)

#### Bloco C - Probes e Self Healing

Monitoramento de saúde com Startup, Readiness e Liveness Probes. Configuração de probes HTTP, TCP e Exec para detecção automática de falhas e auto-recuperação de containers.

- **Projeto:** [`n1/m2/b-c/`](./n1/m2/b-c/)
- **Conteúdo:** Startup/Readiness/Liveness Probes, HTTP/Exec probes, self-healing
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-c.md) (10 questões)

#### Bloco D - Entendendo mais sobre Volumes

Armazenamento persistente com StorageClass, PersistentVolume e PersistentVolumeClaim. Diferença entre volumes efêmeros (emptyDir) e persistentes, modos de acesso (RWO, ROX, RWX) e políticas de recuperação (Retain, Delete).

- **Projeto:** [`n1/m2/b-d/`](./n1/m2/b-d/)
- **Conteúdo:** StorageClass, PV, PVC, hostPath, emptyDir, volume mounts
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-d.md) (10 questões)
