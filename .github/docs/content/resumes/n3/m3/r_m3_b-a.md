# Resumo aulas Nível 3, Módulo 3, Bloco A - Explorando o spot instance

## 1. Conhecendo o conceito de Spot

Nesta aula, discutimos a configuração de um cluster EKS com instâncias EC2 T3 Medium e o uso do Carpenter para gerenciar workloads. Exploramos as Spot Instances, que são recursos ociosos da AWS, oferecendo economia significativa, mas com a ressalva de que podem ser interrompidas a qualquer momento. Abordamos a importância de utilizar Spot para aplicações stateless e como lidar com eventos de interrupção. Nas próximas aulas, vamos implementar essas práticas com o Carpenter.

## 2. Alterando o nosso NodePool

Commit da aula

Nessa aula, exploramos o uso de instâncias Spot no Kubernetes com o Carpenter. Discutimos como configurar o NodePool para utilizar apenas máquinas Spot, destacando a importância de entender os diferentes tipos de instâncias e suas características de custo. Abordamos a criação de uma role para permitir a criação de Spot Instances e a necessidade de monitorar a interrupção dessas máquinas. Na próxima aula, vamos aprender a gerenciar essas interrupções para evitar downtime nas aplicações.

## 3. Iniciando as configurações do SQS

Na aula de hoje, exploramos como monitorar eventos no EC2 da AWS e como usar o SQS para gerenciar essas notificações. Discutimos a criação de filas e a importância do EventBridge para interceptar eventos como interrupções de instâncias e mudanças de estado. Também falamos sobre a integração do SQS com o Lambda e como configurar regras no EventBridge para direcionar eventos para filas. Finalizamos com a criação de comandos para configurar essas regras e filas, preparando o terreno para a próxima etapa.

## 4. Ajustando Karpenter para reação de eventos

Na aula de hoje, exploramos a configuração de targets utilizando a linha de comando da AWS, focando em eventos do EventBridge e como eles interagem com o SQS. Realizamos a configuração das regras e targets, além de ajustar as políticas de acesso para o Carpenter. Discutimos a importância de usar o ARN correto e como garantir que o Carpenter tenha as permissões necessárias para acessar o SQS. Na próxima aula, faremos testes práticos para validar essa configuração.

## 5. Testando estrutura

Na aula de hoje, exploramos a integração do Carpenter com o SQS para gerenciar instâncias de forma reativa. Demonstrei como o Carpenter reage a eventos, como a terminação de instâncias, e como podemos monitorar mensagens no SQS. Também discutimos a configuração de NodePools, permitindo o uso de instâncias Spot e On Demand, e a importância de entender as condições de alocação. Finalizamos com a intenção de terraformar as configurações para manter tudo organizado.

## 6. Terrraformando estrutura

Nessa aula, vamos modularizar a criação de recursos no Terraform, focando na implementação do SQS e EventBridge para o Carpenter. A ideia é facilitar a gestão da infraestrutura como código (IaC) através de variáveis e módulos genéricos. Começamos criando um módulo específico para o SQS, definindo variáveis como nome da fila, tempo de retenção e timeout. Após configurar o módulo, faremos a inicialização e execução do Terraform para garantir que tudo funcione corretamente.

## 7. Refatorando módulo

Nesta aula, finalizei a criação de um recurso SQS na AWS, apesar de algumas dificuldades com o Terraform. Discutimos a nomenclatura e a importância de ajustar as políticas do Carpenter. Abordei como criar access points e configurar o EventBridge. Também introduzimos o conceito de "locals" para tornar o código mais limpo e escalável, facilitando a reutilização de variáveis. Por fim, fizemos um teste com o Terraform para garantir que tudo funcionasse corretamente antes de aplicar as mudanças.

## 8. Testes finais

Na aula de hoje, finalizei a execução do nosso projeto e fizemos um check na configuração do SQS, onde revisamos as políticas e ARNs. Também discutimos ajustes no IAM devido à mudança do nome da fila. Verificamos o EventBridge e suas regras, além de fazer algumas considerações sobre o uso do Terraform. Tentei aplicar uma nova aplicação no Kubernetes, mas encontramos um problema com a NodePool. Vamos retomar isso na próxima aula.

## 9. Corrigindo problema no security group

Na aula de hoje, discutimos a criação de instâncias EC2 e a importância de associá-las a subnets e security groups adequados. Abordamos um problema específico com o NodeGroup, onde a ausência de tags no security group impediu a criação de instâncias. Mostrei como resolver isso, aplicando as tags corretas e reconfigurando o ambiente. Além disso, falamos sobre o uso de instâncias on-demand e spot, e como isso impacta custos. Nas próximas aulas, vamos explorar políticas de cluster e outros tópicos avançados.
