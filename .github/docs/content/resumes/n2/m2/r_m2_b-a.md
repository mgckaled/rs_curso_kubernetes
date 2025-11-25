# Resumo Aulas Nível 2 Módulo 2: Bloco A - StatefulSet e DaemonSet

## 1. Conhecendo o Conceito de Aplicações com Estado

Nesta aula, exploramos conceitos avançados do Kubernetes, focando em StatefulSets e DaemonSets. Discutimos como gerenciar o estado de aplicações, destacando a importância de usar volumes persistentes. Abordamos a diferença entre Deployments e ReplicaSets, enfatizando que o Deployment controla versões, enquanto o ReplicaSet gerencia a quantidade de réplicas. Também falamos sobre a natureza stateless dos Pods e como evitar a perda de dados. Na próxima aula, vamos nos aprofundar no StatefulSet e suas aplicações práticas.

## 2. Explorando Algumas Problemáticas

Nesta aula, mergulhamos no conceito de Stateful Set, comparando-o com Deployments e Replica Sets. Abordamos a importância da identidade fixa dos pods no Stateful Set, que garante que, ao recriar um pod, ele mantenha o mesmo nome e volume, facilitando a segregação de dados, especialmente em bancos de dados. Discutimos também a ordem de criação e exclusão dos pods, essencial para aplicações que requerem consistência. No próximo encontro, aplicaremos esses conceitos na prática no EKS

## 3. Criando Nosso Primeiro StatefulSet

Hoje, vamos explorar o StatefulSet no Kubernetes, começando com um exemplo simples usando o Nginx antes de avançar para o Postgres. O StatefulSet é crucial para gerenciar aplicações que precisam de persistência e ordem, como bancos de dados. Vamos criar um StatefulSet e discutir a replicação entre pods. Também abordaremos a estrutura YAML necessária e como os pods são gerenciados de forma sequencial. Na próxima aula, vamos configurar volumes para persistência de dados.

## 4. Configurando os Volumes

Nessa aula, vamos montar a estrutura de Volume Mounts em um Stateful Set, semelhante ao que fizemos no Deployment. Abordamos a configuração do ponto de montagem, que se relaciona com o workdir do container. Discutimos a criação de Persistent Volume Claims (PVCs) e a importância de volumes persistentes. Enfrentamos alguns erros de indentação e configuração, além de problemas com o CNI, que vamos resolver na próxima aula. O foco é entender como gerenciar armazenamento em Kubernetes.

## 5. Configurando o CSI e Pod Identity

Na aula de hoje, exploramos a configuração de addons no EKS, enfrentando alguns desafios práticos. Abordamos a instalação do VPC CNI e do Amazon EKS Pod Identity Agent, essenciais para garantir a alocação de IPs e permissões no cluster. Também discutimos como resolver problemas de volumes persistentes e a importância do Amazon EBS CSI Driver. O objetivo foi entender as configurações de rede e armazenamento no Kubernetes, preparando o terreno para cenários mais complexos.

## 6. Primeiro Teste de Ponta a Ponta

Na aula de hoje, exploramos a instalação do KubeProxy como um addon para facilitar a descoberta de serviços no Kubernetes. Discutimos a criação de volumes persistentes e como gerenciar StatefulSets, lidando com erros comuns e a alocação de recursos. Realizamos testes práticos para verificar a funcionalidade dos pods e discutimos a importância de entender a persistência de dados em ambientes de produção. Também deixei um exercício para que você experimente com deployments, ampliando seu conhecimento.

## 7. Explorando Cenário Sem Volume

Na aula de hoje, exploramos a criação e a deleção de um StatefulSet no Kubernetes, destacando a importância dos volumes. Demonstrei como deletar e recriar o StatefulSet sem volumes, evidenciando que isso resulta em dados efêmeros. Também discutimos a relação entre StatefulSets e volumes persistentes, crucial para garantir a integridade dos dados. Por fim, introduzi a próxima etapa: configurar o Postgres, abordando desde a instalação até a replicação.

## 8. Iniciando Configuração do PostgreSQL

Na aula de hoje, vamos criar um StatefulSet para o Postgres, aproveitando a configuração que já fizemos anteriormente. A ideia é integrar um banco de dados simples à nossa aplicação, permitindo a comunicação dentro do cluster. Vamos definir o YAML do StatefulSet, incluindo as especificações de containers e volumes. Também discutimos a importância de gerenciar imagens de forma segura. No final, encontramos alguns desafios ao alocar recursos, que abordaremos na próxima aula.

## 9. Criando um Serviço Headless

Na aula de hoje, exploramos como configurar um StatefulSet no Kubernetes para o PostgreSQL, focando na definição do PGData e na criação de um serviço headless. Discutimos a importância de não usar um serviço Cluster IP para StatefulSets, pois isso impediria a segmentação adequada entre réplicas de leitura e escrita. Também abordamos a necessidade de popular o banco de dados e como gerenciar a replicação de dados entre os pods.

## 10. Interagindo Com O Nosso Banco De Dados

Hoje, fizemos alguns testes práticos com o nosso banco de dados Postgres usando o Lens e o Beekeeper Studio. Criamos um banco e uma tabela, mas encontramos alguns problemas de segurança e sincronização de dados entre os pods. Discutimos a importância de configurar variáveis de ambiente corretamente e como isso afeta o funcionamento do banco. Nas próximas aulas, vamos resolver esses problemas e explorar mais sobre StatefulSets e a conexão da aplicação com o banco.

## 11. Corrigindo Algumas Configurações

Nesta aula, exploramos a configuração do PostgreSQL em um ambiente Kubernetes usando StatefulSets. Discutimos a importância da persistência de dados, abordando problemas comuns, como a não replicação de volumes entre pods e a configuração inadequada do caminho de dados. Aprendemos a corrigir esses problemas, implementando variáveis de ambiente e subpaths. Além disso, falamos sobre a autenticação e a configuração de segurança do PostgreSQL. Na próxima aula, vamos aprofundar em conceitos teóricos e práticas de backup.

## 12. Conhecendo o Conceito de Operator

Na aula de hoje, exploramos a replicação de dados em bancos de dados utilizando Kubernetes, focando em StatefulSets e Operators. Discutimos a importância de ter volumes sincronizados e a necessidade de políticas de backup. Aprendemos que, embora StatefulSets não gerenciem a sincronização de volumes, os Operators podem facilitar essa tarefa. Também introduzimos os CRDs, que expandem as opções do Kubernetes. Na próxima aula, vamos nos aprofundar nos Operators e suas aplicações práticas.

## 13. Explorando Operadores de PostgreSQL

Nesta aula, vamos explorar como utilizar um operador no Postgres dentro do Kubernetes, facilitando a gestão de bancos de dados. Discutiremos a importância de operadores, que não são exclusivos do Postgres, e como eles podem simplificar o trabalho em ambientes Kubernetes. Abordaremos o Cloud Native Postgres (CNPG) como exemplo, além de mencionar outras opções populares. Também falaremos sobre a instalação de Custom Resource Definitions (CRDs) e como isso se integra ao Kubernetes.

## 14. Estruturando Nosso Primeiro YAML Com Operator

Na aula de hoje, vamos instalar o YAML da release do nosso projeto no cluster, seguindo as boas práticas recomendadas. Começamos baixando o arquivo e aplicando-o no Kubernetes. Abordamos a criação de um cluster PostgreSQL, utilizando CRDs para gerenciar recursos. Também falamos sobre a importância de usar Secrets para armazenar informações sensíveis, como senhas. Por fim, discutimos a configuração do cluster e a criação de um banco de dados, preparando o terreno para as próximas aulas.

## 15. Testando Nosso Cluster

Nesta aula, exploramos como configurar um banco de dados PostgreSQL usando o Kubernetes. Discutimos a criação de um cluster, a importância das secrets e como debugar problemas comuns, como quebras de linha em senhas. Também abordamos a diferença entre réplicas primárias e secundárias, destacando como as operações de escrita e leitura funcionam. Finalizamos com uma demonstração de como sincronizar dados entre as réplicas e a importância de backups.

## 16. Explorando o Conceito de Backup

Nesta aula, abordei como realizar backups agendados no PostgreSQL utilizando o Kubernetes. Expliquei que, embora a opção de declarar backups tenha sido descontinuada, é possível criar um objeto de "Scheduled Backup". Mostrei como definir a programação usando expressões Cron e a importância de configurar corretamente o Backup Owner Experience. Também mencionei os métodos disponíveis para armazenamento, como o Barman Object Store. Finalizei ressaltando a relevância do conhecimento sobre Operators e StatefulSets.

## 17. O que é e como funciona?

Nesta aula, abordamos o conceito de DaemonSet, uma ferramenta essencial para monitorar a saúde das aplicações em um cluster Kubernetes. Discutimos como ele atua como um agente, instalando um pod por nó para coletar métricas e logs, facilitando a observabilidade sem a necessidade de configurações manuais a cada nova aplicação. O DaemonSet é flexível e pode integrar-se a ferramentas como New Relic e Datadog, garantindo que todas as aplicações sejam monitoradas automaticamente.

## 18. Criando Nosso Primeiro DaemonSet

Nessa aula, exploramos o conceito de DaemonSet no Kubernetes, focando na sua configuração e funcionamento. Montamos um arquivo `daemonset.yaml`, onde definimos um NodeExporter do Prometheus para coletar métricas. Discutimos a estrutura do DaemonSet, que é diferente de um Deployment, pois não utiliza réplicas, operando uma instância por nó. Também abordamos o conceito de Taints, que impede a execução de pods no Control Plane. Na próxima aula, faremos mais configurações para acessar a interface do exporter.

## 19. Últimas Configurações e Encerramento

Na aula de hoje, finalizei a configuração do DaemonSet, abordando a adição de volumes e pontos de montagem para o Prometheus. Expliquei a importância dos sistemas de arquivos, como rootfs e procfs, para a coleta de métricas. Também demonstrei como configurar as portas e resolver problemas de reinício do container. Ao final, introduzi o tema de CI/CD, que exploraremos em aulas futuras, focando na automação de aplicações no EKS.
