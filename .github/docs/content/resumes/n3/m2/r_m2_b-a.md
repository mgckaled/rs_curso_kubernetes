# Resumo Aulas: Nível 3, Módulo 2, Bloco A - Explorando o Karpenter e definindo Roles

## 1. Introdução ao Karpenter

Nesta aula, exploramos a criação de um NodeGroup essencial para operar com componentes como CoreDNS e MetricsServer. Discutimos a transição do Cluster Autoscaler (CAS) para o Carpenter, destacando como o Carpenter otimiza o escalonamento de nós no Kubernetes. Ao contrário do CAS, que depende do Auto Scaling Group, o Carpenter faz o bin packing para alocar recursos de forma mais eficiente. Também abordamos a instalação do Carpenter como um Custom Resource Definition (CRD) e suas vantagens em relação ao CAS. Na próxima aula, vamos configurar o Carpenter no nosso cluster.

## 2. Criando as Primeiras Roles no IAM

Na aula de hoje, começamos a configuração do Carpenter, uma ferramenta que facilita a gestão de nós em clusters Kubernetes. Discutimos seu suporte a diferentes plataformas, como AWS, Azure e Oracle, embora tenha sido originalmente desenvolvido para o EKS. Abordamos a criação de duas roles essenciais no IAM da AWS: a Node Role e a Cluster Role, além de configurar um Identity Provider. A documentação do Carpenter é bastante completa, então não hesite em consultá-la para dúvidas. Vamos continuar com as configurações na próxima aula!

## 3. Finalizando Configurações de Acesso

Na aula de hoje, explorei como configurar o Carpenter em um cluster EKS, focando nas VPCs privadas e nos Security Groups. Abordei a importância de associar as subnets e os grupos de segurança corretamente, garantindo que o Carpenter não utilize subnets públicas. Também fizemos ajustes no ConfigMap para integrar as roles necessárias. Ao final, preparei o terreno para a instalação do Carpenter na próxima aula.
