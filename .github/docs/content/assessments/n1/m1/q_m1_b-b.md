<!-- markdownlint-disable -->

# Questionário Avaliativo - Módulo 1, Bloco B: Orquestrando Containers

## Questão 1: Criação de Namespace

**Pergunta:** Qual comando Kubernetes você usaria para criar um novo namespace chamado "primeiro-app"?

**Resposta Correta:** `kubectl create namespace primeiro-app` (Alternativa 1)

**Justificativa:** O comando `kubectl create namespace` é a forma direta e recomendada para criar um novo namespace no Kubernetes. Este comando cria imediatamente o recurso no cluster sem necessidade de arquivos de configuração adicionais. A sintaxe é simples e intuitiva, seguindo o padrão imperativo do kubectl onde você especifica a ação (create), o tipo de recurso (namespace) e o nome desejado (primeiro-app).

O namespace é um recurso fundamental no Kubernetes que permite a segmentação lógica de recursos dentro do cluster, facilitando a organização, o isolamento e a gestão de políticas de acesso entre diferentes aplicações ou ambientes.

**Alternativas Incorretas:**

- **Alternativa 2 (`kubectl new namespace primeiro-app`):** O kubectl não possui o subcomando "new". A sintaxe correta utiliza "create" para criação de recursos.

- **Alternativa 3 (`kubectl namespace create primeiro-app`):** A ordem dos argumentos está invertida. O padrão do kubectl é verbo-substantivo-nome, não substantivo-verbo-nome.

- **Alternativa 4 (`kubectl apply -f primeiro-app-namespace.yaml`):** Embora funcional, este comando requer a existência prévia de um arquivo YAML de configuração, tornando-o mais complexo que o necessário para uma simples criação de namespace.

- **Alternativa 5 (`kubectl create primeiro-app`):** Este comando está incompleto, pois não especifica o tipo de recurso a ser criado. O kubectl precisa saber que se trata de um namespace.

---

## Questão 2: Finalidade do Port-Forward

**Pergunta:** Ao utilizar o `kubectl port-forward`, qual é a finalidade de redirecionar a porta do seu localhost para uma porta do container?

**Resposta Correta:** Acessar a aplicação dentro do pod a partir do seu computador local (Alternativa 2)

**Justificativa:** O comando `kubectl port-forward` estabelece um túnel de comunicação entre uma porta no seu computador local e uma porta específica em um pod rodando no cluster Kubernetes. Esta funcionalidade é essencial para desenvolvimento e depuração, permitindo que desenvolvedores acessem diretamente aplicações em execução no cluster sem necessidade de expor o serviço publicamente ou configurar recursos adicionais como LoadBalancers ou Ingress.

Esta abordagem é particularmente útil em ambientes de desenvolvimento onde você precisa testar uma aplicação rapidamente, inspecionar logs em tempo real ou depurar problemas específicos de conectividade. O port-forward cria uma conexão direta e temporária, ideal para tarefas de diagnóstico e desenvolvimento local.

**Alternativas Incorretas:**

- **Alternativa 1 (Garantir que o container esteja rodando em múltiplas portas):** O port-forward não altera a configuração do container nem cria múltiplas portas. Ele apenas redireciona o tráfego de uma porta local para uma porta existente no pod.

- **Alternativa 3 (Monitorar o tráfego de rede entre o pod e o cluster):** Embora você possa observar comunicações através do túnel criado, essa não é a finalidade principal. Para monitoramento de tráfego existem ferramentas específicas como service mesh ou network policies.

- **Alternativa 4 (Atualizar a configuração do pod em tempo real):** O port-forward não modifica configurações do pod. Para alterações de configuração são necessários comandos como `kubectl edit` ou `kubectl apply`.

- **Alternativa 5 (Aumentar a quantidade de memória disponível para o pod):** O port-forward é exclusivamente uma ferramenta de redirecionamento de rede e não tem qualquer impacto nos recursos computacionais alocados ao pod.

---

## Questão 3: Limites de Recursos em Containers

**Pergunta:** Por que é importante definir limites e requisições de recursos (CPU e memória) para um container em um pod?

**Resposta Correta:** Para garantir que o pod não consuma mais recursos do que o necessário (Alternativa 1)

**Justificativa:** A definição de resource requests e limits é uma prática fundamental para garantir a estabilidade e eficiência do cluster Kubernetes. Os requests especificam a quantidade mínima de recursos que o pod necessita para funcionar, enquanto os limits estabelecem o teto máximo de consumo permitido. Esta configuração previne que um único pod monopolize os recursos do nó, evitando situações de resource starvation que poderiam afetar outras aplicações no cluster.

Além disso, o Kubernetes scheduler utiliza as informações de resource requests para tomar decisões inteligentes sobre onde posicionar os pods no cluster, garantindo distribuição equilibrada de carga. Quando um pod tenta exceder seus limits, o Kubernetes pode tomar ações corretivas, como throttling de CPU ou terminação do container (OOMKilled) no caso de memória, protegendo assim a integridade do sistema como um todo.

**Alternativas Incorretas:**

- **Alternativa 2 (Para permitir que o pod seja acessado externamente):** O acesso externo é controlado por Services, Ingress e Network Policies, não por configurações de recursos computacionais.

- **Alternativa 3 (Para configurar a rede entre diferentes namespaces):** A comunicação entre namespaces é gerenciada por Network Policies e configurações de DNS, não por limites de recursos.

- **Alternativa 4 (Para garantir que o pod esteja sempre em execução, mesmo se o node falhar):** A alta disponibilidade é garantida por mecanismos como ReplicaSets, Deployments e estratégias de distribuição de pods entre nodes, não por resource limits.

- **Alternativa 5 (Para melhorar a segurança do pod contra ataques externos):** A segurança é tratada por SecurityContexts, PodSecurityPolicies, Network Policies e RBAC, não por configurações de recursos computacionais.

---

## Questão 4: Diferença entre Pod e Deployment

**Pergunta:** Qual é a principal diferença entre um pod e um deployment em Kubernetes?

**Resposta Correta:** O pod é um recurso efêmero que pode ser gerenciado diretamente, enquanto o deployment é um controlador que mantém o número desejado de réplicas de pods (Alternativa 1)

**Justificativa:** Esta distinção é fundamental para compreender a arquitetura do Kubernetes. Um pod é a menor unidade de deployment no Kubernetes, representando um ou mais containers que compartilham recursos e são executados juntos no mesmo host. No entanto, pods são considerados efêmeros e voláteis, podendo ser destruídos e recriados a qualquer momento devido a falhas, atualizações ou reescalonamento.

O Deployment, por outro lado, é um recurso de nível superior que atua como um controlador declarativo. Ele gerencia ReplicaSets, que por sua vez garantem que o número especificado de réplicas de pods esteja sempre em execução. Deployments oferecem funcionalidades avançadas como rolling updates, rollbacks, estratégias de deployment e self-healing automático. Quando você define um Deployment, está declarando o estado desejado da aplicação, e o Kubernetes trabalha continuamente para manter esse estado, recriando pods automaticamente quando necessário.

**Alternativas Incorretas:**

- **Alternativa 2 (O pod gerencia a criação de containers, enquanto o deployment controla o tráfego de rede):** Pods não "gerenciam" a criação de containers, eles simplesmente os executam. O controle de tráfego é responsabilidade dos Services, não dos Deployments.

- **Alternativa 3 (O pod fornece balanceamento de carga, enquanto o deployment fornece armazenamento persistente):** Balanceamento de carga é fornecido por Services, e armazenamento persistente é gerenciado por PersistentVolumes e PersistentVolumeClaims, não por pods ou deployments.

- **Alternativa 4 (O pod é utilizado para configurar redes, enquanto o deployment define políticas de segurança):** Configuração de rede é feita através de Services e Network Policies. Políticas de segurança são definidas por SecurityContexts e PodSecurityPolicies.

- **Alternativa 5 (O pod é usado para criar volumes, enquanto o deployment faz a integração com serviços externos):** Volumes são definidos na especificação do pod, mas não são "criados" por ele. Integração com serviços externos é uma responsabilidade da aplicação, não do Deployment.

---

## Questão 5: ReplicaSet para Gerenciamento de Pods

**Pergunta:** Qual dos componentes a seguir é utilizado para garantir que um conjunto de Pods permaneça sempre em um estado desejado, gerenciando a criação e substituição de Pods conforme necessário?

**Resposta Correta:** ReplicaSet (Alternativa 2)

**Justificativa:** O ReplicaSet é o controlador fundamental do Kubernetes responsável por garantir que um número específico de réplicas de pods esteja sempre em execução no cluster. Ele implementa o conceito de reconciliation loop, monitorando continuamente o estado atual dos pods e comparando-o com o estado desejado definido na especificação. Quando detecta divergências, como pods que falharam ou foram deletados, o ReplicaSet toma ações corretivas automáticas para restaurar o estado desejado.

O ReplicaSet utiliza label selectors para identificar quais pods ele deve gerenciar, proporcionando flexibilidade e permitindo atualizações declarativas. Embora seja possível criar ReplicaSets diretamente, na prática moderna do Kubernetes é recomendado utilizar Deployments, que gerenciam ReplicaSets automaticamente e oferecem funcionalidades adicionais como rolling updates e histórico de versões.

**Alternativas Incorretas:**

- **Alternativa 1 (Pod):** Pods são recursos individuais e não possuem capacidade de auto-gerenciamento ou replicação. Eles dependem de controladores de nível superior para gerenciamento de ciclo de vida.

- **Alternativa 3 (Deployment):** Embora Deployments garantam o estado desejado, eles fazem isso através do gerenciamento de ReplicaSets, não diretamente. O Deployment é uma camada de abstração acima do ReplicaSet.

- **Alternativa 4 (Service):** Services são responsáveis por expor pods e fornecer descoberta de serviços e load balancing, não por gerenciar o ciclo de vida ou replicação de pods.

- **Alternativa 5 (ConfigMap):** ConfigMaps são utilizados para armazenar dados de configuração não confidenciais em pares chave-valor, não tendo qualquer função de gerenciamento de pods.

---

## Questão 6: Tipo de Service ClusterIP

**Pergunta:** Ao configurar um Service no Kubernetes, qual tipo é usado para expor um serviço somente dentro do próprio cluster, atribuindo um IP interno?

**Resposta Correta:** ClusterIP (Alternativa 4)

**Justificativa:** O tipo ClusterIP é o tipo padrão de Service no Kubernetes e representa a forma mais básica e segura de expor aplicações. Quando você cria um Service do tipo ClusterIP, o Kubernetes atribui um endereço IP virtual interno do cluster que atua como um endpoint estável para acessar os pods subjacentes. Este IP é acessível apenas de dentro do cluster, tornando-o ideal para comunicação entre microsserviços internos.

O ClusterIP fornece balanceamento de carga automático entre os pods que correspondem ao selector do Service, distribuindo requisições de forma round-robin por padrão. Esta abordagem é fundamental para arquiteturas de microsserviços onde diferentes componentes precisam se comunicar de forma confiável sem exposição externa, mantendo uma camada adicional de segurança ao não permitir acesso direto da internet.

**Alternativas Incorretas:**

- **Alternativa 1 (NodePort):** NodePort expõe o serviço em uma porta estática em cada nó do cluster, permitindo acesso externo através de `<NodeIP>:<NodePort>`. É usado quando há necessidade de acesso externo sem load balancer.

- **Alternativa 2 (LoadBalancer):** LoadBalancer provisiona um load balancer externo (geralmente fornecido pelo provedor de cloud) e expõe o serviço publicamente na internet, não apenas internamente.

- **Alternativa 3 (ExternalName):** ExternalName mapeia um Service para um nome DNS externo, funcionando como um alias CNAME. Não atribui um ClusterIP e não realiza proxying de conexões.

- **Alternativa 5 (HostNetwork):** HostNetwork não é um tipo de Service, mas sim uma configuração ao nível de pod que faz com que o pod utilize diretamente a rede do host ao invés da rede overlay do Kubernetes.

---

## Questão 7: Gerenciamento Declarativo de Recursos

**Pergunta:** No Kubernetes, qual comando deve ser utilizado para criar ou atualizar recursos com base em um arquivo de configuração?

**Resposta Correta:** `kubectl apply -f` (Alternativa 4)

**Justificativa:** O comando `kubectl apply -f` representa a abordagem declarativa para gerenciamento de recursos no Kubernetes, que é considerada a melhor prática para ambientes de produção. Quando você utiliza apply, o Kubernetes compara o estado desejado especificado no arquivo de configuração com o estado atual do recurso no cluster e realiza apenas as alterações necessárias para reconciliar os dois estados. Esta abordagem é idempotente, significando que você pode executar o comando múltiplas vezes com o mesmo arquivo sem causar efeitos colaterais indesejados.

O apply mantém anotações especiais nos recursos que registram a última configuração aplicada, permitindo que o Kubernetes realize merges inteligentes entre mudanças concorrentes e facilitando operações de rollback. Este comando funciona tanto para criar novos recursos quanto para atualizar recursos existentes, tornando-o extremamente versátil para práticas de GitOps e infraestrutura como código.

**Alternativas Incorretas:**

- **Alternativa 1 (`kubectl exec -f`):** O comando exec é utilizado para executar comandos dentro de containers em execução, não para gerenciar recursos do Kubernetes.

- **Alternativa 2 (`kubectl run -f`):** O comando run é usado para criar pods rapidamente de forma imperativa, não para aplicar arquivos de configuração declarativos.

- **Alternativa 3 (`kubectl expose -f`):** O comando expose é utilizado para criar Services que expõem recursos existentes como pods ou deployments, não para gerenciamento geral de recursos via arquivos.

- **Alternativa 5 (`kubectl deploy -f`):** Não existe o comando "deploy" no kubectl. O gerenciamento de deployments é feito através de apply, create ou outros comandos padrão.

---

## Questão 8: Função do Selector em Services

**Pergunta:** Qual a função do selector em um Service do Kubernetes?

**Resposta Correta:** Associar o Service aos Pods correspondentes com base nas labels (Alternativa 2)

**Justificativa:** O selector é um componente crítico na arquitetura de Services do Kubernetes, estabelecendo a conexão entre o Service e os pods que ele deve rotear tráfego. Os selectors funcionam através de um mecanismo de label matching, onde o Service identifica automaticamente todos os pods que possuem labels correspondentes aos critérios especificados no selector. Esta abordagem baseada em labels proporciona um acoplamento fraco e dinâmico entre recursos.

Quando novos pods são criados com labels que correspondem ao selector do Service, eles são automaticamente adicionados ao pool de endpoints do Service. Da mesma forma, quando pods são removidos ou suas labels mudam, eles são automaticamente removidos. Este comportamento dinâmico permite que Deployments e ReplicaSets gerenciem pods sem necessidade de reconfigurações manuais nos Services, facilitando operações como rolling updates e scaling horizontal.

**Alternativas Incorretas:**

- **Alternativa 1 (Definir a porta do serviço a ser exposta):** A definição de portas é feita através dos campos `port`, `targetPort` e `protocol` na especificação do Service, não pelo selector.

- **Alternativa 3 (Configurar o tipo de serviço - ClusterIP, NodePort, LoadBalancer):** O tipo de serviço é definido pelo campo `type` na especificação do Service, independentemente do selector.

- **Alternativa 4 (Definir o nome do serviço a ser exposto):** O nome do Service é definido no campo `metadata.name` da especificação, não tendo relação com o selector.

- **Alternativa 5 (Especificar a versão da API a ser utilizada):** A versão da API é especificada no campo `apiVersion` no manifesto YAML e não tem qualquer relação com a funcionalidade do selector.

---

## Questão 9: Escalamento de Deployments

**Pergunta:** Durante o processo de escalonamento de um Deployment no Kubernetes, qual é o método recomendado para aumentar ou diminuir o número de réplicas?

**Resposta Correta:** Alterar o número de réplicas no arquivo de configuração declarativo e aplicar a mudança (Alternativa 3)

**Justificativa:** A abordagem declarativa de alterar o número de réplicas no arquivo de configuração e aplicar as mudanças através de `kubectl apply` representa a melhor prática para gerenciamento de infraestrutura Kubernetes em ambientes profissionais. Este método assegura que toda a configuração do cluster esteja versionada em arquivos que podem ser mantidos em sistemas de controle de versão como Git, proporcionando rastreabilidade completa de mudanças, facilitando auditorias e permitindo rollbacks seguros quando necessário.

Ao utilizar esta abordagem, você estabelece um único ponto de verdade para a configuração do seu sistema, essencial para práticas de GitOps e infraestrutura como código. Além disso, este método permite que equipes revisem mudanças através de pull requests antes de aplicá-las, implementando controles de qualidade e governança sobre modificações na infraestrutura.

**Alternativas Incorretas:**

- **Alternativa 1 (Usar comandos diretamente no terminal via `kubectl scale`):** Embora funcional e útil para testes rápidos, comandos imperativos não deixam registro das mudanças em arquivos de configuração, dificultando rastreabilidade e controle de versão.

- **Alternativa 2 (Editar o número de réplicas diretamente no painel de gerenciamento da interface):** Interfaces web podem ser úteis para visualização, mas mudanças através delas não ficam registradas em código, contradizendo princípios de infraestrutura como código.

- **Alternativa 4 (Configurar o autoscaler manualmente para ajustar as réplicas automaticamente):** Autoscaling (HPA) é uma funcionalidade complementar que ajusta réplicas baseado em métricas, mas não é o método recomendado para escalonamento manual controlado.

- **Alternativa 5 (Reiniciar o cluster Kubernetes para aplicar mudanças):** Reiniciar o cluster é desnecessário e extremamente disruptivo. Mudanças em Deployments são aplicadas dinamicamente sem necessidade de restart.

---

## Questão 10: Port-Forward para Acesso Local

**Pergunta:** Qual dos comandos abaixo é utilizado para redirecionar uma porta local para acessar um serviço exposto pelo Kubernetes, sem expor o serviço diretamente na internet?

**Resposta Correta:** `kubectl port-forward` (Alternativa 3)

**Justificativa:** O comando `kubectl port-forward` é a ferramenta ideal para estabelecer túneis seguros entre sua máquina local e recursos dentro do cluster Kubernetes sem necessidade de expor serviços publicamente. Esta funcionalidade é particularmente valiosa durante desenvolvimento, depuração e troubleshooting, permitindo que desenvolvedores acessem diretamente pods, services ou deployments como se estivessem rodando localmente. O comando estabelece uma conexão proxy através do API server do Kubernetes, garantindo que todo o tráfego seja autenticado e autorizado.

A sintaxe típica é `kubectl port-forward <recurso>/<nome> <porta-local>:<porta-remota>`, criando uma ponte temporária que existe apenas enquanto o comando está ativo. Esta abordagem evita a necessidade de configurar LoadBalancers externos, Ingress controllers ou modificar Network Policies apenas para acesso temporário, mantendo a segurança do cluster intacta.

**Alternativas Incorretas:**

- **Alternativa 1 (`kubectl connect svc`):** Não existe o comando "connect" no kubectl. Esta sintaxe é inválida.

- **Alternativa 2 (`kubectl expose pod`):** O comando expose cria um Service para expor pods ou outros recursos, mas não estabelece redirecionamento de portas locais. Além disso, ele pode expor o serviço dentro do cluster ou externamente, dependendo do tipo.

- **Alternativa 4 (`kubectl tunnel svc`):** Não existe o comando "tunnel" no kubectl padrão. Embora alguns contextos (como Minikube) tenham `minikube tunnel`, este não é um comando kubectl.

- **Alternativa 5 (`kubectl proxy`):** O comando proxy cria um proxy para o API server do Kubernetes, permitindo acesso à API REST, mas não redireciona portas específicas de aplicações como o port-forward faz.