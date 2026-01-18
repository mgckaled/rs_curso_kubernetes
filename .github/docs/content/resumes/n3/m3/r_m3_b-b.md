# Resumo aulas Nível 3, Módulo 3, Bloco B - Policies nativas do k8s

## 1. Conhecendo o conceito de políticas

Nesta aula, vamos explorar o conceito de políticas no Kubernetes, que são regras que definem permissões e garantem governança e segurança no cluster. Abordaremos o RBAC, que controla quem pode fazer o quê, e as Network Policies, que gerenciam a comunicação entre pods. Também falaremos sobre Pod Security Standards, Resource Quotas e Limit Ranges, que ajudam a regular o uso de recursos. Por fim, introduzirei os Admission Controllers para políticas mais avançadas.

## 2. Explorando o NetworkPolicy

Na aula de hoje, vamos explorar as Network Policies no Kubernetes, focando na regra Ingress. Começamos com uma introdução teórica e, em seguida, partimos para a prática, criando um arquivo YAML para configurar nossa política. Discutimos como restringir o tráfego entre pods usando selectors e match labels. Também fizemos testes de carga com a ferramenta FortIO para validar se a configuração estava funcionando corretamente. Ao final, percebemos que ainda havia ajustes a serem feitos, o que nos levará a uma próxima sessão.

## 3. Mudando algumas configurações na CNI

Nesta aula, exploramos a configuração do Amazon VPC-CNI, um plugin de rede essencial para a interface de rede de containers. Discutimos como o VPC-CNI afeta as Network Policies e a necessidade de segmentar regras para pods. Realizamos ajustes no daemon set para habilitar o modo estrito de políticas de rede e testamos a conectividade entre os pods. Enfrentamos alguns desafios durante os testes, que nos levaram a debater a importância das políticas de rede e como elas podem impactar a comunicação entre serviços.

## 4. Correções e testes finais de acesso

Nesta aula, exploramos o conceito de Network Policies, focando no modo "strict" e suas implicações. Discutimos como implementar políticas para gerenciar o tráfego entre pods, além de realizar testes práticos para verificar o funcionamento das regras. Também abordamos a diferença entre ingress e egress, explicando como configurar regras para controlar a saída de dados. Finalizamos a sessão introduzindo o Pod Security Standard, preparando o terreno para as próximas aulas.

## 5. Adendo sobre regra de rede em todo o namespace

Nesta aula, fiz uma correção sobre o uso do Namespace Selector em Network Policies. Expliquei que a política é aplicada a um Namespace, e não a cada deployment individual. Se as regras forem iguais, não é necessário criar uma política para cada um. O Namespace Selector deve ser usado apenas em Ingress ou Egress. Além disso, mencionei que é possível utilizar Match Label para selecionar Pods. Espero que essa correção ajude a esclarecer o tema.

## 6. Aplicando políticas de segurança

Nesta aula, exploramos o PodSecurityStandard e como ele se aplica a namespaces no Kubernetes. Começamos criando um namespace com um arquivo YAML e discutimos a importância das labels para segurança. Demonstrei como configurar regras de segurança, como "enforce", "audit" e "warn", que ajudam a proteger o cluster. Enfrentamos alguns erros ao tentar criar pods que violavam essas regras, destacando a governança necessária. Na próxima aula, vamos resolver esses problemas práticos.

## 7. Mudando configurações do Deployment

Na aula de hoje, exploramos a segurança em containers, focando em ajustes no deployment para evitar que aplicações rodem como root. Discuti como implementar o Security Context, incluindo a configuração de "run as non-root" e "allow privilege escalation". Também abordei a importância de perfis restritos para garantir que os containers operem com permissões mínimas. Ao final, demonstramos como resolver erros comuns e garantir um ambiente seguro. Na próxima aula, falaremos sobre Resource Quota e Limit Range.

## 8. Explorando Resource Quota

Nesta aula, exploramos o conceito de Resource Quota no Kubernetes, que permite definir limites de recursos, como CPU e memória, para namespaces. Demonstrei como criar um arquivo YAML para configurar essas quotas, especificando tanto limites de recursos quanto a quantidade de objetos, como pods e config maps. Mostrei na prática como esses limites funcionam, destacando que ao exceder a cota, o sistema não permite a criação de novos pods. Na próxima aula, vamos aprofundar na parte de requests.

## 9. Testando efetivade das cotas por namespace

Na aula de hoje, exploramos o conceito de Requests e Limits em Kubernetes, focando em como o Resource Quota funciona. Demonstrei como configurar e testar esses limites em um cluster, ajustando a alocação de CPU e memória dos pods. Também discutimos a importância do controle de recursos e como o Scope Selector pode ser utilizado para aplicar regras específicas. Por fim, introduzi o tema do Limit Range, que será abordado na próxima aula. Espero que você carontinue comigo!

## 10. Criando o nosso primeiro LimitRange

Nesta aula, exploramos o conceito de Limit Range e sua relação com Resource Quota. Aprendemos a definir limites e requisições para recursos em pods, garantindo que eles não consumam todo o nó de forma descontrolada. Mostrei como criar um arquivo YAML para configurar o Limit Range e discutimos a importância de definir valores mínimos e máximos. Também abordamos como verificar a aplicação dessas configurações e os desafios que podem surgir. Na próxima aula, faremos um debug para entender melhor esses pontos.

## 11. Testes finais e próximos passos

Na aula de hoje, fizemos um mergulho profundo nas políticas do Kubernetes, focando em limit ranges e resource quotas. Abordamos a importância de reaplicar configurações e como os valores de request e limit interagem. Discutimos também a precedência dos valores e a segurança no uso de recursos. Para finalizar, introduzi o Kiver, uma ferramenta que amplia as políticas no Kubernetes, e prometi que exploraremos mais sobre isso nas próximas aulas.
