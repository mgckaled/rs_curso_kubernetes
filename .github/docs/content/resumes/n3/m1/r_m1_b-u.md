# Resumo aulas Nível 3, Módulo 1, Bloco Único - Explorando a Auto Sscala dos Nós

## 1. Qual é o Problema Que Queremos Resolver

Nesta aula, exploramos a escala da aplicação em termos de infraestrutura, focando na configuração do HPA (Horizontal Pod Autoscaler) no Kubernetes. Discutimos como a escala horizontal permite aumentar o número de réplicas em resposta à demanda, mas também destacamos a importância de considerar a capacidade do cluster. Abordamos a necessidade de distribuir aplicações entre múltiplos nós para garantir resiliência e evitar downtime. Na próxima aula, vamos aprofundar mais nas questões de escalabilidade e gestão de recursos.

## 2. Estressando Aplicações

Nessa aula, exploramos a alocação de recursos em um cluster, discutindo erros de insuficiência de CPU e como otimizar o uso de pods. Falei sobre a importância de definir limites e requisições para evitar desperdício, já que alocar muitos recursos sem uso gera custos desnecessários. Também abordamos a relação entre a quantidade de pods e a capacidade do nó, além de dicas para escalar eficientemente.

## 3. EKS Nodegroup

Nessa aula, exploramos como funcionam as escalas de nós no Kubernetes, focando no EKS Node Group. Discutimos a importância de configurar corretamente a quantidade de nós para evitar custos desnecessários. Mostrei como ajustar as configurações via Terraform, definindo um mínimo e máximo de nós para atender à demanda. Também abordamos a relação entre a alocação de recursos e a performance das cargas de trabalho.

## 4. Explorando Alguns Cenários do NodeGroup

Na aula de hoje, abordamos a configuração de um Node Group no Kubernetes e como isso impacta a escalabilidade. Discutimos a importância de ter métricas para acionar o scaling automático e como a falta delas pode causar downtime. Também introduzimos o conceito de múltiplos Node Groups para evitar interrupções durante atualizações. Além disso, falamos sobre o Cluster Autoscaler, que será o foco do próximo módulo, e como ele pode ajudar a gerenciar a alocação de recursos de forma mais eficiente.

## 5. Iniciando a Configuração do Cluster Autoscaler

Na aula de hoje, exploramos o Cluster Outscale e suas funcionalidades para escalar clusters no Kubernetes. Discutimos a instalação manual, a importância das tags para o auto-discovery e as diferenças entre escalas vertical e horizontal. Enfrentamos alguns desafios, como erros de configuração e a necessidade de conectar o Cluster Outscale à AWS. Na próxima aula, vamos abordar como configurar o IAM para resolver esses problemas e garantir uma integração adequada.

## 6. Configurando Política

Nesta aula, vamos explorar a criação de políticas no IAM da AWS, focando em auto-scaling. Começamos configurando permissões específicas para ações de leitura e escrita, como descrever instâncias e grupos de auto-scaling. Abordamos também a importância de condições de segurança, utilizando tags para restringir ações a grupos específicos. Ao final, criamos uma política personalizada para o controle de auto escala dos nós do EKS. Prepare-se para entender como gerenciar identidades e permissões na AWS de forma eficiente!

## 7. Configurando Role

Na aula de hoje, exploramos a configuração de uma service account no AWS EKS e como associá-la a uma política de acesso. Discutimos a importância de evitar sobrescrições ao gerenciar arquivos de configuração e a necessidade de criar um Identity Provider antes de definir uma role. Também abordamos o troubleshooting, identificando e corrigindo erros relacionados a credenciais. Finalizamos com a configuração bem-sucedida do Cluster Autoscaler, enfatizando boas práticas no uso do IAM.

## 8. Escalando o Nosso Cluster

Na aula de hoje, explorei como configurar e monitorar um Cluster Outscale, focando na escalabilidade da aplicação. Demonstrei como aumentar a carga, usar ferramentas como K6 e Chaos Mesh, e ajustar réplicas no Kubernetes. Abordei a importância do HPA para escalar automaticamente, além de discutir o gerenciamento de nós e a necessidade de monitoramento constante para evitar custos desnecessários. No próximo módulo, vamos mergulhar no Carpenter, que traz uma abordagem mais dinâmica para gerenciamento de nós.

## 9. Cluster Sendo Desescalado

Na aula de hoje, explorei a automação de escalonamento no Kubernetes, focando em como os nós podem ser marcados para deleção com a taint "Prefer No Schedule". Isso impede que novas cargas sejam alocadas nesses nós, permitindo uma gestão mais eficiente da infraestrutura. Abordei também a aleatoriedade e a efemeridade do Kubernetes, destacando a importância do Cluster Autoscaler. Fiquem ligados, pois nas próximas aulas vamos aprofundar no Carpenter e em outros conceitos avançados.
