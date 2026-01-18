# Questionário Avaliativo de Kubernetes - 22 Questões

## Questão 2/22

**Pergunta:** No behavior do HPA v2, o que faz a configuração `stabilizationWindow`?

**Resposta Correta:** ✅ Opção 3 - "Estabelece o tempo de espera antes de iniciar o processo de scale up ou scale down"

**Explicação:**

A configuração `stabilizationWindow` no HPA v2 define uma janela de tempo de estabilização que controla quanto tempo o HPA deve esperar antes de efetivamente executar uma ação de escalonamento (seja aumentar ou reduzir pods). Essa janela impede que o HPA reaja imediatamente a picos temporários de métricas, evitando o "flapping" (oscilações rápidas entre scale up e down). Por exemplo, se você configurar `stabilizationWindow: 300s`, o HPA observará as métricas durante 5 minutos e só executará o escalonamento se a condição persistir durante todo esse período, garantindo que mudanças sejam baseadas em tendências reais e não em flutuações momentâneas.

**Por que as outras opções estão incorretas:**

- **Opção 1** (tempo máximo para escalar pods): Essa funcionalidade não define o tempo de execução do escalonamento, mas sim o tempo de observação antes de decidir escalar.
- **Opção 2** (tempo limite para criação de novos pods): A criação de pods é responsabilidade do scheduler e dos controllers do Kubernetes, não uma configuração do HPA.
- **Opção 4** (intervalo entre verificações de métricas): O intervalo de verificação de métricas é controlado pelo parâmetro `--horizontal-pod-autoscaler-sync-period` (padrão 15 segundos), não pelo `stabilizationWindow`.
- **Opção 5** (janela de monitoramento de CPU e memória): Embora o HPA monitore métricas, o `stabilizationWindow` não define qual janela de dados é coletada, mas sim quanto tempo esperar antes de agir sobre essas métricas.

---

## Questão 3/22

**Pergunta:** Qual é a principal diferença entre ConfigMap e Secret no Kubernetes?

**Resposta Correta:** ✅ Opção 4 - "ConfigMap é para dados não sensíveis, Secret para dados sensíveis codificados em base64"

**Explicação:**

A principal diferença entre ConfigMap e Secret no Kubernetes está relacionada ao tipo de dado que cada recurso é projetado para armazenar. ConfigMaps são destinados a armazenar dados de configuração não sensíveis como variáveis de ambiente, arquivos de configuração de aplicações, parâmetros, etc., e os dados são armazenados em texto plano. Já os Secrets são projetados especificamente para armazenar informações sensíveis como senhas, tokens de API, chaves SSH e certificados TLS. Os dados em Secrets são codificados em base64 (não criptografados por padrão, mas ofuscados) e o Kubernetes aplica controles de acesso mais restritivos a eles. Além disso, Secrets podem ser criptografados em repouso (at rest) quando configurado no cluster, e são tratados com maior cuidado pelo sistema, como não aparecer em logs por padrão.

**Por que as outras opções estão incorretas:**

- **Opção 1** (ConfigMap é criptografado, Secret não é): Invertida. Na verdade, é o Secret que pode ser criptografado em repouso, enquanto ConfigMap não possui essa funcionalidade nativa.
- **Opção 2** (ConfigMap armazena JSON, Secret YAML): Ambos são recursos Kubernetes definidos em YAML (ou JSON) e podem armazenar dados em diversos formatos independentemente de como são declarados.
- **Opção 3** (ConfigMap apenas com Deployments, Secret com qualquer workload): Ambos os recursos podem ser consumidos por qualquer tipo de workload do Kubernetes (Deployments, StatefulSets, DaemonSets, Jobs, etc.).
- **Opção 5** (Não há diferença funcional): Existem diferenças funcionais significativas, especialmente relacionadas à segurança, controle de acesso, criptografia opcional e como o Kubernetes trata esses recursos internamente.

---

## Questão 4/22

**Pergunta:** Quais são as três principais interfaces (APIs) que o Kubernetes utiliza para abstrair diferentes componentes?

**Resposta Correta:** ✅ Opção 1 - "CRI, CNI e CSI"

**Explicação:**

O Kubernetes utiliza três interfaces principais para abstrair e padronizar a integração com diferentes componentes de infraestrutura: **CRI (Container Runtime Interface)** permite que o Kubernetes trabalhe com diferentes runtimes de contêineres como containerd, CRI-O ou Docker, abstraindo a implementação específica de execução de contêineres; **CNI (Container Network Interface)** padroniza como plugins de rede se integram ao Kubernetes, permitindo soluções como Calico, Flannel, Weave ou Cilium implementarem networking de pods; e **CSI (Container Storage Interface)** abstrai diferentes sistemas de armazenamento, permitindo que providers como AWS EBS, GCE Persistent Disk, Ceph ou NFS forneçam volumes persistentes de forma padronizada. Essas três interfaces são fundamentais para a arquitetura plugável e extensível do Kubernetes, permitindo escolher as melhores soluções para cada necessidade sem alterar o core do sistema.

**Por que as outras opções estão incorretas:**

- **Opção 2** (HTTP, TCP e UDP): Esses são protocolos de rede de camada de transporte e aplicação, não interfaces de abstração do Kubernetes para componentes.
- **Opção 3** (REST, SOAP e GraphQL): Esses são estilos arquiteturais ou protocolos para APIs web. O Kubernetes usa REST para sua API, mas não são as interfaces de abstração de componentes.
- **Opção 4** (JSON, XML e YAML): Esses são formatos de serialização de dados usados para configuração e comunicação, não interfaces de abstração de componentes.
- **Opção 5** (API, CLI e GUI): Esses são métodos de interação com o Kubernetes, não as interfaces de abstração que conectam componentes de infraestrutura.

---

## Questão 5/22

**Pergunta:** O que é o Kind?

**Resposta Correta:** ✅ Opção 4 - "Uma ferramenta para executar Kubernetes localmente usando containers Docker"

**Explicação:**

Kind (Kubernetes IN Docker) é uma ferramenta desenvolvida pela comunidade Kubernetes especificamente para executar clusters Kubernetes locais utilizando containers Docker como "nodes". Diferentemente de soluções como Minikube que usam máquinas virtuais, o Kind cria nodes do cluster como containers Docker, tornando-o extremamente rápido para inicializar e muito mais leve em termos de recursos. É amplamente utilizado para testes, desenvolvimento local, integração contínua (CI) e para testar o próprio Kubernetes. O Kind permite criar clusters multi-node rapidamente, simular diferentes topologias de cluster e é a ferramenta oficial usada para testar o próprio Kubernetes antes de releases. Por executar tudo em containers, é possível ter múltiplos clusters isolados rodando simultaneamente na mesma máquina sem conflitos.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Um componente de rede do Kubernetes): Kind não é um componente de rede. Componentes de rede do Kubernetes incluem plugins CNI como Calico, Flannel ou Cilium.
- **Opção 2** (Uma versão simplificada do kubectl): Kind não é uma variação do kubectl. O kubectl é a ferramenta de linha de comando para interagir com clusters, enquanto Kind é usado para criar clusters locais.
- **Opção 3** (Um sistema de armazenamento): Kind não é uma solução de armazenamento. Sistemas de armazenamento para Kubernetes são implementados através de CSI drivers.
- **Opção 5** (Um tipo especial de pod): Kind não é um tipo de pod ou recurso do Kubernetes. É uma ferramenta externa que cria clusters Kubernetes completos para desenvolvimento e teste.

---

## Questão 6/22

**Pergunta:** Qual a principal diferença entre as estratégias de deploy "Recreate" e "Rolling Update"?

**Resposta Correta:** ✅ Opção 4 - "Recreate deleta todos os pods de uma vez, Rolling Update substitui pods gradualmente"

**Explicação:**

A principal diferença entre as estratégias de deploy "Recreate" e "Rolling Update" está na forma como os pods são atualizados durante um deployment. A estratégia **Recreate** termina todos os pods da versão antiga simultaneamente antes de criar os novos pods, causando um período de downtime onde a aplicação fica indisponível. Já a estratégia **Rolling Update** (padrão no Kubernetes) substitui os pods gradualmente, criando novos pods com a versão atualizada enquanto remove progressivamente os pods antigos, garantindo que sempre haja pods disponíveis para atender requisições durante todo o processo de atualização. O Rolling Update permite configurar parâmetros como `maxUnavailable` (quantos pods podem ficar indisponíveis) e `maxSurge` (quantos pods extras podem ser criados), oferecendo zero downtime e possibilidade de rollback automático em caso de falha.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Recreate para stateful, Rolling Update para stateless): Ambas estratégias podem ser usadas com Deployments (normalmente stateless). Para aplicações stateful, usa-se StatefulSets que têm suas próprias estratégias de atualização.
- **Opção 2** (Recreate só com ReplicaSets, Rolling Update só com Deployments): Ambas são estratégias de atualização configuráveis em Deployments. ReplicaSets são recursos de nível inferior gerenciados pelos Deployments.
- **Opção 3** (Recreate é mais rápido que Rolling Update): Na verdade, Recreate pode ser mais rápido em termos de tempo total de transição, mas causa downtime. Rolling Update leva mais tempo total mas mantém disponibilidade.
- **Opção 5** (Recreate usa menos recursos que Rolling Update): Rolling Update temporariamente usa mais recursos pois mantém pods antigos e novos simultaneamente durante a transição.

---

## Questão 7/22

**Pergunta:** Por que não é recomendado usar o namespace `default` para deployar aplicações em produção no Kubernetes?

**Resposta Correta:** ✅ Opção 5 - "O namespace default não permite identificar facilmente qual time ou aplicação possui os recursos"

**Explicação:**

Não é recomendado usar o namespace `default` para aplicações em produção porque ele dificulta a organização, governança e gestão de recursos em ambientes corporativos. Quando todos os recursos são criados no namespace `default`, torna-se extremamente difícil identificar qual time, projeto ou aplicação é responsável por determinados pods, services ou deployments, especialmente em clusters compartilhados por múltiplas equipes. Namespaces customizados permitem implementar isolamento lógico, aplicar políticas de segurança específicas (RBAC, Network Policies), definir quotas de recursos por projeto/equipe, facilitar auditoria e monitoramento, e organizar recursos de forma clara e escalável. A melhor prática é criar namespaces dedicados por ambiente (dev, staging, prod), por aplicação, por time ou por projeto, permitindo melhor controle, segurança e observabilidade dos recursos no cluster.

**Por que as outras opções estão incorretas:**

- **Opção 1** (não suporta services ClusterIP): O namespace `default` suporta todos os tipos de services, incluindo ClusterIP, NodePort e LoadBalancer, sem qualquer restrição.
- **Opção 2** (só aceita pods, não aceita deployments): O namespace `default` aceita todos os tipos de recursos do Kubernetes, incluindo Pods, Deployments, StatefulSets, Services, etc.
- **Opção 3** (tem limitações de recursos computacionais): Por padrão, o namespace `default` não tem limitações de recursos. Quotas devem ser explicitamente configuradas através de ResourceQuotas.
- **Opção 4** (não suporta múltiplos containers por pod): Qualquer namespace, incluindo o `default`, suporta pods com múltiplos containers (sidecar pattern, init containers, etc.).

---

## Questão 8/22

**Pergunta:** Qual é o papel do namespace no Kubernetes?

**Resposta Correta:** ✅ Opção 1 - "Separação lógica de recursos para organização"

**Explicação:**

O papel fundamental do namespace no Kubernetes é fornecer uma separação lógica de recursos dentro de um cluster, permitindo organizar e isolar recursos de forma virtual. Namespaces criam escopos isolados para nomes de recursos, possibilitando que diferentes equipes, projetos ou ambientes compartilhem o mesmo cluster físico sem conflitos de nomenclatura. Além da organização, namespaces permitem aplicar políticas de segurança específicas através de RBAC (Role-Based Access Control), definir quotas de recursos computacionais (CPU, memória) por namespace usando ResourceQuotas, implementar Network Policies para isolamento de rede entre namespaces, e facilitar a gestão multi-tenant. É importante entender que namespaces são apenas isolamento lógico - todos os namespaces compartilham os mesmos nodes físicos do cluster, diferente de uma separação física real de infraestrutura.

**Por que as outras opções estão incorretas:**

- **Opção 2** (Backup automático de dados): Namespaces não têm relação com backup de dados. Backups são implementados através de ferramentas externas como Velero ou soluções específicas de storage.
- **Opção 3** (Separação física de recursos): Namespaces fornecem apenas separação **lógica**, não física. Todos os namespaces compartilham os mesmos nodes físicos do cluster.
- **Opção 4** (Controle de versão de aplicações): Controle de versão é gerenciado por Deployments através de strategies como Rolling Update e suas configurações de imagem/tag, não por namespaces.
- **Opção 5** (Monitoramento de performance): Monitoramento é implementado através de ferramentas como Prometheus, Grafana, ou sistemas de observabilidade, não através de namespaces.

---

## Questão 9/22

**Pergunta:** Qual problema principal o Kubernetes foi criado para resolver?

**Resposta Correta:** ✅ Opção 1 - "Problemas de escala e orquestração de containers"

**Explicação:**

O Kubernetes foi criado principalmente para resolver os desafios complexos de **escala e orquestração de containers** em ambientes de produção. Antes do Kubernetes, gerenciar aplicações containerizadas em grande escala era extremamente difícil - era necessário manualmente provisionar containers, garantir alta disponibilidade, balancear carga, gerenciar falhas, escalar aplicações e coordenar deployments em múltiplos servidores. O Kubernetes automatiza todos esses processos através de orquestração inteligente: ele gerencia onde e quando containers são executados, escala automaticamente baseado em demanda, substitui containers que falham, distribui carga de trabalho, gerencia atualizações sem downtime e fornece service discovery e networking entre containers. Nascido da experiência do Google com sistemas internos como Borg e Omega, o Kubernetes democratizou a capacidade de operar aplicações containerizadas em escala cloud-native de forma confiável e eficiente.

**Por que as outras opções estão incorretas:**

- **Opção 2** (Problemas de backup de dados): Backup de dados não é o foco principal do Kubernetes. Embora suporte volumes persistentes, backup é responsabilidade de ferramentas específicas.
- **Opção 3** (Problemas de segurança em containers): Embora o Kubernetes ofereça recursos de segurança (RBAC, Network Policies, Pod Security), segurança não foi o problema principal que motivou sua criação.
- **Opção 4** (Problemas de monitoramento de aplicações): Monitoramento não é a função principal do Kubernetes. O Kubernetes expõe métricas e integra-se com ferramentas de monitoramento, mas não foi criado para resolver problemas de observabilidade.
- **Opção 5** (Problemas de versionamento de código): Versionamento de código é responsabilidade de sistemas de controle de versão como Git. O Kubernetes gerencia deployment de containers, não o código-fonte em si.

---

## Questão 10/22

**Pergunta:** Qual é a diferença entre um Pod e um Deployment?

**Resposta Correta:** ✅ Opção 4 - "Pod é a menor unidade sem controle, Deployment controla versão e réplicas"

**Explicação:**

A diferença fundamental entre Pod e Deployment está no nível de abstração e controle. Um **Pod** é a menor unidade computacional no Kubernetes - representa um ou mais containers executando juntos, compartilhando rede e volumes, mas é efêmero e sem gerenciamento automático de ciclo de vida. Se um Pod falhar, ele simplesmente morre e não é recriado automaticamente. Já um **Deployment** é um recurso de nível superior que gerencia Pods de forma declarativa, controlando quantas réplicas devem estar rodando, gerenciando atualizações de versão (rolling updates), realizando rollbacks automáticos em caso de falha, garantindo o estado desejado (self-healing), e mantendo o número especificado de réplicas sempre disponível. O Deployment cria e gerencia ReplicaSets, que por sua vez gerenciam os Pods. Na prática, Pods raramente são criados diretamente em produção - usa-se Deployments que abstraem a complexidade de gerenciamento.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Pod para desenvolvimento, Deployment para produção): Tanto Pods quanto Deployments podem ser usados em qualquer ambiente. A diferença não é o ambiente, mas sim o nível de gerenciamento.
- **Opção 2** (Não há diferença, são sinônimos): São conceitos completamente diferentes: Pod é a unidade básica de execução, Deployment é um controller que gerencia Pods.
- **Opção 3** (Pod roda apenas em Linux, Deployment em qualquer OS): Ambos são abstrações do Kubernetes e podem executar em nodes com diferentes sistemas operacionais.
- **Opção 5** (Pod para aplicações web, Deployment para APIs): Não há essa separação de uso. Tanto aplicações web quanto APIs devem usar Deployments para beneficiar-se do gerenciamento automatizado.

---

## Questão 11/22

**Pergunta:** Qual é a hierarquia correta dos objetos Kubernetes, do mais alto nível para o mais baixo nível?

**Resposta Correta:** ✅ Opção 4 - "Deployment → ReplicaSet → Pod"

**Explicação:**

A hierarquia correta dos principais objetos de workload no Kubernetes, do mais alto nível de abstração para o mais baixo, é **Deployment → ReplicaSet → Pod**. O **Deployment** é o recurso de mais alto nível que você geralmente interage, definindo declarativamente o estado desejado da aplicação (quantas réplicas, qual imagem, estratégia de atualização). O Deployment cria e gerencia automaticamente um **ReplicaSet**, que é o objeto responsável por garantir que o número correto de réplicas de Pods esteja sempre executando. O ReplicaSet, por sua vez, cria e monitora os **Pods**, que são a menor unidade executável contendo os containers da aplicação. Quando você atualiza um Deployment, ele cria um novo ReplicaSet com a nova versão enquanto gradualmente escala down o ReplicaSet antigo, permitindo rolling updates. Namespaces ficam fora dessa hierarquia pois servem apenas como escopo de organização lógica.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Namespace → Service → Pod): Namespace não gerencia Services ou Pods hierarquicamente - apenas os organiza logicamente. Service também não gerencia Pods, apenas roteia tráfego.
- **Opção 2** (Service → Deployment → Pod): Service não gerencia Deployments nem Pods - Service é um recurso separado que expõe Pods através de networking.
- **Opção 3** (Pod → ReplicaSet → Deployment): Esta hierarquia está invertida. Pod é o nível mais baixo, ReplicaSet gerencia Pods, e Deployment gerencia ReplicaSets.
- **Opção 5** (ReplicaSet → Deployment → Pod): A ordem está errada. Deployment é o nível mais alto que cria/gerencia ReplicaSets, que por sua vez gerenciam Pods.

---

## Questão 12/22

**Pergunta:** Qual é a diferença entre StartupProbe, ReadinessProbe e LivenessProbe?

**Resposta Correta:** ✅ Opção 1 - "StartupProbe verifica se o container subiu, ReadinessProbe verifica se está pronto para receber tráfego, LivenessProbe verifica se está funcionando"

**Explicação:**

As três probes têm propósitos distintos no ciclo de vida do container. A **StartupProbe** é executada apenas durante a inicialização do container e verifica se a aplicação conseguiu subir completamente - é especialmente útil para aplicações com startup lento, pois as outras probes só começam após a StartupProbe ter sucesso. A **ReadinessProbe** verifica continuamente se o container está pronto para aceitar tráfego - se falhar, o Kubernetes remove o Pod dos endpoints do Service temporariamente, mas não reinicia o container, permitindo que ele se recupere (útil para sobrecarga temporária ou dependências indisponíveis). A **LivenessProbe** verifica se o container ainda está funcionando corretamente - se falhar, o Kubernetes mata e reinicia o container, sendo usada para detectar deadlocks ou estados irrecuperáveis onde a aplicação está travada mas o processo ainda está rodando.

**Por que as outras opções estão incorretas:**

- **Opção 2** (StartupProbe para stateful, ReadinessProbe para stateless, LivenessProbe para ambos): As três probes podem ser usadas em qualquer tipo de aplicação - não há essa separação de uso baseada em estado.
- **Opção 3** (Todas fazem a mesma verificação, apenas em momentos diferentes): Embora sejam executadas em momentos diferentes, cada probe tem um propósito específico diferente e resulta em ações distintas quando falha.
- **Opção 4** (StartupProbe verifica recursos, ReadinessProbe verifica rede, LivenessProbe verifica disco): As probes não verificam aspectos específicos de infraestrutura - elas executam verificações definidas pelo usuário para determinar o estado da aplicação.
- **Opção 5** (StartupProbe é obrigatória, ReadinessProbe é opcional, LivenessProbe é deprecated): Todas as três probes são opcionais, e nenhuma delas está deprecated - são recursos ativos e recomendados.

---

## Questão 13/22

**Pergunta:** Qual é a menor unidade de execução no Kubernetes?

**Resposta Correta:** ✅ Opção 5 - "Pod"

**Explicação:**

O **Pod** é a menor e mais básica unidade de execução no Kubernetes. Um Pod encapsula um ou mais containers que compartilham o mesmo contexto de execução, incluindo namespace de rede (mesmo endereço IP), volumes de armazenamento, e configurações. Embora um Pod possa conter múltiplos containers, ele é tratado como uma única unidade atômica - todos os containers dentro do Pod são sempre agendados juntos no mesmo node, iniciados e terminados em conjunto. O Pod é efêmero por natureza, podendo ser destruído e recriado a qualquer momento pelo Kubernetes. Containers individuais não podem ser gerenciados diretamente pelo Kubernetes - eles devem sempre estar dentro de um Pod. É por isso que dizemos que o Pod, não o container, é a menor unidade de execução gerenciável pela plataforma.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Container): Embora containers sejam executados dentro de Pods, eles não são diretamente gerenciáveis pelo Kubernetes como unidade independente. Containers devem sempre existir dentro de um Pod.
- **Opção 2** (Node): Node é a máquina física ou virtual onde os Pods são executados - é infraestrutura, não uma unidade de execução. Nodes hospedam múltiplos Pods.
- **Opção 3** (Deployment): Deployment é um controller de nível superior que gerencia ReplicaSets e Pods, não é uma unidade de execução. É uma abstração de gerenciamento.
- **Opção 4** (Service): Service é um recurso de rede que expõe Pods e fornece service discovery, não é uma unidade de execução.

---

## Questão 14/22

**Pergunta:** Qual componente é necessário instalar no cluster para que o HPA funcione corretamente?

**Resposta Correta:** ✅ Opção 3 - "Metrics Server"

**Explicação:**

O **Metrics Server** é o componente essencial que deve estar instalado no cluster para que o HPA (Horizontal Pod Autoscaler) funcione corretamente. O Metrics Server é um agregador de métricas de recursos do cluster que coleta dados de uso de CPU e memória de cada node e pod através da Kubelet API. Ele expõe essas métricas através da Metrics API do Kubernetes, permitindo que o HPA tome decisões de escalonamento baseadas no consumo real de recursos. Sem o Metrics Server, o HPA não consegue obter as métricas necessárias para calcular se deve aumentar ou reduzir o número de réplicas. O Metrics Server é um componente cluster-wide que deve ser instalado separadamente (não vem por padrão em muitas distribuições) e é fundamental não apenas para HPA, mas também para comandos como `kubectl top pods` e `kubectl top nodes`.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Secret Manager): Secret Manager não tem relação com HPA. Secrets são usados para armazenar dados sensíveis, não para fornecer métricas de escalonamento.
- **Opção 2** (Ingress Controller): Ingress Controller gerencia tráfego HTTP/HTTPS externo para services no cluster, não fornece métricas para o HPA.
- **Opção 4** (Load Balancer): Load Balancer é um tipo de Service que expõe aplicações externamente, não está relacionado com coleta de métricas ou funcionamento do HPA.
- **Opção 5** (Config Map Controller): ConfigMaps são recursos para armazenar configurações não sensíveis. Não existe um "Config Map Controller" responsável por métricas ou HPA.

---

## Questão 15/22

**Pergunta:** Qual componente roda em cada nó worker e é responsável pela comunicação com o Control Plane?

**Resposta Correta:** ✅ Opção 5 - "kubelet"

**Explicação:**

O **kubelet** é o agente primário que executa em cada nó worker do cluster Kubernetes e é responsável pela comunicação direta com o Control Plane (especificamente com o kube-apiserver). O kubelet garante que os containers descritos nos PodSpecs estejam executando e saudáveis no seu node. Ele continuamente monitora o estado dos Pods atribuídos ao seu node, reporta o status de volta ao Control Plane, executa health checks (liveness, readiness, startup probes), gerencia volumes, coleta métricas de recursos e interage com o container runtime através da CRI (Container Runtime Interface) para criar, iniciar, parar e remover containers. O kubelet é o único componente do worker node que se comunica ativamente com o API Server, recebendo instruções sobre quais Pods devem executar e reportando o estado atual constantemente.

**Por que as outras opções estão incorretas:**

- **Opção 1** (etcd): O etcd é o banco de dados distribuído que roda apenas no Control Plane, armazenando todo o estado do cluster. Não executa em worker nodes.
- **Opção 2** (kube-scheduler): O kube-scheduler é um componente do Control Plane responsável por decidir em qual node cada Pod deve ser agendado. Não executa em worker nodes.
- **Opção 3** (kube-proxy): Embora o kube-proxy execute em cada worker node, sua função é gerenciar regras de rede e iptables para services, não comunicar-se com o Control Plane sobre Pods.
- **Opção 4** (container-runtime): O container runtime (containerd, CRI-O, Docker) é responsável por executar os containers, mas não se comunica diretamente com o Control Plane. Ele recebe instruções do kubelet.

---

## Questão 16/22

**Pergunta:** Qual é a diferença entre "requests" e "limits" na configuração de recursos de um container?

**Resposta Correta:** ✅ Opção 1 - "Requests é o valor alocado para o container, limits é o máximo que ele pode usar"

**Explicação:**

A diferença entre **requests** e **limits** está relacionada à alocação e restrição de recursos computacionais. O **requests** define a quantidade mínima de recursos (CPU e memória) que o Kubernetes **garante** que o container terá disponível - é usado pelo scheduler para decidir em qual node o Pod será alocado, garantindo que o node tenha recursos suficientes disponíveis. Já o **limits** define o **teto máximo** de recursos que o container pode consumir - se o container tentar usar mais CPU do que o limit, ele será throttled (limitado), e se tentar usar mais memória do que o limit, será terminado (OOMKilled). Um container pode usar mais recursos do que seu request (se disponível no node), mas nunca pode ultrapassar seu limit. Essa distinção permite overcommitment controlado de recursos no cluster, onde a soma dos requests deve caber nos nodes, mas os limits podem ser maiores.

**Por que as outras opções estão incorretas:**

- **Opção 2** (Requests para CPU, limits para memória): Ambos requests e limits podem ser configurados tanto para CPU quanto para memória independentemente. Não há essa separação de recurso por tipo de configuração.
- **Opção 3** (Não há diferença, são configurações com o mesmo fim): Há diferença fundamental: requests afeta scheduling e garante recursos mínimos, enquanto limits estabelece tetos máximos.
- **Opção 4** (Requests é o máximo, limits é o mínimo garantido): Está completamente invertido. Requests é o mínimo garantido, limits é o máximo permitido.
- **Opção 5** (Requests é obrigatório, limits é opcional): Ambos são opcionais na especificação do container. No entanto, é considerada melhor prática definir ambos.

---

## Questão 17/22

**Pergunta:** O que é o kubectl?

**Resposta Correta:** ✅ Opção 3 - "Uma ferramenta de linha de comando para interagir com clusters Kubernetes"

**Explicação:**

O **kubectl** (pronuncia-se "kube-control" ou "kube-cuttle") é a ferramenta de linha de comando (CLI) oficial do Kubernetes que permite aos usuários interagir com clusters Kubernetes através do API Server. Com o kubectl, você pode criar, inspecionar, atualizar e deletar recursos do Kubernetes (Pods, Deployments, Services, etc.), executar comandos dentro de containers, visualizar logs, fazer port-forwarding, aplicar configurações através de arquivos YAML/JSON, escalar aplicações, fazer debug de problemas e muito mais. O kubectl se comunica com o kube-apiserver do Control Plane usando credenciais configuradas no arquivo kubeconfig (normalmente em ~/.kube/config), que especifica qual cluster acessar, qual usuário usar e contextos de autenticação. É a principal interface de administração e operação de clusters Kubernetes.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Um componente do Control Plane): kubectl não é um componente do cluster - é uma ferramenta cliente externa que se conecta ao cluster.
- **Opção 2** (Uma interface web para API do Kubernetes): kubectl é uma ferramenta de linha de comando (CLI), não uma interface web. A interface web oficial é o Kubernetes Dashboard.
- **Opção 4** (Um sistema de monitoramento e alertas): kubectl não é uma ferramenta de monitoramento. Sistemas de monitoramento incluem Prometheus, Grafana, ou soluções de observabilidade.
- **Opção 5** (Um tipo de container especial para gerenciamento): kubectl não é um container - é um binário executável que roda na máquina do usuário.

---

## Questão 18/22

**Pergunta:** Como um Service do Kubernetes identifica quais Pods deve incluir em seus endpoints?

**Resposta Correta:** ✅ Opção 1 - "Através de labels e seletores"

**Explicação:**

Um Service do Kubernetes identifica quais Pods devem receber tráfego através do mecanismo de **labels e seletores (selectors)**. Quando você cria um Service, você define um selector que especifica um conjunto de labels (pares chave-valor) que os Pods devem possuir para serem incluídos nos endpoints daquele Service. O Kubernetes continuamente monitora todos os Pods no namespace e automaticamente adiciona aos endpoints do Service aqueles que possuem labels correspondentes ao selector, e remove aqueles que não correspondem mais ou que foram terminados. Por exemplo, se um Service tem selector `app: frontend, version: v1`, apenas Pods com ambas essas labels serão incluídos. Esse mecanismo de descoberta dinâmica permite que Pods sejam criados, destruídos e escalados automaticamente enquanto o Service mantém sempre os endpoints atualizados.

**Por que as outras opções estão incorretas:**

- **Opção 2** (Através do IP do Pod): IPs de Pods são efêmeros e mudam constantemente quando Pods são recriados. Services não usam IPs diretamente para identificar Pods.
- **Opção 3** (Através do namespace onde está o Pod): Embora Services e Pods devam estar no mesmo namespace (por padrão), o namespace sozinho não é suficiente para identificação.
- **Opção 4** (Através do nome do Deployment que criou o Pod): Services não têm conhecimento de Deployments ou outros controllers - eles trabalham diretamente com labels dos Pods.
- **Opção 5** (Através do nome do Pod): Nomes de Pods são únicos mas efêmeros, especialmente em ReplicaSets onde cada réplica tem um nome diferente gerado automaticamente.

---

## Questão 19/22

**Pergunta:** Qual componente do Control Plane é responsável por agendar e alocar pods nos nós do cluster?

**Resposta Correta:** ✅ Opção 2 - "kube-scheduler"

**Explicação:**

O **kube-scheduler** é o componente do Control Plane responsável exclusivamente por agendar (schedule) Pods nos nodes do cluster. Quando um novo Pod é criado e ainda não foi atribuído a nenhum node (estado Pending), o kube-scheduler observa esses Pods através do API Server e toma a decisão de em qual node cada Pod deve ser executado. Ele analisa diversos fatores para essa decisão: recursos disponíveis nos nodes (CPU, memória), requisitos de recursos do Pod (requests e limits), restrições de afinidade e anti-afinidade, node selectors, taints e tolerations, prioridades de Pods, distribuição de carga, e políticas de agendamento personalizadas. Após selecionar o node mais adequado, o kube-scheduler atualiza o objeto Pod no etcd através do API Server com a informação de binding do node.

**Por que as outras opções estão incorretas:**

- **Opção 1** (cloud-controller-manager): O cloud-controller-manager gerencia integrações com provedores de nuvem (AWS, GCP, Azure), como criar load balancers e gerenciar volumes, não agenda Pods.
- **Opção 3** (etcd): O etcd é o banco de dados distribuído que armazena todo o estado do cluster de forma persistente, mas não toma decisões de scheduling.
- **Opção 4** (kube-apiserver): O kube-apiserver é o front-end da API do Kubernetes que valida e processa requisições, mas não toma decisões de scheduling.
- **Opção 5** (kube-controller-manager): O kube-controller-manager executa diversos controllers que garantem o estado desejado do cluster, mas não é responsável por scheduling inicial de Pods.

---

## Questão 20/22

**Pergunta:** O que é o Control Plane no Kubernetes?

**Resposta Correta:** ✅ Opção 3 - "O cérebro do cluster que gerencia e garante o estado desejado"

**Explicação:**

O **Control Plane** é o conjunto de componentes que formam o "cérebro" do cluster Kubernetes, responsável por tomar decisões globais sobre o cluster e detectar e responder a eventos para garantir que o estado atual corresponda ao estado desejado. O Control Plane é composto por componentes críticos: o **kube-apiserver** (ponto de entrada de todas as operações), o **etcd** (armazena todo o estado do cluster), o **kube-scheduler** (decide onde executar Pods), o **kube-controller-manager** (executa loops de controle para manter o estado desejado) e, em ambientes cloud, o **cloud-controller-manager** (integração com provedores). Esses componentes trabalham juntos para receber declarações de estado desejado (através de manifestos YAML), compará-las com o estado atual, e continuamente reconciliar qualquer diferença, orquestrando ações nos worker nodes.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Uma interface de rede): O Control Plane não é uma interface de rede. Embora componentes do Control Plane se comuniquem via rede, seu papel é gerencial e de coordenação.
- **Opção 2** (Um sistema de backup): O Control Plane não é um sistema de backup. Embora o etcd armazene dados que devem ser protegidos com backup, essa não é a função principal.
- **Opção 4** (Uma ferramenta de monitoramento, logs e alertas): O Control Plane não é uma ferramenta de observabilidade. Ferramentas de monitoramento são componentes separados.
- **Opção 5** (Um tipo especial de container que gerencia variáveis do cluster): O Control Plane não é "um container" e não gerencia apenas variáveis - gerencia todo o estado e orquestração do cluster.

---

## Questão 21/22

**Pergunta:** Qual é a boa prática recomendada para criar recursos no Kubernetes?

**Resposta Correta:** ✅ Opção 3 - "Usar manifestos declarativos em YAML"

**Explicação:**

A melhor prática recomendada para criar e gerenciar recursos no Kubernetes é usar **manifestos declarativos em YAML** (ou JSON). A abordagem declarativa define o "estado desejado" dos recursos em arquivos versionáveis, que podem ser armazenados em sistemas de controle de versão como Git, permitindo Infrastructure as Code (IaC), rastreabilidade de mudanças, code review, rollback facilitado e documentação viva da infraestrutura. Ao aplicar manifestos com `kubectl apply -f`, o Kubernetes compara o estado atual com o estado desejado e faz apenas as alterações necessárias de forma idempotente. Essa abordagem é superior aos comandos imperativos porque permite reprodutibilidade, facilita colaboração em equipe, suporta GitOps workflows, permite automação através de CI/CD, e fornece um registro claro e auditável de todas as configurações do cluster.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Usar sempre comandos imperativos): Comandos imperativos (`kubectl create`, `kubectl run`) são úteis para testes rápidos, mas não são recomendados para produção pois não permitem versionamento.
- **Opção 2** (Usar apenas a API REST diretamente): Embora seja possível interagir diretamente com a API REST, essa abordagem é mais complexa, propensa a erros e difícil de manter.
- **Opção 4** (Usar a interface web do cluster): Interfaces web (Kubernetes Dashboard) são úteis para visualização e operações pontuais, mas não são recomendadas para gerenciamento de recursos.
- **Opção 5** (Usar scripts em bash): Scripts bash com comandos kubectl imperativos herdam os mesmos problemas dos comandos imperativos - são procedurais, não declarativos.

---

## Questão 22/22

**Pergunta:** Qual é a principal diferença entre escala horizontal e escala vertical no Kubernetes?

**Resposta Correta:** ✅ Opção 4 - "Escala horizontal aumenta o número de réplicas, escala vertical aumenta os recursos computacionais de cada pod"

**Explicação:**

A diferença fundamental entre escala horizontal e vertical está na estratégia de aumento de capacidade. **Escala horizontal (Horizontal Scaling)** aumenta a capacidade adicionando mais réplicas (cópias) de Pods - por exemplo, aumentar de 3 para 10 réplicas de uma aplicação, distribuindo a carga entre mais instâncias. É gerenciada automaticamente pelo HPA (Horizontal Pod Autoscaler) baseado em métricas como CPU, memória ou métricas customizadas. Já a **escala vertical (Vertical Scaling)** aumenta os recursos computacionais (CPU e memória) de cada Pod individual - por exemplo, aumentar o limite de CPU de 500m para 2000m ou memória de 512Mi para 2Gi. É gerenciada pelo VPA (Vertical Pod Autoscaler) ou manualmente. Escala horizontal é preferida em arquiteturas cloud-native por oferecer melhor resiliência (múltiplas instâncias), enquanto escala vertical é útil quando a aplicação não pode ser facilmente paralelizada.

**Por que as outras opções estão incorretas:**

- **Opção 1** (Escala horizontal aumenta CPU, escala vertical aumenta memória): Ambos os tipos de escala podem afetar tanto CPU quanto memória, mas essa não é a distinção entre eles.
- **Opção 2** (Não há diferença prática entre os dois tipos de escala): Há diferença fundamental e prática significativa - uma adiciona mais instâncias (horizontal) e outra aumenta recursos de instâncias existentes (vertical).
- **Opção 3** (Escala horizontal apenas com Deployments, escala vertical com StatefulSets): Ambos os tipos de escala podem ser aplicados tanto a Deployments quanto a StatefulSets.
- **Opção 5** (Escala horizontal é automática, escala vertical é sempre manual): Ambas podem ser automáticas: HPA para escala horizontal e VPA (Vertical Pod Autoscaler) para escala vertical.

---

## Resumo das Respostas Corretas

| Questão | Resposta Correta |
| -------- | ------------------ |
| 2 | Opção 3 - stabilizationWindow estabelece tempo de espera antes de escalar |
| 3 | Opção 4 - ConfigMap para dados não sensíveis, Secret para dados sensíveis em base64 |
| 4 | Opção 1 - CRI, CNI e CSI |
| 5 | Opção 4 - Kind executa Kubernetes localmente usando containers Docker |
| 6 | Opção 4 - Recreate deleta todos os pods, Rolling Update substitui gradualmente |
| 7 | Opção 5 - Namespace default não permite identificar facilmente qual time/aplicação possui recursos |
| 8 | Opção 1 - Namespace provê separação lógica de recursos para organização |
| 9 | Opção 1 - Kubernetes resolve problemas de escala e orquestração de containers |
| 10 | Opção 4 - Pod é menor unidade sem controle, Deployment controla versão e réplicas |
| 11 | Opção 4 - Deployment → ReplicaSet → Pod |
| 12 | Opção 1 - StartupProbe verifica se subiu, ReadinessProbe se está pronto, LivenessProbe se está funcionando |
| 13 | Opção 5 - Pod |
| 14 | Opção 3 - Metrics Server |
| 15 | Opção 5 - kubelet |
| 16 | Opção 1 - Requests é o valor alocado, limits é o máximo que pode usar |
| 17 | Opção 3 - kubectl é ferramenta de linha de comando para interagir com clusters |
| 18 | Opção 1 - Service identifica Pods através de labels e seletores |
| 19 | Opção 2 - kube-scheduler |
| 20 | Opção 3 - Control Plane é o cérebro que gerencia e garante o estado desejado |
| 21 | Opção 3 - Usar manifestos declarativos em YAML |
| 22 | Opção 4 - Escala horizontal aumenta réplicas, escala vertical aumenta recursos por pod |
