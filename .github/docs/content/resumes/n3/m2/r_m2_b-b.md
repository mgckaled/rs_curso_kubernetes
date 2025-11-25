# Resumo Aulas: Nível 3, Módulo 2, Bloco B - Instalçao do Karpenter e práticas

## 1. Instalando o Karpenter via Helm

Na aula de hoje, finalmente instalamos o Carpenter no nosso cluster usando o Helm. Expliquei como o Helm funciona como um empacotador que gerencia o ciclo de vida das aplicações. Fizemos a instalação do Carpenter, abordando a configuração de variáveis e a criação de um Service Account. Também discutimos a importância de máquinas on-demand e como o Carpenter pode gerenciar eventos de máquinas spot no futuro. Na próxima aula, vamos explorar a configuração de Node Pools e Node Classes.

## 2. Criando a NodeClass

Hoje, exploramos a integração do Carpenter com o Kubernetes, focando em como configurar NodeClasses e NodePools. Discutimos a importância de definir como e quais nós podem ser criados, usando a Amazon Linux 2023 como exemplo. Aprendemos a criar arquivos YAML para configurar esses recursos, além de entender as melhores práticas de segurança ao associar subnets e security groups. Também abordamos a relevância das labels e como elas influenciam a gestão dos nós no cluster.

## 3. Aplicando o NodePool e Realizando Primeiros Testes

Na aula de hoje, exploramos a configuração de um cluster usando o Carpenter para gerenciar a escalabilidade de nós na AWS. Abordamos a criação de um pool de nós com limites de CPU e memória, além de estratégias de downscale para otimizar custos. Demonstramos como escalar pods rapidamente e a importância de distribuir nós em diferentes zonas de disponibilidade. Também discutimos a necessidade de configurar aplicações para garantir resiliência em caso de falhas em uma zona.

## 4. Explorando Topology Spread e Afinidad

Na aula de hoje, exploramos como garantir uma distribuição uniforme de pods em diferentes zonas de disponibilidade usando o conceito de topology spread no Kubernetes. Discutimos a importância da alta disponibilidade e como configurar o topology spread e a afinidade de nós. Também abordamos como aplicar regras para evitar que pods sejam agendados em tipos de instância indesejados. Por fim, fizemos testes práticos para observar o comportamento do sistema e as configurações que implementamos.

## 5. Conhecendo o Conceito de Pod Anti-Affinity

Na aula de hoje, exploramos o conceito de Pod Anti Affinity, que permite garantir que pods não sejam escalonados no mesmo nó, promovendo uma distribuição mais eficiente. Discutimos como configurar as regras de afinidade e anti-afindade, e como isso impacta o agendamento dos pods. Também abordamos a importância de ajustar as configurações para evitar problemas de escalonamento, especialmente em cenários com múltiplos pods. Na próxima aula, vamos criar uma nova NodeClass e NodePool para aprofundar ainda mais esses conceitos.

## 6. Finalizando Testes e Próximos Passos

Na aula de hoje, exploramos a configuração do Carpenter no Nodepool, discutindo limitações de escalabilidade e a importância da distribuição uniforme de pods para garantir resiliência. Introduzimos o Bottle Rocket, uma imagem de máquina voltada para segurança. Também falamos sobre a criação de diferentes NodePools e a utilização de Node Affinity para aplicações específicas. Finalizamos com a criação de deployments, ressaltando a importância do balanceamento entre zonas de disponibilidade e o gerenciamento de custos com instâncias.
