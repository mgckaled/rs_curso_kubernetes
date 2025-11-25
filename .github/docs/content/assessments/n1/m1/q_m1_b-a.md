<!-- markdownlint-disable -->

# Questionário Avaliativo - Módulo 1, Bloco A: Conhecendo o Kubernetes

## Questão 1

**Pergunta:** Qual é a principal função do Control Plane em um cluster Kubernetes?

**Resposta Correta:** Gerenciar o estado e a configuração do cluster, assegurando a execução dos containers conforme especificado.

**Justificativa:**

O Control Plane é o cérebro do cluster Kubernetes, responsável por tomar todas as decisões globais sobre o cluster e detectar e responder a eventos. Ele mantém o registro do estado desejado de todos os objetos no cluster e executa loops de controle contínuos para garantir que o estado atual corresponda ao estado desejado. Isso inclui decisões de agendamento de pods, detecção de falhas e início de ações corretivas.

Os componentes do Control Plane (kube-apiserver, kube-scheduler, kube-controller-manager e etcd) trabalham em conjunto para gerenciar toda a orquestração do cluster, desde a alocação de recursos até a garantia de que as aplicações estejam sempre em execução conforme declarado nos manifestos.

**Alternativas Incorretas:**

1. **Executar os containers diretamente nos nós** - Incorreto. Esta é a função dos worker nodes através do kubelet e do container runtime, não do Control Plane.

2. **Controlar a rede e o armazenamento persistente dos containers** - Incorreto. Embora o Control Plane gerencie a configuração desses recursos, a implementação real da rede é feita por plugins CNI nos workers e o armazenamento persistente é gerenciado por drivers de volume específicos.

3. **Monitorar o desempenho dos containers e escalar os recursos automaticamente** - Incorreto. O monitoramento é feito por componentes adicionais (como Metrics Server) e o escalonamento automático requer configuração específica de HPA (Horizontal Pod Autoscaler), que não é uma função nativa do Control Plane base.

5. **Armazenar os logs e métricas dos containers em tempo real** - Incorreto. O Control Plane não armazena logs de containers. Logs são mantidos nos próprios nodes e métricas requerem sistemas de observabilidade separados.

---

## Questão 2

**Pergunta:** No Kubernetes, o que é um Node?

**Resposta Correta:** Uma máquina física ou virtual onde os containers são executados.

**Justificativa:**

Um Node (nó) é uma máquina worker no Kubernetes que fornece os recursos computacionais necessários para executar as cargas de trabalho. Cada node contém os serviços necessários para executar pods e é gerenciado pelo Control Plane. Um node pode ser uma máquina física em um datacenter ou uma máquina virtual em um provedor de cloud.

Os componentes principais de um node incluem o kubelet (que garante que os containers estejam rodando), o kube-proxy (que gerencia as regras de rede) e um container runtime (como containerd ou Docker). O node reporta seu status e recursos disponíveis ao Control Plane, que usa essas informações para tomar decisões de agendamento.

**Alternativas Incorretas:**

1. **Uma máquina virtual responsável por armazenar todos os dados do cluster** - Incorreto. Nodes executam workloads, não armazenam dados do cluster. O armazenamento do estado do cluster é feito pelo etcd no Control Plane.

2. **Um banco de dados que guarda as informações de configuração do cluster** - Incorreto. Isso descreve o etcd, não um Node.

3. **Um componente responsável por gerenciar a rede entre os containers** - Incorreto. Embora nodes contenham o kube-proxy para gerenciar regras de rede, um Node em si é a máquina completa, não apenas um componente de rede.

5. **Um serviço que realiza backups automáticos do cluster** - Incorreto. Nodes não têm função de backup. Backups são responsabilidade de ferramentas externas.

---

## Questão 3

**Pergunta:** Qual é a função do Kube-Scheduler em um cluster Kubernetes?

**Resposta Correta:** Agendar e alocar os pods nos nodes de acordo com os recursos disponíveis.

**Justificativa:**

O Kube-Scheduler é o componente do Control Plane responsável por assistir aos pods recém-criados que ainda não têm um node atribuído e selecionar um node adequado para executá-los. Ele considera múltiplos fatores ao tomar decisões de agendamento, incluindo requisitos de recursos individuais e coletivos, restrições de hardware/software/políticas, especificações de afinidade e anti-afinidade, localidade de dados e interferência entre cargas de trabalho.

O scheduler avalia todos os nodes disponíveis no cluster, filtra aqueles que não atendem aos requisitos do pod e, em seguida, classifica os nodes viáveis usando funções de prioridade para selecionar o node mais adequado. Esta é uma função crítica para otimizar a utilização de recursos e garantir que as cargas de trabalho sejam distribuídas eficientemente.

**Alternativas Incorretas:**

1. **Monitorar a utilização de memória e CPU dos pods** - Incorreto. O scheduler não monitora recursos em execução, ele apenas toma decisões de colocação inicial. O monitoramento é feito pelo Metrics Server ou outras ferramentas de observabilidade.

3. **Garantir a comunicação entre os nodes e o Control Plane** - Incorreto. Esta é função do kube-apiserver como ponto central de comunicação, não do scheduler.

4. **Realizar o balanceamento de carga entre os pods** - Incorreto. Balanceamento de carga é realizado por Services através do kube-proxy, não pelo scheduler.

5. **Gerenciar a persistência de dados entre os containers** - Incorreto. Persistência de dados é gerenciada por Persistent Volumes e Persistent Volume Claims, não pelo scheduler.

---

## Questão 4

**Pergunta:** O que é o ETCD no contexto de Kubernetes?

**Resposta Correta:** Um banco de dados chave-valor que armazena as informações de configuração e estado do cluster.

**Justificativa:**

O etcd é um armazenamento de dados distribuído, consistente e de alta disponibilidade usado como backing store do Kubernetes para todos os dados do cluster. Ele armazena todo o estado do cluster, incluindo configurações, especificações e status de todos os recursos Kubernetes como pods, services, deployments, configmaps, secrets, entre outros.

O etcd implementa o algoritmo de consenso Raft para garantir consistência dos dados mesmo em caso de falhas de nodes. Todos os componentes do Kubernetes leem e escrevem dados apenas através do kube-apiserver, que por sua vez interage com o etcd. A perda do etcd significa perda completa do estado do cluster, tornando-o o componente mais crítico em termos de backup e recuperação.

**Alternativas Incorretas:**

1. **Um mecanismo de rede que gerencia as comunicações internas do cluster** - Incorreto. Rede é gerenciada por plugins CNI e pelo kube-proxy, não pelo etcd.

2. **Um serviço de monitoramento que envia alertas sobre o estado dos containers** - Incorreto. O etcd apenas armazena dados, não monitora ou envia alertas. Monitoramento é função de ferramentas como Prometheus.

4. **Um componente que realiza a instalação automática de novos nodes no cluster** - Incorreto. O etcd não gerencia a infraestrutura física ou provisionamento de nodes.

5. **Uma ferramenta de escalabilidade horizontal dos pods** - Incorreto. Escalabilidade horizontal é função do Horizontal Pod Autoscaler (HPA), não do etcd.

---

## Questão 5

**Pergunta:** O que é o conceito de Self-Healing no Kubernetes?

**Resposta Correta:** O processo de reiniciar automaticamente pods que falham, garantindo a continuidade da aplicação.

**Justificativa:**

Self-Healing é uma capacidade fundamental do Kubernetes que permite ao sistema detectar e responder automaticamente a falhas sem intervenção manual. Quando um pod falha, quebra ou se torna não-responsivo, os controladores do Kubernetes (como ReplicaSet ou Deployment) detectam essa falha e automaticamente criam novos pods para substituir os que falharam, mantendo sempre o número desejado de réplicas em execução.

Este mecanismo inclui também health checks (liveness e readiness probes) que permitem ao Kubernetes detectar containers com problemas mesmo que não tenham crasheado completamente. O self-healing garante alta disponibilidade e resiliência das aplicações, reduzindo drasticamente o tempo de inatividade e a necessidade de intervenção manual em caso de falhas.

**Alternativas Incorretas:**

1. **Um mecanismo que permite o escalonamento automático dos pods com base no tráfego** - Incorreto. Isso descreve o Horizontal Pod Autoscaler (HPA), não self-healing. Self-healing é sobre recuperação de falhas, não escalonamento baseado em carga.

2. **A capacidade do cluster de realizar backups automáticos dos containers em execução** - Incorreto. Kubernetes não realiza backups automáticos de containers. Backups são responsabilidade de ferramentas externas e estratégias de disaster recovery.

4. **Um serviço que redistribui pods entre nodes para balancear a carga** - Incorreto. Embora o scheduler distribua pods inicialmente, o rebalanceamento ativo não é uma função nativa de self-healing. Self-healing reage a falhas, não redistribui proativamente.

5. **A criação automática de novos nodes quando os recursos do cluster são insuficientes** - Incorreto. Isso seria cluster autoscaling, geralmente implementado por Cluster Autoscaler em ambientes cloud. Self-healing opera no nível de pods, não de nodes.

---

## Questão 6

**Pergunta:** O que caracteriza um ambiente Stateless no Kubernetes?

**Resposta Correta:** Um ambiente onde os pods não retêm estado ou dados entre reinicializações.

**Justificativa:**

Aplicações stateless (sem estado) são aquelas que não armazenam dados persistentes localmente e não dependem de sessões anteriores para processar novas requisições. Cada requisição é processada independentemente, sem depender de dados de requisições anteriores. Quando um pod stateless é deletado e recriado, ele inicia com um estado limpo, sem memória de execuções anteriores.

Este padrão é ideal para a natureza efêmera do Kubernetes, onde pods podem ser criados, destruídos e movidos entre nodes a qualquer momento. Aplicações stateless são mais fáceis de escalar horizontalmente, pois qualquer réplica pode atender qualquer requisição. Exemplos incluem APIs REST, servidores web servindo conteúdo estático e microserviços que delegam persistência a bancos de dados externos.

**Alternativas Incorretas:**

1. **Um ambiente onde os containers armazenam todos os dados em discos locais** - Incorreto. Isso caracteriza um ambiente stateful, não stateless. Armazenamento local implica em manter estado.

3. **Um ambiente onde todos os pods compartilham um volume persistente** - Incorreto. Uso de volumes persistentes indica ambiente stateful, pois há persistência de dados entre reinicializações.

4. **Um ambiente onde os pods têm acesso a múltiplas CPUs e grandes quantidades de memória** - Incorreto. Recursos de CPU e memória não determinam se uma aplicação é stateless ou stateful. Isso se refere apenas a requisitos de recursos computacionais.

5. **Um ambiente onde os logs dos pods são armazenados no ETCD** - Incorreto. Logs não são armazenados no etcd (que guarda apenas estado do cluster) e isso não define se uma aplicação é stateless ou stateful.

---

## Questão 7

**Pergunta:** O que é um Horizontal Pod Autoscaler (HPA) no Kubernetes?

**Resposta Correta:** Um mecanismo que escala o número de réplicas dos pods automaticamente com base em métricas de uso.

**Justificativa:**

O Horizontal Pod Autoscaler (HPA) é um recurso do Kubernetes que ajusta automaticamente o número de réplicas de pods em um Deployment, ReplicaSet ou StatefulSet com base em métricas observadas. Ele monitora continuamente métricas como utilização de CPU, memória ou métricas customizadas e aumenta ou diminui o número de pods para atender à demanda, mantendo as métricas dentro de targets especificados.

O HPA funciona em conjunto com o Metrics Server (para métricas básicas) ou sistemas de monitoramento mais avançados (para métricas customizadas). Ele implementa um loop de controle que periodicamente consulta as métricas e calcula o número ideal de réplicas necessárias. Isso permite que aplicações se adaptem automaticamente a variações de carga, otimizando uso de recursos e mantendo performance adequada durante picos de demanda.

**Alternativas Incorretas:**

1. **Um componente que gerencia a comunicação entre os nodes e o Control Plane** - Incorreto. Comunicação entre nodes e Control Plane é gerenciada pelo kube-apiserver e kubelet, não pelo HPA.

2. **Um serviço que escalona verticalmente os recursos de CPU e memória dos pods** - Incorreto. Isso descreve o Vertical Pod Autoscaler (VPA). HPA escala horizontalmente (número de pods), não verticalmente (recursos por pod).

4. **Uma ferramenta que realiza backups automáticos dos dados armazenados nos pods** - Incorreto. HPA não tem relação com backups. Ele apenas gerencia escalonamento de réplicas.

5. **Um serviço que controla o estado dos pods e realiza ações corretivas em caso de falhas** - Incorreto. Isso descreve os controladores de self-healing (como ReplicaSet), não o HPA. HPA escala baseado em métricas, não reage a falhas.

---

## Questão 8

**Pergunta:** Qual é o papel do Kubelet em um cluster Kubernetes?

**Resposta Correta:** Facilitar a comunicação entre os nodes e o Control Plane, executando instruções e relatando o status.

**Justificativa:**

O kubelet é o agente principal que roda em cada node do cluster Kubernetes. Ele é responsável por garantir que os containers estejam rodando em um pod conforme especificado. O kubelet recebe especificações de pods (PodSpecs) através do kube-apiserver e garante que os containers descritos nessas especificações estejam rodando e saudáveis.

O kubelet monitora continuamente o estado dos pods e containers no seu node, reportando informações de status de volta ao Control Plane. Ele também gerencia volumes de dados, executa health checks (liveness e readiness probes) e interage com o container runtime para iniciar, parar e gerenciar containers. É a ponte essencial entre as decisões do Control Plane e a execução real nos worker nodes.

**Alternativas Incorretas:**

1. **Monitorar a utilização de recursos e redistribuir os pods entre os nodes** - Incorreto. Redistribuição de pods é responsabilidade do scheduler durante a criação. Kubelet executa pods no node local, não os redistribui entre nodes.

2. **Gerenciar a comunicação de rede entre os containers e o mundo externo** - Incorreto. Embora kubelet configure alguns aspectos de rede, a comunicação de rede é primariamente gerenciada por plugins CNI e kube-proxy.

4. **Armazenar e proteger as informações de configuração do cluster** - Incorreto. Armazenamento de configurações é função do etcd, não do kubelet.

5. **Realizar a instalação e manutenção do cluster Kubernetes** - Incorreto. Kubelet gerencia containers em um node já configurado. Instalação e manutenção do cluster são feitas por ferramentas como kubeadm, kops ou ferramentas de IaC.

---

## Questão 9

**Pergunta:** Qual é a função principal do nó de trabalho (worker node) em um cluster Kubernetes?

**Resposta Correta:** Executar as cargas de trabalho, como aplicações.

**Justificativa:**

O worker node é onde as aplicações e workloads realmente são executados no Kubernetes. Cada worker node contém os componentes necessários para executar pods: o kubelet (gerencia a execução dos containers), o kube-proxy (gerencia regras de rede) e um container runtime (executa os containers). O worker node fornece os recursos computacionais (CPU, memória, armazenamento, rede) necessários para as aplicações.

Quando o scheduler decide em qual node um pod deve executar, é o worker node que recebe e executa esse pod. Os worker nodes reportam seu status e disponibilidade de recursos para o Control Plane, que usa essas informações para tomar decisões de agendamento. Em um cluster de produção, tipicamente há múltiplos worker nodes para distribuir a carga e fornecer redundância.

**Alternativas Incorretas:**

1. **Gerenciar os componentes do control plane** - Incorreto. O Control Plane gerencia a si mesmo. Worker nodes executam apenas workloads de aplicação, não componentes de gerenciamento do cluster.

3. **Armazenar logs e métricas do cluster** - Incorreto. Embora logs sejam gerados nos workers, o armazenamento centralizado de logs e métricas é feito por sistemas de observabilidade dedicados (Elasticsearch, Prometheus, etc.), não é função primária dos workers.

4. **Monitorar a saúde dos pods** - Incorreto. Embora o kubelet no worker execute health checks, a função principal do worker é executar as cargas, não apenas monitorar. Monitoramento é uma atividade de suporte, não a função principal.

5. **Configurar as redes internas do cluster** - Incorreto. Configuração de rede é feita por plugins CNI durante a inicialização. A função principal dos workers é executar aplicações, não configurar infraestrutura de rede.

---

## Questão 10

**Pergunta:** Qual é a vantagem de se ter múltiplos control planes em um cluster Kubernetes?

**Resposta Correta:** Garantir redundância e resiliência na gestão do cluster.

**Justificativa:**

Ter múltiplos control planes (configuração High Availability ou HA) é essencial para ambientes de produção críticos. Com múltiplos control planes, se um deles falhar, os outros continuam gerenciando o cluster, eliminando o single point of failure. Cada componente do Control Plane (kube-apiserver, kube-scheduler, kube-controller-manager) pode ter múltiplas instâncias rodando simultaneamente.

O etcd, em particular, beneficia-se de ter múltiplos membros (tipicamente 3, 5 ou 7) para manter consenso e disponibilidade dos dados mesmo com falhas de nodes. Esta configuração garante que operações críticas do cluster (criar pods, atualizar deployments, responder a falhas) continuem funcionando mesmo durante manutenção ou falhas de hardware. É uma prática obrigatória para clusters de produção que requerem alta disponibilidade.

**Alternativas Incorretas:**

1. **Aumentar o número de pods que podem ser executados simultaneamente** - Incorreto. A capacidade de executar pods é determinada pelos recursos dos worker nodes, não pela quantidade de control planes. Control planes gerenciam o cluster, não fornecem recursos computacionais para workloads.

2. **Facilitar a comunicação entre os nós de trabalho** - Incorreto. Comunicação entre workers é gerenciada pela rede do cluster (CNI) e não é afetada pelo número de control planes.

4. **Diminuir o tempo de criação dos pods** - Incorreto. Múltiplos control planes não reduzem significativamente o tempo de criação de pods. Eles fornecem redundância, não performance de criação.

5. **Reduzir o uso de memória dos nós de trabalho** - Incorreto. Control planes não afetam o uso de memória dos workers. Eles rodam em nodes separados e não competem por recursos com os workloads.

---

## Questão 11

**Pergunta:** No contexto do Kubernetes, o que é um manifesto YAML?

**Resposta Correta:** Um arquivo que descreve a configuração de recursos do Kubernetes de forma declarativa.

**Justificativa:**

Um manifesto YAML é um arquivo de configuração que define o estado desejado de recursos Kubernetes de maneira declarativa. Ao invés de especificar comandos imperativos de como criar recursos, você descreve "o que" você quer (qual deve ser o estado final) e o Kubernetes cuida de "como" alcançar esse estado. Os manifestos incluem especificações de recursos como Pods, Deployments, Services, ConfigMaps, entre outros.

Manifestos YAML seguem a estrutura da API do Kubernetes, contendo campos como apiVersion, kind, metadata e spec. Eles são versionáveis, podem ser armazenados em controle de versão (Git), facilitam revisão de código e permitem práticas de GitOps. O uso de manifestos declarativos é considerado best practice pois torna a infraestrutura reproduzível, auditável e mais fácil de gerenciar em escala.

**Alternativas Incorretas:**

1. **Um arquivo que define os logs do cluster** - Incorreto. Logs são outputs dinâmicos de aplicações em execução, não são definidos em arquivos de configuração estática como manifestos YAML.

2. **Um comando para criar nós de trabalho via CLI** - Incorreto. Manifestos são arquivos declarativos, não comandos. Além disso, nodes geralmente são provisionados pela infraestrutura, não criados via manifesto (exceto em alguns casos específicos de cluster autoscaling).

4. **Um script para monitorar a saúde dos control planes** - Incorreto. Manifestos descrevem recursos desejados, não contêm lógica de script ou monitoramento. Monitoramento é implementado por outras ferramentas.

5. **Uma ferramenta para gerenciar permissões de usuário no cluster** - Incorreto. Embora permissões possam ser definidas em manifestos YAML (via RBAC), o manifesto em si é um arquivo de configuração, não uma ferramenta de gerenciamento.

---

## Questão 12

**Pergunta:** Qual dos seguintes componentes é responsabilidade do control plane em um cluster Kubernetes?

**Resposta Correta:** CoreDNS.

**Justificativa:**

O CoreDNS é considerado um componente crítico do sistema Kubernetes e sua gestão é responsabilidade do Control Plane. Embora execute como pods nos worker nodes, o CoreDNS é um addon essencial gerenciado e mantido pelo Control Plane através de um Deployment no namespace kube-system. O Control Plane garante que o CoreDNS esteja sempre disponível e funcionando corretamente para fornecer resolução DNS interna do cluster, que é fundamental para service discovery.

A responsabilidade do Control Plane sobre o CoreDNS inclui garantir sua disponibilidade através de controladores (Deployment controller no kube-controller-manager), manter sua configuração via ConfigMaps gerenciados centralmente, e assegurar que o serviço DNS esteja acessível para todos os pods. O CoreDNS é parte integrante da infraestrutura do cluster gerenciada pelo Control Plane, diferente de workloads de aplicações que são responsabilidade dos usuários.

**Alternativas Incorretas:**

1. **Kube-proxy** - Incorreto. O kube-proxy roda em cada worker node como um DaemonSet para gerenciar regras de rede localmente (iptables/IPVS). Embora seja um componente do sistema, é considerado parte da infraestrutura do worker node, não do Control Plane.

3. **Workloads das aplicações** - Incorreto. Aplicações (pods) dos usuários executam exclusivamente em worker nodes. O Control Plane apenas orquestra e gerencia o estado desejado, mas não é responsável pelas aplicações de usuário em si.

4. **Configuração da rede interna do worker node** - Incorreto. Configuração de rede nos workers é responsabilidade dos plugins CNI (Container Network Interface) que rodam nos próprios workers. O Control Plane coordena, mas não configura diretamente a rede dos workers.

5. **Criação de volumes persistentes para os pods** - Incorreto. Embora o Control Plane coordene através do PersistentVolume controller fazendo binding de PVCs e PVs, a provisão física real é delegada a storage provisioners e drivers CSI que interagem com sistemas de armazenamento externos.
