# Curso/Formação Kubernetes

Repositório pessoal de registro, referência e suporte para fins de aprendizado, consulta e acompanhamento do Curso de Formação em Kuberbetes, desenvolvido pela Faculdade de Tecnologia Rocketseat (FTR).

## Tabela de Referência Rápida

| Nível | Módulo | Bloco | Tema | Resumo | Videoaulas | Quiz (n° Questões) |
|-------|--------|-------|------|--------|------------|------|
| **N1** | **M1** | **A** | [Conhecendo o Kubernetes](./n1/m1/b-a/) | [Ver](./.github/docs/content/resumes/n1/m1/r_m1_b-a.md) | 8 | [12](./.github/docs/content/assessments/n1/m1/q_m1_b-a.md) |
| | | **B** | [Orquestrando Containers](./n1/m1/b-b/) | [Ver](./.github/docs/content/resumes/n1/m1/r_m1_b-b.md) | 8 | [10](./.github/docs/content/assessments/n1/m1/q_m1_b-b.md) |
| | **M2** | **A** | [Explorando Deployment e Aplicação Real](./n1/m2/b-a/) | [Ver](./.github/docs/content/resumes/n1/m2/r_m2_b-a.md) | 11 | [13](./.github/docs/content/assessments/n1/m2/q_m2_b-a.md) |
| | | **B** | [Conhecendo o HPA](./n1/m2/b-b/) | [Ver](./.github/docs/content/resumes/n1/m2/r_m2_b-b.md) | 12 | [12](./.github/docs/content/assessments/n1/m2/q_m2_b-b.md) |
| | | **C** | [Probes e Self Healing](./n1/m2/b-c/) | [Ver](./.github/docs/content/resumes/n1/m2/r_m2_b-c.md) | 8 | [10](./.github/docs/content/assessments/n1/m2/q_m2_b-c.md) |
| | | **D** | [Entendendo mais sobre Volumes](./n1/m2/b-d/) | [Ver](./.github/docs/content/resumes/n1/m2/r_m2_b-d.md) | 8 | [10](./.github/docs/content/assessments/n1/m2/q_m2_b-d.md) |
| | **-** | **-** | **Avaliação de Nível 1** | **-** | **-** | [**15**](./.github/docs/content/assessments/n1/q_n1.md) |
| **N2** | **M1** | **A** | [Kubernetes Gerenciado](./n2/m1/b-a/) | [Ver](./.github/docs/content/resumes/n2/m1/r_m1_b-a.md) | 15 | - |
| | | **B** | [Conhecendo o RBAC](./n2/m1/b-b/) | [Ver](./.github/docs/content/resumes/n2/m1/r_m1_b-b.md) | 13 | - |
| | **-** | **-** | **Avaliação do Módulo 1** | **-** | **-** | [**20**](./.github/docs/content/assessments/n2/m1/q_m1.md) |
| | **M2** | **A** | [StatefulSet e DaemonSet](./n2/m2/b-a/) | [Ver](./.github/docs/content/resumes/n2/m2/r_m2_b-a.md) | 19 | 10 |
| | | **B** | Adaptando nosso Pipeline | [Ver](./.github/docs/content/resumes/n2/m2/r_m2_b-b.md) | 9 | 10 |
| | **-** | **-** | **Avaliação do Módulo 2** | **-** | **-** | **20** |
| **N3** | **M1** | **-** | Explorando a Auto Escala de Nós | [Ver](./.github/docs/content/resumes/n3/m1/r_m1_b-u.md) | 9 | - |
| | **-** | **-** | **Avaliação do Módulo 1** | **-** | **-** | **15** |
| | **M2** | **A** | Explorando o Karpenter e definindo Roles | [Ver](./.github/docs/content/resumes/n3/m2/r_m2_b-a.md) | 3 | - |
| | | **B** | Instalação do Karpenter e prática | [Ver](./.github/docs/content/resumes/n3/m2/r_m2_b-b.md) | 6 | - |
| | **-** | **-** | **Avaliação do Módulo 2** | **-** | **-** | **15** |

---

## Demo API

A Demo API é uma aplicação NestJS 11 com Fastify projetada especificamente para demonstrar recursos Kubernetes nos três níveis do curso. Construída com Drizzle ORM e PostgreSQL 17, oferece endpoints de stress (CPU, memória, I/O) para testes de HPA e Cluster Autoscaler, CRUD completo de usuários para demonstrações de StatefulSet e persistência de dados, probes HTTP configuráveis para self-healing, e métricas Prometheus nativas para observabilidade. A stack TypeScript-native com validação via class-validator, suporte a ConfigMap/Secret, e Docker multi-stage otimizado permite explorar desde conceitos fundamentais (Deployments, Services, Probes) até patterns avançados (RBAC, CI/CD, Karpenter) em um único projeto evolutivo.

Documentação completa: [apps/demo-api/README.md](./apps/demo-api/README.md)

---

## Projeto

## Nível 1 - Fundamentos do Kubernetes

- **Avaliação de Nível:** [Questionário](./.github/docs/content/assessments/n1/q_n1.md) (15 questões)

### Módulo 1 - Introdução a Conceitos Fundamentais

#### Bloco A - Conhecendo o Kubernetes

Introdução teórica e prática ao Kubernetes: arquitetura de clusters, componentes principais (Control Plane, Worker Nodes) e configuração de ambiente local com Kind.

- **Projeto:** [`n1/m1/b-a/`](./n1/m1/b-a/)
- **Conteúdo:** Configuração de cluster Kind com 1 control-plane + 1 worker
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m1/r_m1_b-a.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m1/q_b-a.md) (12 questões)

#### Bloco B - Orquestrando Containers

Prática com os principais objetos do Kubernetes: Pods, Namespaces, ReplicaSets, Deployments e Services. Demonstração de conceitos como efemeridade, replicação, rolling updates e exposição de aplicações.

- **Projeto:** [`n1/m1/b-b/`](./n1/m1/b-b/)
- **Conteúdo:** Manifests YAML comentados (namespace, pod, replicaset, deployment, service)
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m1/r_m1_b-b.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m1/q_b-b.md) (10 questões)

---

### Módulo 2 - Aprofundando no Workloads e Configurações

#### Bloco A - Explorando Deployment e Cenários em uma Aplicação Real

Deploy de aplicação NestJS com estratégias de atualização (RollingUpdate e Recreate), uso de ConfigMap para variáveis não sensíveis, Secret para dados confidenciais, e práticas de rollback e versionamento.

- **Projeto:** [`n1/m2/b-a/`](./n1/m2/b-a/)
- **Conteúdo:** Namespace, ConfigMap, Secret, Deployment (RollingUpdate/Recreate), Service ClusterIP
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m2/r_m2_b-a.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-a.md) (13 questões)

#### Bloco B - Conhecendo o HPA

Escalonamento automático com Horizontal Pod Autoscaler: instalação do Metrics Server, configuração de HPA v1 (CPU) e v2 (CPU + Memory), políticas de behavior para controle de velocidade de scale up/down, e testes de estresse com Fortio.

- **Projeto:** [`n1/m2/b-b/`](./n1/m2/b-b/)
- **Conteúdo:** Metrics Server, HPA v1/v2, behavior policies, Fortio para load testing
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m2/r_m2_b-a.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-b.md) (12 questões)

#### Bloco C - Probes e Self Healing

Monitoramento de saúde com Startup, Readiness e Liveness Probes. Configuração de probes HTTP, TCP e Exec para detecção automática de falhas e auto-recuperação de containers.

- **Projeto:** [`n1/m2/b-c/`](./n1/m2/b-c/)
- **Conteúdo:** Startup/Readiness/Liveness Probes, HTTP/Exec probes, self-healing
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m2/r_m2_b-c.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-c.md) (10 questões)

#### Bloco D - Entendendo mais sobre Volumes

Armazenamento persistente com StorageClass, PersistentVolume e PersistentVolumeClaim. Diferença entre volumes efêmeros (emptyDir) e persistentes, modos de acesso (RWO, ROX, RWX) e políticas de recuperação (Retain, Delete).

- **Projeto:** [`n1/m2/b-d/`](./n1/m2/b-d/)
- **Conteúdo:** StorageClass, PV, PVC, hostPath, emptyDir, volume mounts
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n1/m2/r_m2_b-d.md)
- **Avaliação:** [Questionário](./.github/docs/content/assessments/n1/m2/q_m2_b-d.md) (10 questões)

---

## Nível 2 - Cloud e Persistência

### Módulo 1 - Kubernetes Gerenciado e RBAC

#### Bloco A - Kubernetes Gerenciado (Simulação Local)

Simulação de ambiente Kubernetes gerenciado (como DigitalOcean DOKS e AWS EKS) usando Kind localmente, com custo zero. Implementação de MetalLB para simular Load Balancers externos, Nginx Ingress Controller para roteamento HTTP inteligente, e stack completo de monitoramento com Prometheus e Grafana.

- **Projeto:** [`n2/m1/b-a/`](./n2/m1/b-a/)
- **Conteúdo:** Cluster Kind multi-node, MetalLB, Service LoadBalancer, Ingress Controller, Prometheus/Grafana
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n2/m1/r_m1_b-a.md)

#### Bloco B - Conhecendo o RBAC (Role-Based Access Control)

Implementação prática de RBAC (controle de acesso baseado em funções) no Kubernetes usando Kind localmente, com custo zero. Demonstração de Roles, ClusterRoles, RoleBindings, ClusterRoleBindings e ServiceAccounts para controlar quem pode fazer o que no cluster. Aplicação do princípio de privilégio mínimo e testes de permissões com kubectl auth can-i.

- **Projeto:** [`n2/m1/b-b/`](./n2/m1/b-b/)
- **Conteúdo:** Roles, ClusterRoles, RoleBindings, ClusterRoleBindings, ServiceAccounts, kubectl auth can-i
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n2/m1/r_m1_b-b.md)

---

### Módulo 2 - StatefulSets e CI/CD

#### Bloco A - StatefulSet e DaemonSet

Implementação de aplicações stateful no Kubernetes usando StatefulSets para PostgreSQL, explorando Headless Services, persistent storage (PVC), e PostgreSQL Operators (CloudNativePG) para automação de alta disponibilidade. Demonstração de DaemonSets com Prometheus Node Exporter para monitoramento de infraestrutura em todos os nodes. Conexão da demo-api com PostgreSQL persistente.

- **Projeto:** [`n2/m2/b-a/`](./n2/m2/b-a/)
- **Conteúdo:** StatefulSet, PostgreSQL, Headless Service, PVC, CloudNativePG Operator, DaemonSet, Node Exporter
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n2/m2/r_m2_b-a.md)
