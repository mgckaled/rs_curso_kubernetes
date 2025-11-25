# Resumo Aulas Nível 2 Módulo 2: Bloco B - Adaptando nossa Pipeline

## 1. Relembrando o GitHub Actions

Nesta aula, vamos explorar a automatização do deploy em Kubernetes, focando na integração contínua (CI) e entrega contínua (CD). Até agora, nosso processo era manual, envolvendo alterações na aplicação, builds locais e pushes para o Docker Hub. O objetivo é automatizar essas etapas, preparando um ambiente de CI que inclui instalação de dependências e execução de testes. Em seguida, abordaremos o CD, que se refere ao deploy da aplicação no cluster EKS. Na próxima aula, começaremos a implementar essa estrutura.

## 2. Criando a estrutura inicial

Nessa aula, vamos criar um repositório no GitHub e explorar o uso do GitHub Actions para CI/CD. Faremos uma introdução a várias ferramentas disponíveis, mas focaremos na configuração do GitHub Actions. Abordaremos a criação de um workflow em YAML, definindo gatilhos e jobs, além de configurar o ambiente com Node.js e Yarn. Ao final, realizaremos um commit e veremos a execução do CI.

## 3. Buildando a Nossa Imagem

Na aula de hoje, seguimos com a evolução da nossa pipeline, focando no passo do Docker Build. Aprendemos a gerar uma imagem no Ubuntu e a importância de automatizar a tag das imagens usando a hash do commit, ao invés de versões como V11 ou V12. Discutimos boas práticas e como otimizar o uso do Git Actions, além de verificar o andamento do build. Agora, vamos nos preparar para a etapa do push.

## 4. Fazendo o Push e Configurando Variáveis

Na aula de hoje, seguimos com a etapa do push no Docker, onde discutimos como realizar o `docker push` e a importância de autenticação, mesmo em repositórios públicos. Abordamos também boas práticas de tagueamento, como usar a tag `latest` para consistência, mas sem deploy. Aprendemos a criar variáveis e secrets no GitHub para gerenciar credenciais de maneira segura. Por fim, fizemos um teste prático e preparamos o terreno para a próxima aula, que abordará a integração com a AWS.

## 5. Configurando a Nossa Role na AWS

Na aula de hoje, focamos na configuração da etapa de publicação do nosso pipeline, especialmente na conexão com o EKS da AWS. Abordamos como usar o OpenID Connect para garantir segurança ao invés de credenciais legadas. Criamos um provedor de identidade e uma role para permitir que o GitHub Actions acesse a AWS de forma controlada. Ao final, testamos a configuração e conseguimos autenticar com sucesso. Na próxima aula, vamos conectar nosso cluster EKS e aplicar as configurações.

## 6. Debugando um Problema no Permissionamento

Nesta aula, vamos estabelecer a conexão entre o Git e o EKS na AWS. Já temos a conexão com a AWS funcionando, mas precisamos configurar o EKS. Mostrei como usar o comando `aws eks update-kubeconfig` e a importância de definir variáveis como `clusterName`. Abordei também a questão de permissões, destacando que a role atual não tem acesso suficiente, o que pode gerar erros. Vamos ajustar isso e continuar a configuração do nosso cluster.

## 7. Atualizando Kubeconfig Via Pipe

Nessa aula, vamos explorar como resolver problemas de acesso na AWS, focando em permissões e relações de confiança. Mostrarei como criar uma política inline para permitir que um cluster EKS seja descrito. Também discutiremos o uso do kubectl para aplicar configurações no Kubernetes, abordando a questão de tags e como fazer substituições em arquivos YAML. Vamos entender os prós e contras de diferentes abordagens, preparando o terreno para o uso do Helm em aulas futuras.

## 8. Deployando Nossa Aplicação de Maneira Automatizada

Nesta aula, abordamos a solução de problemas relacionados ao CubeControl e a configuração de credenciais de acesso no EKS. Discutimos a importância do debug e como a configuração do ConfigMap impacta a autenticação. Realizamos alterações na role para garantir que o acesso fosse concedido corretamente, além de criar um namespace e configurar os recursos necessários para o deployment. Também exploramos a execução de pipelines e a importância de verificar as tags de imagem.

## 9. Últimos Testes e Evoluções

Na aula de hoje, finalizei a implementação do namespace e atualizei componentes como ConfigMap e Service. Discutimos o comando `rollout status` para monitorar o status do deployment no Kubernetes, além de realizar um downscale por falta de recursos. Também abordei a importância de manter a fonte da verdade no código e a migração para o ECR. Por fim, antecipei o próximo módulo sobre Carpenter, que permitirá escalar o cluster automaticamente.
