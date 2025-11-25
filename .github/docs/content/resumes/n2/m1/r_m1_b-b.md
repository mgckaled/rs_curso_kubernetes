# Resumo Aulas Nível 2 Módulo 1: Bloco B

## 1. Aplicando TF na Nossa Estrutura na AWS

Nesta aula, introduzimos o Terraform como uma ferramenta essencial para gerenciar infraestrutura na nuvem de forma declarativa, em vez de usar o console. Discutimos a importância de ter uma "fonte da verdade" para evitar problemas de governança e controle de recursos. Abordamos conceitos como módulos e variáveis para facilitar a reutilização de código ao criar um cluster EKS na AWS. Ao final, mostramos como inicializar e aplicar configurações no Terraform, preparando o ambiente para a próxima aula.

## 2. Revisando Estrutura

Na aula de hoje, exploramos a criação de recursos na AWS usando Terraform, focando na configuração do IAM, VPC e, principalmente, do cluster EKS. Discutimos o tempo que cada etapa levou, especialmente a criação do cluster e do CoreDNS. Também abordamos a importância do controle de estado no Terraform e como ele facilita a gestão de recursos. Por fim, fizemos uma atualização do KubeConfig e nos preparamos para a próxima aula, onde falaremos sobre RBAC e Service Accounts.

## 3. Contexto Inicial

Hoje, vamos explorar RBAC e Service Accounts no Kubernetes. Começamos discutindo a importância de ter um "declarativo" para gerenciar aplicações, evitando problemas de governança. O RBAC, que significa Controle de Acesso Baseado em Funções, é essencial para definir permissões e garantir que apenas usuários autorizados possam realizar ações específicas. Também falamos sobre Roles, Cluster Roles e como vincular essas permissões a Service Accounts. Na próxima aula, vamos aplicar esses conceitos na prática.

## 4. Criando Nosso Primeiro Usuário

Na aula de hoje, exploramos o gerenciamento de acesso no Kubernetes usando RBAC. Começamos discutindo a importância de não utilizar o usuário root para operações diárias e como criar um novo usuário com permissões específicas. Abordamos a configuração do ConfigMap para autenticação e como isso impacta o acesso ao cluster. Ao final, identificamos um erro de autenticação e planejamos voltar ao usuário root para ajustar as permissões necessárias.

## 5. Mapeamento de Conta no ConfigMap

Na aula de hoje, exploramos como gerenciar usuários e permissões no EKS da AWS. Começamos verificando a autenticação com o comando kubectl, seguido por uma configuração do kubeconfig usando credenciais do usuário root. Em seguida, mapeamos um novo usuário no config map AWS-Auth e testamos a autenticação com o kubectl. Discutimos a diferença entre erros de autorização e permissão, introduzindo o conceito de RBAC para gerenciar acessos no cluster.

## 6. Criando as Roles

Nessa aula, vamos trabalhar com RBAC no Kubernetes, focando na criação de roles e role bindings. Iniciaremos trocando de usuário para o admin, permitindo a criação das permissões. Vou explicar como configurar um manifesto RBAC para conceder acesso de leitura a pods em um namespace específico. É importante notar que essa configuração é mais relacionada à infraestrutura do cluster do que à aplicação em si. Após a criação, testaremos a aplicação das permissões e faremos ajustes conforme necessário.

## 7. Testando o Acesso

Na aula de hoje, exploramos a troca de usuários no Kubernetes, focando na atualização do KubeConfig e na verificação de permissões. Demonstrei como usar os comandos kubectl para listar pods e namespaces, além de discutir o controle de acesso através do RBAC. Abordei a importância de entender as permissões e como elas afetam a visualização de recursos no cluster. O conteúdo é denso, mas fundamental para compreender a configuração e o gerenciamento de acesso no Kubernetes.

## 8. Criando Nossa Primeira Cluster Role

Na aula de hoje, exploramos o RBAC (Role-Based Access Control) em Kubernetes, focando em como aplicar regras por namespace e também a nível de cluster. Mostrei como criar ClusterRoles e ClusterRoleBindings para permitir que usuários leiam pods e namespaces. Enfatizei a importância de entender as permissões e como configurá-las corretamente. O objetivo é que você consiga gerenciar o acesso dos usuários de forma eficiente em seu cluster. Na próxima aula, vamos abordar outro tipo de autenticação, o EKS API.

## 9. Configurando Permissão a Nível de Grupo

Nesta aula, explorei a configuração de grupos no EKS, mostrando como trocar de usuário e mapear permissões. Abordei a importância do controle de acesso, utilizando RBAC para gerenciar o que cada usuário ou grupo pode fazer. Demonstrei como alterar roles e bindings, além de destacar as boas práticas em relação a Secrets no Kubernetes. Finalizei mencionando a próxima etapa, que envolve a EKS API e o gerenciamento de RBAC.

## 10. Alterando Modo de Acesso ao Cluster

Nessa aula, exploramos a configuração do EKS, focando na transição entre o ConfigMap e o EKS API para gerenciar o acesso. Discutimos a importância do IAM da AWS e como ele centraliza as permissões. Demonstrei como alterar as credenciais no Terraform e as implicações dessa mudança. Também fizemos testes práticos com usuários e políticas, destacando a granularidade do RBAC. Por fim, enfatizei a necessidade de cuidado ao gerenciar permissões de admin.

## 11. Explorando o Modo de Acesso via EKS API

Nesta aula, focamos na configuração do EKS apenas com API, sem o ConfigMap. Fizemos ajustes no Terraform, alterando o AuthenticationMode para API e trocando o token do usuário Admin. Após validar o kubeconfig, rodamos o terraform plan e terraform apply para aplicar as mudanças. Discutimos a importância de entender o comportamento do Terraform, que pode exigir a destruição e recriação de recursos. Também enfatizei a necessidade de uma boa governança de usuários para evitar problemas de segurança.

## 12. Fechando RBAC e Últimos Testes

Nesta aula, abordamos a configuração do EKS API e a migração do ConfigMap para um gerenciamento mais robusto via IAM. Demonstrei como atualizar o token de acesso e validar permissões do usuário no cluster. Também discutimos a sensibilidade das alterações no Kubernetes e a importância de um gerenciamento cuidadoso com o Terraform. Finalizamos com uma introdução ao conceito de Service Account, que será explorado na próxima aula.

## 13. Criando uma Service Account

Nesta aula, exploramos o conceito de Service Account no Kubernetes, que serve como a identidade de um processo em um pod. Discutimos como criar uma Service Account e sua importância para interações seguras com a API do Kubernetes. Abordamos também a associação de roles e a segmentação de permissões, enfatizando a segurança granular. Ao final, mencionamos a transição para tópicos sobre DaemonSet e StatefulSet, essenciais para gerenciar aplicações e agentes dentro do cluster.
