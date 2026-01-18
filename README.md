# Curso/Formação Kubernetes

Repositório pessoal de registro, referência e suporte para fins de aprendizado, consulta e acompanhamento do Curso de Formação em Kuberbetes, desenvolvido pela Faculdade de Tecnologia Rocketseat (FTR).

## Proposta

Domine o Kubernetes, a principal plataforma de orquestração de contêineres do mercado, e torne-se um profissional preparado para os desafios de infraestruturas modernas e escaláveis.

Neste curso, você iniciará sua jornada pelos fundamentos, aprendendo a arquitetura do Kubernetes, desde o `control plane` até os `nodes`. Você criará seus primeiros clusters locais com `Kind` e aprenderá a gerenciar `pods`, `namespaces`, `ReplicaSets` e `Deployments`. Avançando para a prática, você executará deploys completos de aplicações, garantirá a alta disponibilidade com `Horizontal Pod Autoscaler` (HPA), implementará `probes` para `self-healing` e assegurará a persistência de dados com `volumes` e `StorageClass`.

Nos níveis seguintes, o curso aborda a operação de Kubernetes em ambientes de nuvem reais. Você aprenderá a provisionar e gerenciar clusters na DigitalOcean e AWS EKS usando Terraform, a ferramenta padrão para infraestrutura como código. Você dominará a governança e a segurança do seu cluster com `Role-Based Access Control` (RBAC), configurando `users`, `roles` e `Service Accounts`, e implementará monitoramento robusto com Prometheus e Grafana.

Para completar sua formação, exploraremos topologias avançadas e automação. Você construirá pipelines de CI/CD com GitHub Actions, automatizando o build e o deploy de suas aplicações no EKS. Aprenderá a gerenciar aplicações com estado (`stateful applications`) utilizando `StatefulSets` e `Operators`, e a implementar monitoramento distribuído com `DaemonSets`.

Ao final deste curso, você estará preparado para arquitetar, implementar e gerenciar aplicações escaláveis e resilientes em ambientes Kubernetes, desde o desenvolvimento local até a produção na nuvem, utilizando as melhores práticas e ferramentas do mercado.

## Tabela de Referência Rápida

| Nível | Módulo | Bloco | Tema | Resumo | Videoaulas | Quiz (n° Questões) |
| ------- | -------- | ------- | ------ | -------- | ------------ | ------ |
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
| | | **B** | [Adaptando nosso Pipeline](./n2/m2/b-b/) | [Ver](./.github/docs/content/resumes/n2/m2/r_m2_b-b.md) | 9 | 10 |
| | **-** | **-** | **Avaliação do Módulo 2** | **-** | **-** | **20** |
| **N3** | **M1** | **-** | [Explorando a Auto Escala de Nós](./n3/m1/b-auto-scale/) | [Ver](./.github/docs/content/resumes/n3/m1/r_m1_b-u.md) | 9 | **15** |
| | **-** | **-** | **Avaliação do Módulo 1** | **-** | **-** | **15** |
| | **M2** | **A** | [Karpenter e Scheduling Avançado](./n3/m2/) | [Ver](./.github/docs/content/resumes/n3/m2/r_m2_b-a.md) | 3 | - |
| | | **B** | [Karpenter e Scheduling Avançado](./n3/m2/) | [Ver](./.github/docs/content/resumes/n3/m2/r_m2_b-b.md) | 6 | - |
| | **-** | **-** | **Avaliação do Módulo 2** | **-** | **-** | **15** |
| | **M3** | **A** | Explorando o Spot Instance | [Ver](./.github/docs/content/resumes/n3/m3/r_m3_b-a.md) | 9 | 6 |
| | | **B** | Policies nativas do K8s | [Ver](./.github/docs/content/resumes/n3/m3/r_m3_b-b.md) | 11 | 6 |
| | | **C** | Explorando Kyverno | [Ver](./.github/docs/content/resumes/n3/m3/r_m3_b-c.md) | 9 | 6 |
| | **-** | **-** | **Avaliação do Módulo 3** | **-** | **-** | **15** |
| **N4** | **M1** | **-** | Automação e GitOps | [Ver](./.github/docs/content/resumes/n4/m1/r_m4_b-a.md) | 11 | -- |
| | **-** | **-** | **Avaliação do Módulo 1** | **-** | **-** | **18** |

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

#### Bloco B - Adaptando nosso Pipeline

Automacao de CI/CD com GitHub Actions para deploy no Kubernetes. Configuracao de workflows para build de imagens Docker, push para registry, e deploy automatico de aplicacoes. Integracao com AWS EKS usando OIDC (OpenID Connect) para autenticacao segura sem credenciais estaticas. Implementacao de deploy automatico em ambientes de staging e producao.

- **Projeto:** [`n2/m2/b-b/`](./n2/m2/b-b/)
- **Conteudo:** GitHub Actions, CI/CD workflows, Docker build/push, AWS OIDC, EKS deploy
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n2/m2/r_m2_b-b.md)

---

## Nivel 3 - Escalabilidade Avancada

### Modulo 1 - Auto Escala de Nos

#### Explorando a Auto Escala dos Nos

Implementacao pratica de HPA (Horizontal Pod Autoscaler) e compreensao teorica do Cluster Autoscaler. Configuracao de Metrics Server, definicao de resource requests/limits, implementacao de PodDisruptionBudgets para alta disponibilidade. Demonstracao de topology spread constraints, node affinity, taints e tolerations. Simulacao local de comportamentos de Cluster Autoscaler (scale up/down de nodes) usando Kind com custo zero.

- **Projeto:** [`n3/m1/b-auto-scale/`](./n3/m1/b-auto-scale/)
- **Conteudo:** HPA v2, Metrics Server, PodDisruptionBudget, Resource Management, Topology Spread, Node Management, Cluster Autoscaler (teoria + simulacao)
- **Resumo Aulas**: [Acesso](./.github/docs/content/resumes/n3/m1/r_m1_b-u.md)
- **Memoria estimada:** 1.4-2.9 GB (otimizado para ambientes com recursos limitados)

---

### Modulo 2 - Karpenter e Scheduling Avancado

#### Karpenter e Conceitos Avancados de Scheduling

Exploracao do Karpenter, ferramenta de auto-scaling de nos desenvolvida pela AWS, e implementacao pratica de conceitos avancados de scheduling no Kubernetes. Abordagem hibrida: teoria completa do Karpenter com exemplos AWS prontos para uso futuro, e pratica local com Kind explorando Topology Spread Constraints, Node Affinity, Pod Anti-Affinity, Priority Classes e PodDisruptionBudgets. Simulacao de ambiente cloud com labels personalizados e demonstracao dos mesmos conceitos que o Karpenter utiliza.

- **Projeto:** [`n3/m2/`](./n3/m2/)
- **Conteudo:** Teoria Karpenter (NodePool, NodeClass, Consolidation), Topology Spread Constraints, Node/Pod Affinity, Priority Classes, PodDisruptionBudgets, Resource Management avancado
- **Resumo Aulas**: [Bloco A](./.github/docs/content/resumes/n3/m2/r_m2_b-a.md) | [Bloco B](./.github/docs/content/resumes/n3/m2/r_m2_b-b.md)
- **Memoria estimada:** 2.0-2.5 GB (cluster Kind otimizado 1 CP + 3 workers)
- **Abordagem:** Hibrida (teoria AWS + pratica local custo zero)
