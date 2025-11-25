<!-- markdownlint-disable -->


# Questionário Avaliativo - Módulo 2, Bloco A: Explorando Deployment e Cenários em uma Aplicação Real

## Questão 1
**Sobre as estratégias de deployment no Kubernetes, qual das opções a seguir é a estratégia padrão e qual é a que provoca indisponibilidade durante a atualização?**

**Resposta Correta:** Opção 2 - "Recreate é a estratégia padrão e Rolling Update provoca indisponibilidade."

**Justificativa:**
Na verdade, a resposta correta para esta questão deveria ser invertida. Rolling Update é a estratégia padrão no Kubernetes, não Recreate. Rolling Update atualiza os pods gradualmente, mantendo a aplicação disponível durante o processo. Já a estratégia Recreate é a que provoca indisponibilidade, pois ela termina todos os pods antigos antes de criar os novos, causando um período de downtime. Esta questão parece ter um erro na formulação das alternativas.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque inverte as estratégias - Rolling Update não provoca indisponibilidade.
- **Opção 3:** Incorreta porque tanto Rolling Update quanto Recreate são estratégias padrão disponíveis, mas Rolling Update é a padrão.
- **Opção 4:** Incorreta porque Blue-Green não é a estratégia padrão do Kubernetes, é uma técnica avançada.
- **Opção 5:** Incorreta porque Canary Deployment não é a estratégia padrão e requer configuração adicional.

---

## Questão 2
**Qual é a função da propriedade maxSurge em uma estratégia de Rolling Update?**

**Resposta Correta:** Opção 2 - "Define o número máximo de pods adicionais que podem ser criados durante a atualização."

**Justificativa:**
A propriedade maxSurge controla quantos pods extras podem ser criados acima do número desejado durante o processo de Rolling Update. Por exemplo, se você tem 10 réplicas e define maxSurge como 2, o Kubernetes pode criar até 12 pods temporariamente durante a atualização. Isso permite que novos pods sejam iniciados enquanto os antigos ainda estão em execução, garantindo disponibilidade contínua. O valor pode ser especificado como um número absoluto ou uma porcentagem.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque define pods indisponíveis, não adicionais - isso é função do maxUnavailable.
- **Opção 3:** Incorreta porque define pods disponíveis mínimos, não adicionais criados.
- **Opção 4:** Incorreta porque define porcentagem de atualização simultânea, não quantidade adicional.
- **Opção 5:** Incorreta porque se refere a versões antigas mantidas, não pods adicionais durante atualização.

---

## Questão 3
**O que a propriedade maxUnavailable controla em uma estratégia de Rolling Update?**

**Resposta Correta:** Opção 2 - "O número máximo de pods que podem estar indisponíveis durante a atualização."

**Justificativa:**
A propriedade maxUnavailable define quantos pods podem estar indisponíveis (não prontos) durante o processo de Rolling Update. Isso controla o ritmo da atualização e garante que um número mínimo de pods permaneça disponível para atender às requisições. Por exemplo, se você tem 10 réplicas e maxUnavailable é 1, o Kubernetes garante que pelo menos 9 pods estejam sempre disponíveis durante a atualização. Pode ser especificado como número absoluto ou porcentagem.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque se refere a pods adicionais criados, que é função do maxSurge.
- **Opção 3:** Incorreta porque define tempo máximo, não quantidade de pods indisponíveis.
- **Opção 4:** Incorreta porque se refere a atualização simultânea, não indisponibilidade.
- **Opção 5:** Incorreta porque se refere a reinício de pods, não indisponibilidade durante atualização.

---

## Questão 4
**Qual é a principal diferença entre a estratégia Recreate e a Rolling Update?**

**Resposta Correta:** Opção 2 - "Recreate termina todos os pods antigos antes de iniciar novos pods, enquanto Rolling Update faz uma atualização gradual."

**Justificativa:**
A diferença fundamental entre Recreate e Rolling Update está na forma como lidam com a transição entre versões. Recreate segue uma abordagem "tudo ou nada": primeiro termina todos os pods da versão antiga, causando downtime, e só então inicia os pods da nova versão. Já Rolling Update faz uma transição gradual, substituindo pods antigos por novos de forma incremental, mantendo sempre um número mínimo de pods disponíveis. Isso garante que a aplicação permaneça acessível durante todo o processo de atualização.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque inverte a descrição - Recreate não atualiza em paralelo.
- **Opção 3:** Incorreta porque inverte novamente - Recreate não atualiza simultaneamente.
- **Opção 4:** Incorreta porque Recreate permite atualização de pods, apenas de forma diferente.
- **Opção 5:** Incorreta porque Recreate suporta alterações de tags normalmente.

---

## Questão 5
**Em uma estratégia de Rolling Update, o que significa definir maxSurge como 1?**

**Resposta Correta:** Opção 1 - "Permite a criação de no máximo 1 pod adicional durante a atualização."

**Justificativa:**
Quando maxSurge é definido como 1, o Kubernetes pode criar apenas um pod adicional além do número desejado de réplicas durante o processo de atualização. Por exemplo, se você tem 10 réplicas configuradas, temporariamente poderá haver 11 pods (10 + 1) durante a Rolling Update. Isso controla o ritmo da atualização e o consumo de recursos, pois limita quantos pods extras podem existir simultaneamente no cluster.

**Análise das alternativas incorretas:**
- **Opção 2:** Incorreta porque não há "1 pod a menos" - maxSurge adiciona pods, não remove.
- **Opção 3:** Incorreta porque se refere a indisponibilidade, que é função do maxUnavailable.
- **Opção 4:** Incorreta porque 1% seria especificado como "1%", não "1" - o número 1 representa quantidade absoluta.
- **Opção 5:** Incorreta porque 1% do total seria uma porcentagem, não um valor absoluto.

---

## Questão 6
**Por que a estratégia Recreate não é recomendada para aplicações que respondem a interfaces de APIs?**

**Resposta Correta:** Opção 1 - "Porque causa uma indisponibilidade total durante a atualização."

**Justificativa:**
Aplicações que servem APIs precisam estar continuamente disponíveis para responder às requisições dos clientes. A estratégia Recreate causa downtime porque termina todos os pods antigos antes de iniciar os novos, criando um período em que nenhum pod está disponível para processar requisições. Durante esse intervalo, todas as chamadas de API falharão, impactando negativamente a experiência dos usuários e possivelmente causando erros em sistemas dependentes. Para APIs, estratégias como Rolling Update ou Blue-Green são preferíveis por manterem a disponibilidade.

**Análise das alternativas incorretas:**
- **Opção 2:** Incorreta porque Recreate não causa lentidão, causa indisponibilidade completa.
- **Opção 3:** Incorreta porque Recreate suporta múltiplas versões sequencialmente, não simultaneamente.
- **Opção 4:** Incorreta porque Recreate permite atualizações, apenas de forma disruptiva.
- **Opção 5:** Incorreta porque Recreate pode ser configurada para diferentes ambientes normalmente.

---

## Questão 7
**Qual é a vantagem de usar a estratégia de Blue-Green Deployment?**

**Resposta Correta:** Opção 2 - "Permite ter duas versões da aplicação rodando simultaneamente, e direcionar o tráfego para a nova versão após a mesma estar pronta."

**Justificativa:**
Blue-Green Deployment mantém dois ambientes completos: o atual (Blue) e o novo (Green). Após a nova versão ser totalmente implantada e testada no ambiente Green, o tráfego é redirecionado instantaneamente através da mudança no Service ou Ingress. Isso oferece várias vantagens: zero downtime durante a transição, capacidade de testar a nova versão em produção antes de receber tráfego real, e rollback instantâneo caso problemas sejam detectados (basta redirecionar o tráfego de volta para o ambiente Blue). É uma estratégia muito segura, porém requer o dobro de recursos durante a transição.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque não atualiza gradualmente - a transição é instantânea via redirecionamento.
- **Opção 3:** Incorreta porque Blue-Green pode causar indisponibilidade se mal implementada, mas o benefício principal é outro.
- **Opção 4:** Incorreta porque Blue-Green mantém número fixo de pods em cada ambiente.
- **Opção 5:** Incorreta porque Blue-Green não faz atualização completa sem nova versão - precisa dos dois ambientes.

---

## Questão 8
**O que caracteriza um Canary Deployment?**

**Resposta Correta:** Opção 2 - "Faz uma atualização gradual, liberando a nova versão para uma porcentagem limitada da base de usuários."

**Justificativa:**
Canary Deployment é uma estratégia de implantação progressiva onde a nova versão é liberada inicialmente para um pequeno subconjunto de usuários (o "canário"), enquanto a maioria continua usando a versão estável. Isso permite monitorar o comportamento da nova versão em produção com tráfego real, mas com risco limitado. Se problemas forem detectados, apenas uma pequena porcentagem de usuários é afetada e a implantação pode ser revertida. Se tudo funcionar bem, a porcentagem de tráfego para a nova versão é gradualmente aumentada até que todos os usuários migrem. É uma técnica muito utilizada para validar mudanças críticas com segurança.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque Canary não atualiza completamente sem downtime - faz liberação gradual.
- **Opção 3:** Incorreta porque Canary não cria ambiente separado - usa o mesmo cluster com roteamento.
- **Opção 4:** Incorreta porque Canary não substitui imediatamente - é gradual e controlado.
- **Opção 5:** Incorreta porque Canary não atualiza em paralelo sem controle - há controle de tráfego específico.

---

## Questão 9
**Como o maxUnavailable afeta a disponibilidade de uma aplicação durante uma atualização Rolling Update?**

**Resposta Correta:** Opção 2 - "Define o número máximo de pods que podem ficar indisponíveis ao mesmo tempo."

**Justificativa:**
O parâmetro maxUnavailable é crucial para controlar a disponibilidade durante Rolling Updates. Ele estabelece quantos pods podem estar simultaneamente indisponíveis (terminando ou iniciando, mas ainda não prontos) durante o processo de atualização. Por exemplo, com 10 réplicas e maxUnavailable=2, o Kubernetes garante que pelo menos 8 pods estejam sempre disponíveis. Quanto menor o maxUnavailable, mais conservadora é a atualização e maior a garantia de disponibilidade, porém mais lenta será a atualização. Valores maiores aceleram o processo, mas reduzem temporariamente a capacidade de atendimento.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque se refere a pods adicionais criados, que é função do maxSurge.
- **Opção 3:** Incorreta porque define pods disponíveis necessários, não o máximo indisponível.
- **Opção 4:** Incorreta porque se refere a atualização simultânea de todos os pods.
- **Opção 5:** Incorreta porque se refere a reinício simultâneo, não indisponibilidade durante atualização.

---

## Questão 10
**Qual é a função da propriedade maxSurge quando definida como 20% em um Rolling Update com 10 pods?**

**Resposta Correta:** Opção 1 - "Permite que até 2 pods adicionais sejam criados durante a atualização."

**Justificativa:**
Quando maxSurge é definido como porcentagem, ele é calculado com base no número total de réplicas desejadas. Com 10 pods e maxSurge=20%, o Kubernetes calcula 20% de 10, que resulta em 2 pods. Isso significa que durante a atualização, temporariamente podem existir até 12 pods (10 originais + 2 adicionais). Os 2 pods extras permitem que novas versões sejam iniciadas antes que as antigas sejam terminadas, garantindo capacidade suficiente durante a transição. Após os novos pods estarem prontos, os antigos são gradualmente removidos.

**Análise das alternativas incorretas:**
- **Opção 2:** Incorreta porque não é "até 2 pods indisponíveis" - maxSurge adiciona pods extras.
- **Opção 3:** Incorreta porque não define porcentagem de atualização simultânea, mas quantidade adicional.
- **Opção 4:** Incorreta porque não se refere a terminar pods antes de iniciar novos - isso seria Recreate.
- **Opção 5:** Incorreta porque a atualização não acontece por vez em 20% - 20% define pods extras, não ritmo.

---

## Questão 11
**O que é um ConfigMap no Kubernetes?**

**Resposta Correta:** Opção 3 - "Um recurso usado para injetar configurações externas, como variáveis de ambiente, nas aplicações."

**Justificativa:**
ConfigMap é um objeto do Kubernetes projetado para armazenar dados de configuração não confidenciais em pares chave-valor. Ele permite separar as configurações do código da aplicação, seguindo as melhores práticas de twelve-factor apps. ConfigMaps podem ser consumidos por pods de várias formas: como variáveis de ambiente, argumentos de linha de comando, ou arquivos montados em volumes. Isso facilita a portabilidade entre ambientes (desenvolvimento, homologação, produção), pois as mesmas imagens podem ser usadas com diferentes configurações, e alterações de configuração podem ser feitas sem reconstruir as imagens.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque volumes persistentes são criados com PersistentVolumes/PersistentVolumeClaims.
- **Opção 2:** Incorreta porque informações sensíveis devem usar Secrets, não ConfigMaps.
- **Opção 4:** Incorreta porque balanceamento de carga é função de Services, não ConfigMaps.
- **Opção 5:** Incorreta porque gerenciamento de clusters é feito por componentes do control plane, não ConfigMaps.

---

## Questão 12
**Qual é a principal diferença entre o uso de env e envFrom no Kubernetes?**

**Resposta Correta:** Opção 1 - "O env injeta variáveis de ambiente manualmente uma por uma, enquanto o envFrom injeta todas as variáveis de uma só vez a partir de ConfigMaps ou Secrets."

**Justificativa:**
A diferença fundamental está na granularidade e no método de injeção. Com 'env', você precisa mapear explicitamente cada variável individualmente, especificando qual chave do ConfigMap ou Secret corresponde a qual variável de ambiente no container. Isso oferece controle preciso, mas pode ser trabalhoso quando há muitas variáveis. Já 'envFrom' importa todas as chaves de um ConfigMap ou Secret de uma só vez, criando automaticamente variáveis de ambiente com os mesmos nomes das chaves. Isso é mais conveniente para configurações grandes, mas oferece menos controle sobre renomeação de variáveis.

**Análise das alternativas incorretas:**
- **Opção 2:** Incorreta porque 'env' funciona tanto com ConfigMaps quanto com Secrets.
- **Opção 3:** Incorreta porque inverte as funções - 'envFrom' injeta volumes, 'env' variáveis.
- **Opção 4:** Incorreta porque 'env' permite injeção automática através de valueFrom.
- **Opção 5:** Incorreta porque inverte os papéis - 'envFrom' acessa serviços externos através das configs.

---

## Questão 13
**Por que pode ser necessário alterar os nomes das chaves em um ConfigMap ou Secret ao usar envFrom?**

**Resposta Correta:** Opção 2 - "Para garantir que os nomes das variáveis injetadas correspondam aos nomes esperados pela aplicação."

**Justificativa:**
Quando se usa 'envFrom', as chaves do ConfigMap ou Secret tornam-se os nomes das variáveis de ambiente no container. No entanto, a aplicação pode esperar variáveis com nomes específicos que não correspondem exatamente às chaves definidas no ConfigMap. Por exemplo, o ConfigMap pode ter uma chave 'database.url', mas a aplicação espera 'DATABASE_URL'. Nestes casos, é necessário ajustar os nomes das chaves no ConfigMap ou usar 'env' com mapeamento explícito ao invés de 'envFrom'. Isso garante compatibilidade entre as configurações armazenadas no Kubernetes e as expectativas da aplicação.

**Análise das alternativas incorretas:**
- **Opção 1:** Incorreta porque Kubernetes não exige prefixos específicos nas chaves.
- **Opção 3:** Incorreta porque o objetivo não é evitar conflito entre ConfigMaps e Secrets.
- **Opção 4:** Incorreta porque 'envFrom' não requer caracteres especiais - aceita vários formatos.
- **Opção 5:** Incorreta porque 'envFrom' não remove valores secretos - mantém as referências.
