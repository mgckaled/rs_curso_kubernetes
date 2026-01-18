# Resumo aulas Nível 3, Módulo 3, Bloco C - Explorando Kyverno

## 1. Evoluindo no contexto de políticas

Nessa aula, exploramos as políticas padrão do cluster e introduzimos o Kyverno, uma ferramenta que vai além da fiscalização, atuando como um gerente que automatiza e corrige tarefas. Discutimos como o Kyverno pode aplicar configurações automaticamente, como no caso de namespaces, e suas funcionalidades de mutação e geração. Essa automação não só aumenta a segurança, mas também facilita a gestão do cluster. Na próxima aula, aprofundaremos mais no Kyverno e compararemos com outra ferramenta similar.

## 2. Conhecendo o Kyverno

Hoje, vamos explorar o OPA (Open Policy Agent) e o Kyverno, focando em como eles ajudam na governança de políticas, especialmente no Kubernetes. O OPA oferece uma linguagem de políticas mais poderosa, o Rego, enquanto o Kyverno é mais simples e se integra diretamente ao Kubernetes, utilizando YAML. Discutimos como o Kyverno atua como um Admission Controller, permitindo mutações e validações de recursos. No final, instalamos o Kyverno no cluster, preparando o terreno para as próximas aulas.

## 3. Criando a nossa primeira ClusterPolicy

Nesta aula, vamos explorar o Kyverno, focando na criação de uma Cluster Policy para proibir o uso da tag "latest" em imagens de contêiner. Vou mostrar como configurar essa política no VSCode, explicando a estrutura necessária e a lógica por trás dela. Vamos aplicar a política e testar sua eficácia, observando como o Kyverno bloqueia tentativas de uso da tag proibida. No final, faremos uma breve introdução sobre mutações, que será o tema da próxima aula.

## 4. Testando a criação de uma Policy

Na aula de hoje, exploramos a diferença entre Cluster Policy e Policy, focando em como aplicar regras a namespaces específicos. Demonstrei a criação e deleção de políticas, além de como o contexto de namespace influencia a aplicação das regras. Também discutimos a funcionalidade de auditoria, onde as políticas não bloqueiam, mas geram eventos de aviso. Finalizamos com a promessa de abordar o tema do "butate" na próxima aula.

## 5. Explorando o objeto Mutate

Na aula de hoje, explorei como criar uma política de mutação usando YAML para adicionar labels padrão a objetos no Kubernetes. Demonstrei a criação de uma Cluster Policy chamada "addDefaultLabels", que aplica labels automaticamente a pods. Abordei também como usar pré-condições para garantir que as labels sejam adicionadas apenas se não existirem. O foco foi na governança do cluster, garantindo que todos os recursos tenham as labels corretas. Na próxima aula, vamos falar sobre triggers e geração de namespaces.

## 6. Copiando configurações entre namespaces

Nesta aula, exploramos a automação com Kubernetes, focando na criação de políticas para sincronizar secrets e config maps entre namespaces. Abordamos a importância de permissões e como configurar o ClusterPolicy para clonar dados sensíveis. Demonstrei como criar um arquivo YAML para o SyncSecret e o SyncConfigMap, além de mostrar como o Kyverno gerencia essas cópias. Também discutimos a governança e a possibilidade de sincronizar alterações entre os recursos. Na próxima aula, vamos aprofundar mais em exemplos práticos.

## 7. Criando políticas para bloquear execução de containers root

Na aula de hoje, explorei como criar uma política para bloquear o uso do usuário root em deployments no Kubernetes. Demonstrei a criação de uma política chamada block-root-user.yaml, enfatizando a importância de começar com auditoria antes de aplicar regras restritivas. Também discuti a possibilidade de usar mutações para garantir que containers não rodem como root, mostrando como isso pode ser feito de forma eficaz. Finalizei com a promessa de um próximo exemplo mais complexo.

## 8. Checando probes

Nesta aula, exploramos um exemplo mais complexo sobre validação de probes, focando no startup, readiness e liveness probes. Aprendemos a criar uma política de cluster no Kyverno para garantir que esses probes estejam sempre definidos em deployments, daemon sets e stateful sets. Abordamos como validar campos específicos, como o período de checagem e a existência de paths. Também fizemos testes práticos para verificar se as regras estavam funcionando corretamente e discutimos possíveis erros. Na próxima aula, faremos um debug dos problemas encontrados.

## 9. Últimos testes e fechamento

Nesta aula, finalizei o conteúdo sobre políticas no Kyverno, abordando a importância das probes e como elas funcionam. Discuti a obrigatoriedade de campos e como validar a presença deles, além de demonstrar a criação de regras de auditoria e enforce. O foco foi em simular erros para facilitar o aprendizado prático. Encerramos com uma introdução ao próximo tema, GitOps, utilizando o Argo CD, que promete ser um assunto fascinante.
