# Resumo aulas Nível 4, Módulo 1, Bloco Único - GitOps e ArgoCD

## 1. Relembrando o Conceito de GitOps

Neste módulo do curso de Kubernetes avançado, vamos explorar o conceito de GitOps, que se baseia na ideia de ter o Git como a fonte da verdade para a operação. Discutiremos como isso se aplica tanto à infraestrutura quanto ao Kubernetes, garantindo que o que está no Git corresponda ao que está no cluster. Vamos abordar práticas de governança, automação e a importância de manter a consistência entre o Git e o ambiente Kubernetes. Prepare-se para aulas teóricas e práticas que aprofundarão seu entendimento.

## 2. Explorando GitOps no Contexto do Kubernetes

Na aula de hoje, abordamos a instalação e testes de uma aplicação simples, além de discutirmos o conceito de GitOps e sua relação com Terraform e IAC. Exploramos como o GitOps se aplica no Kubernetes, focando na conciliação entre o estado do Git e do cluster. Apresentamos duas abordagens: uma pipeline CI/CD e uma manual, destacando a importância da automação. Na próxima aula, vamos conhecer a ferramenta que facilitará essa reconciliação.

## 3. Conhecendo o ArgoCD

Na aula de hoje, exploramos o Argo CD, uma ferramenta de entrega contínua declarativa para Kubernetes, que automatiza a sincronização entre o repositório Git e o estado do cluster. Discutimos como ele se integra ao GitOps e como funciona o monitoramento contínuo de mudanças. Também abordamos a importância de manter os YAMLs como fonte da verdade e a possibilidade de utilizar a interface do Argo CD para fins de estudo. Na próxima aula, vamos instalar o Argo e aplicar uma aplicação simples.

## 4. Configurando o ArgoCD no Nosso Cluster

Na aula de hoje, exploramos o conceito de GitOps dentro do Kubernetes, focando na ferramenta Argo CD. Discutimos como o Argo CD atua como uma solução declarativa para manter a sincronia entre o repositório Git e o cluster Kubernetes. Aprendemos sobre a instalação do Argo CD, sua estrutura e os principais componentes, como Application Controller e Application Set. Também abordamos a interface gráfica e a linha de comando para interagir com o Argo. Na próxima aula, vamos configurar um repositório para criar aplicações.

## 5. Criando a Nossa Primeira Aplicação

Na aula de hoje, vamos conectar o Argo ao nosso repositório Git, utilizando o mesmo que usamos anteriormente para CI e CD. Discutimos a diferença entre o que o Argo considera dissonância e como ele aplica os YAMLs no Kubernetes. Também abordamos a configuração do repositório, optando pelo método SSH para maior segurança. Por fim, criamos uma nova aplicação no Argo, definindo políticas de sincronização e lidando com a criação de namespaces e recursos.

## 6. Corrigindo Objetos do Repositório

Nessa aula, exploramos o uso do Argo para gerenciar implantações no Kubernetes. Mostrei como cancelar pipelines, ajustar arquivos de configuração e monitorar o status dos pods. Discutimos a importância do AutoSync e como ele facilita o gerenciamento de alterações. Também abordamos o rollback e a visualização das diferenças entre o estado do cluster e o repositório. Na próxima aula, vamos nos aprofundar em multi-cluster e no Application Set, que simplifica a configuração de múltiplos repositórios.

## 7. Alterando a Nossa Estrutura de CI

Nessa aula, exploramos tópicos mais avançados, como multi-cluster e o conceito de Application Set, que ajuda a gerenciar configurações de aplicações em diferentes clusters, como staging e produção. Discutimos a estrutura de CI e como ela se relaciona com ferramentas como Argo e Helm. Demonstrei como automatizar a atualização de imagens de container usando GitHub Actions, além de abordar a sincronização com o Argo. Por fim, falamos sobre estratégias de organização de YAMLs para simplificar o desenvolvimento.

## 8. Explorando o Conceito Multi Cluster

Na aula de hoje, exploramos a estrutura multicluster do Argo. Começamos criando um novo cluster de staging e conectando-o ao Argo CD, que está instalado em outro cluster. Discutimos como gerenciar contextos e resolvemos problemas de autenticação. Também demonstramos como implementar aplicações em clusters diferentes, destacando a importância de ambientes semelhantes para staging e produção. Por fim, introduzimos o conceito de Application Set, que facilitará a gestão de múltiplas aplicações com YAMLs, tornando o processo mais escalável e eficiente.

## 9. Criando Nosso Primeiro ApplicationSet

Nesta aula, exploramos a criação de um YAML para um Application Set no Argo, focando na implementação de aplicações em múltiplos clusters simultaneamente. Começamos definindo o source e o destination, além de configurar o template com metadata e especificações necessárias. Discutimos a importância de garantir nomes únicos para evitar conflitos e utilizamos o Lens para visualizar os recursos. Ao final, aplicamos o YAML e verificamos a criação das aplicações, ressaltando a eficiência do Argo na orquestração de deploys.

## 10. Escalando a Nossa Configuração do GitHub

Nessa aula, compartilhei uma dica prática sobre automação na configuração de repositórios. Ao invés de conectar um por um, você pode configurar apenas um repositório via SSH, simplificando o processo. Demonstrei como criar um app e conectar ao repositório, além de mostrar como deletar aplicações e seus recursos no Kubernetes. É importante ter cuidado com a deleção, pois isso pode afetar sua estrutura. Espero que essas dicas ajudem a otimizar seu fluxo de trabalho!

## 11. Entendendo Mais Sobre os Projetos

Nesta aula, explorei a estrutura de projetos no Argo, destacando como gerenciar aplicações e repositórios de forma granular. Falei sobre o controle de permissões, a criação de roles e a configuração de Sync Window para agendar atualizações. Também introduzi o Helm, uma ferramenta que facilita o gerenciamento de pacotes no Kubernetes, prometendo simplificar a configuração e organização dos YAMLs. Nos próximos módulos, vamos aprofundar no Helm e como ele complementa o Argo.
