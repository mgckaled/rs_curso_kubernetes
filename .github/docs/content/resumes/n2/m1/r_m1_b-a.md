# Resumo Aulas Nível 2 Módulo 1: Bloco A - Kubernetes Gerenciado

## 1. Conhecendo os Principais Provedores de Cloud

Neste vídeo, introduzimos o módulo avançado de Kubernetes, focando em provedores de cloud. Diferente do módulo básico, aqui trabalhamos com Kubernetes gerenciado, onde não temos acesso ao Control Plane, que é responsabilidade do provedor. Discutimos os principais provedores, como GCP, Azure e AWS, e mencionamos a DigitalOcean como uma opção acessível para pequenos projetos. Vamos explorar como escalar nós e usar ferramentas como Helm. Na próxima aula, falaremos sobre precificação.

## 2. Modelo de Precificação

Na aula de hoje, discutimos os principais provedores de cloud, como AWS, Azure e GCP, além da DigitalOcean, que é ótima para pequenas organizações. Abordamos a importância da precificação e como usar as calculadoras de preços de cada provedor para estimar custos. Falei sobre a diferença entre máquinas regulares e spot, e como isso impacta no custo. Na próxima aula, vamos colocar a mão na massa com a DigitalOcean e criar um cluster.

## 3. Criando Nosso Cluster na DigitalOcean

Nesta aula, vamos explorar a DigitalOcean e seu serviço de Kubernetes, o DOCS. O foco principal é a redução de custos, ideal para organizações menores que querem experimentar Kubernetes em um ambiente gerenciado. Discutimos a importância do SLA e do uptime, além de dicas sobre como aproveitar os créditos de US$ 200 para estudos. Vamos criar um cluster Kubernetes de forma simples e rápida, destacando a facilidade de uso da DigitalOcean em comparação com outros provedores.

## 4. Configurando o Apontamento Local

Na aula de hoje, finalizei a criação do nosso NodePool na DigitalOcean, onde temos dois nós como workers. Expliquei que esses nós são máquinas virtuais e como podemos usar o Auto Scale para aumentar recursos conforme necessário. Também mostrei como configurar o acesso ao cluster usando a CLI doc tl, incluindo a criação de um token de acesso. Finalmente, fizemos algumas interações com o Kubernetes e discutimos que na próxima aula vamos rodar uma aplicação no cluster.

## 5. Colocando Nossa Primeira Aplicação em Execução

Na aula de hoje, avançamos com a configuração do nosso cluster e conectamos a aplicação básica que criamos anteriormente. Focamos em rodar a aplicação, ajustando os manifestos do Kubernetes, como ConfigMap e Deployment. Discutimos sobre a importância da arquitetura do container, especialmente em Macs com chip M1, que pode causar incompatibilidades. Enfrentamos um erro comum relacionado à arquitetura e decidimos reconstruir o container na próxima aula.

## 6. Ajustando Build da Aplicação

Hoje, vamos corrigir um probleminha na nossa aplicação utilizando Docker. Começamos com um Dockerfile já configurado, mas precisamos focar no build. Vou mostrar como especificar a plataforma correta, já que alguns provedores de cloud, como a AWS, suportam ARM. Abordamos a questão do Yarn e como resolver erros comuns, além de fazer uma atualização na versão. No final, conseguimos subir a aplicação e verificar sua saúde no Kubernetes. Vamos também discutir como expor a aplicação na internet.

## 7. Expondo Aplicação na Internet

Nesta aula, vamos expor nossa aplicação em um cenário real, permitindo que ela receba tráfego da internet. Abordaremos a configuração do tipo de serviço no Kubernetes, focando no LoadBalancer. Vou demonstrar como alterar o tipo de serviço e aplicar as mudanças, além de verificar o status do LoadBalancer. Também falaremos sobre o custo associado e a possibilidade de usar o Marketplace da Digital Ocean para instalar stacks de monitoramento.

## 8. Debugando Métricas do Cluster

Na aula de hoje, finalizei a instalação do KubePrometheus no cluster e explorei as funcionalidades do Grafana e Prometheus. Mostrei como acessar os dashboards, monitorar métricas de CPU e memória, e configurar alertas. Também discuti a importância de gerenciar recursos e a prática de deletar clusters para evitar custos desnecessários. Por fim, preparei o terreno para nossa próxima etapa, que será a configuração do cluster na AWS, onde abordaremos tópicos avançados de Kubernetes.

## 9. Primeiras Configurações na Criação do Cluster EKS

Na aula de hoje, vamos oficializar o uso da AWS criando um cluster no EKS. Começaremos no console da AWS para entender as ferramentas antes de aplicar o conceito de Infrastructure as Code (IaC) com Terraform. Focaremos na região de Ohio e faremos uma configuração personalizada do cluster, abordando aspectos como roles do IAM e versões do Kubernetes. Também vamos criar uma VPC do zero, já que a AWS não fornece uma por padrão

## 10. Entendendo Mais Sobre VPC

Nesta aula, fizemos uma introdução à rede em um provedor de cloud, focando na VPC (Virtual Private Cloud) e suas subnets. A VPC é comparada a um prédio, enquanto as subnets são como andares. Discutimos a diferença entre subnets públicas e privadas, além da importância do Internet Gateway e do NAT Gateway para gerenciar o tráfego. Também abordamos a criação da VPC e a escolha do CIDR, enfatizando a necessidade de um bom planejamento de endereçamento IP. Na próxima aula, criaremos as subnets.

## 11. Criando Subnets

Nesta aula, vamos criar subnets, focando principalmente nas públicas, mas também abordando algumas privadas. Aprendemos que cada subnet está associada a uma única VPC e discutimos a importância das zonas de disponibilidade para garantir redundância e tolerância a falhas. Vamos criar três subnets públicas e três privadas, cada uma em uma zona diferente, utilizando o CIDR apropriado. Por fim, configuramos um Internet Gateway para permitir a conexão com a internet.

## 12. Finalizando a Criação do Cluster EKS

Na aula de hoje, exploramos a configuração de roteamento em uma VPC, incluindo a criação de uma tabela de roteamento para associar subnets públicas e privadas. Aprendemos a adicionar rotas para o Internet Gateway e o NAT Gateway, permitindo que subnets privadas acessem a internet. Também discutimos a criação de um cluster EKS, abordando a instalação de addons e a configuração do controle de acesso. Por fim, encerramos a aula aguardando a finalização da criação do cluster.

## 13. Criando NodeGroup

Na aula de hoje, exploramos a criação de um cluster EKS na AWS, começando pela configuração do ambiente local com a AWS CLI. Discutimos a importância de criar o cluster antes dos nós e como utilizar o Node Group para gerenciá-los. Também abordamos a configuração de subnets e a criação de uma role IAM. Ao final, verificamos que os pods estavam prontos para execução, preparando o terreno para a implementação de aplicações e conceitos mais avançados, como RBAC e Fargate.

## 14. Rodando a Nossa Aplicação no EKS

Nesta aula, vamos aplicar o manifesto do Kubernetes no nosso cluster EKS, semelhante ao que fizemos na DigitalOcean. Focaremos em um deployment simples, ajustando réplicas e recursos. Abordaremos a criação de namespaces e a execução de comandos no terminal. Também discutiremos a configuração de serviços, incluindo o uso de load balancer e suas implicações de custo. Por fim, falaremos sobre a importância de verificar subnets e IAM para evitar problemas.

## 15. Deletando Recursos

Hoje, vamos focar na deleção de recursos que criamos até agora. É importante remover o Node Group antes do cluster, pois há dependências. Também falamos sobre a remoção do Load Balancer e da estrutura da VPC, que deve ser feita hierarquicamente. Não se preocupe com o tempo de espera, pois o processo pode demorar. O objetivo é garantir que você saiba como gerenciar esses recursos de forma eficaz. Estou animado para seguirmos com o conteúdo de Kubernetes e AWS!
