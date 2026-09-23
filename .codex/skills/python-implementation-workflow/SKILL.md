---
name: python-implementation-workflow
description: executa tarefas de programação Python ponta a ponta como workflow de engenharia senior. use quando o usuário pedir para implementar, alterar, corrigir, refatorar ou evoluir código em projetos Python, incluindo mapeamento inicial, preservação de padrões, implementação, testes e validação.
---

# Workflow de Implementação

## Objetivo

Executar tarefas de programação de ponta a ponta com mudanças pequenas, consistentes com o projeto e validadas por testes.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "implemente essa feature"
- "corrija esse bug"
- "altere esse comportamento"
- "refatore esse fluxo"
- "adicione suporte para..."
- "faça essa task"

## Procedimento

Quando esta skill for usada:
1. Entenda a task e identifique requisitos explícitos, implícitos e ambiguidades.
2. Pergunte somente quando a ambiguidade puder levar a uma implementação errada ou arriscada.
3. Não pergunte por informação que pode ser descoberta lendo o projeto.
4. Mapeie o projeto antes de editar: leia instruções locais, estrutura, stack, pontos de entrada, testes e arquivos relacionados.
5. Localize código existente que já resolva parte do problema antes de criar código novo.
6. Identifique padrões de nomenclatura, organização, classes, funções, métodos, imports, erros, logging e testes.
7. Implemente a menor mudança coerente com o comportamento pedido.
8. Crie ou atualize testes para toda mudança comportamental.
9. Pergunte antes de executar testes ou validações demoradas, salvo quando o usuário já tiver pedido explicitamente.
10. Reporte claramente o que foi ou não foi executado.

## Correção de bugs

Quando a task for corrigir um bug, execute estas etapas antes de editar código:

1. Reproduza o problema: confirme o comportamento incorreto com um exemplo concreto, caso de teste ou sequência de passos.
2. Identifique a causa raiz, não o sintoma: entenda por que o bug acontece antes de propor correção.
3. Verifique se deveria existir um teste cobrindo esse caso: a ausência de teste frequentemente é parte do bug.
4. Corrija a causa raiz; evite adicionar condição protetora ou contornar o problema sem entender a origem.
5. Adicione ou atualize o teste que deveria cobrir o caso que falhou.

## Branch e plano da issue

Antes de editar qualquer arquivo:

1. Identificar a issue: ID do Plane (ex.: `MONV4-58`) ou identificador local (`LOCAL-<slug>`), conforme a skill `task-planner`.
2. Se existir `tmp/plans/<identificador>/`, ler os arquivos da pasta em ordem numérica. As decisões do plano prevalecem sobre a issue; divergência entre plano e pedido atual deve ser apontada ao usuário antes de implementar.
3. Atualizar a branch base do projeto (normalmente `develop`) com `git fetch` e fast-forward.
   - Se o acesso ao remoto falhar, avançar a base local até o último `origin/<base>` já baixado (`git merge --ff-only origin/<base>`), informar a falha ao usuário e registrar o commit usado.
   - Se a base avançou desde a análise do plano, conferir com `git diff --stat <commit-do-plano> HEAD -- <arquivos do escopo>` se algo relevante mudou.
4. Criar a branch a partir da base, no formato `<n>-<identificador>-<descrição-kebab>`, em que `n` é o número do PR na divisão do plano (ex.: `1-MONV4-58-justification-harden-scope-lock-and-requester`). Sem plano, usar `1`.
5. Confirmar com `git branch --show-current`. Nunca implementar direto na branch base, em `master`/`main` ou em branch de outra tarefa.

Ao terminar a implementação:

- Atualizar a seção "Andamento" do plano com branch, commits, o que foi feito, validações executadas e pendências.
- Ajuste exigido pelo `make ci`/formatador fora do escopo (ex.: arquivo que veio sem formatação da base) vai na mesma branch, em commit próprio, separado do commit da mudança.

## Planejamento

- Para mudanças pequenas e claras, execute diretamente depois de mapear o contexto necessário.
- Alterações restritas a arquivos `__init__.py` podem ser executadas diretamente quando a intenção estiver clara.
- Para mudanças médias, grandes, arriscadas ou com múltiplas alternativas plausíveis, apresente um plano curto antes de editar.
- Se o escopo real parecer maior do que a task inicial indicava, pare e informe o usuário antes de expandir a implementação.

## Regras de implementação

- Preserve os padrões do repositório acima de preferências genéricas.
- Evite duplicar código, helpers, abstrações, constantes, validações ou fluxos já existentes.
- Prefira APIs, serviços, factories, fixtures e utilitários locais já usados pelo projeto.
- Não faça refatorações amplas sem necessidade direta para a task.
- Não altere contratos públicos, schemas, payloads, nomes ou comportamento existente sem necessidade explícita.
- Mantenha mudanças pequenas e fáceis de revisar.
- Adicione docstrings em classes, funções e métodos públicos, complexos ou de domínio criados ou alterados.
- Para métodos simples, privados ou autoexplicativos, siga o padrão local e evite documentação redundante.
- Docstrings devem ser claras e úteis: explique intenção, contrato, comportamento esperado, entradas, saídas, efeitos colaterais ou exceções relevantes.
- Docstrings não devem apenas dizer o óbvio nem repetir linha a linha como o código funciona.
- Se o projeto tiver um padrão claro de documentação diferente de docstrings, siga o padrão local e preserve a intenção de documentação.
- Não introduza dependências novas sem verificar se já existe alternativa no projeto e sem justificar.
- Só crie abstração nova quando houver duplicação real, complexidade recorrente ou padrão equivalente no projeto.

## Convenções de código

- Código, nomes de variáveis, funções, métodos, classes, módulos e arquivos devem estar em inglês.
- Docstrings e comentários devem estar em português brasileiro.
- Testes devem ter docstrings claras em português brasileiro.
- Aplique código limpo: legibilidade, baixo acoplamento, nomes descritivos e responsabilidades claras.
- Use tipagem robusta e moderna em funções e métodos novos ou alterados.
- Evite `Any`, tipos vagos e tipos legados como `Dict` quando houver alternativa moderna e específica.
- Não introduza funções ou métodos sem tipagem, salvo quando o padrão explícito do projeto exigir.
- Prefira recursos modernos da linguagem e evite padrões legados sem necessidade.
- Mantenha uma coisa por função e uma responsabilidade por módulo.
- Evite duplicação de código; extraia lógica compartilhada para função, classe ou módulo quando houver reutilização real.
- Prefira retornos antecipados a `if`s aninhados.
- Mensagens de exceção devem incluir o valor inválido e o formato esperado quando isso ajudar o diagnóstico.

### Imports

- Todos os imports ficam no topo do arquivo, após o docstring de módulo quando houver.
- Nunca coloque imports dentro de funções, métodos ou classes, salvo quando houver importação circular documentada — nesse caso, adicione um comentário curto explicando o ciclo.
- Antes de introduzir um import inline, verifique se o ciclo é real movendo o import para o topo. Só use import local se o ciclo for confirmado.

### Estrutura de arquivos e classes

- Não crie variáveis globais em arquivos que contêm classes. Constantes e conjuntos usados por uma única classe devem ser atributos privados de classe (`_FORBIDDEN = frozenset(...)`), não variáveis soltas no módulo. Variáveis de módulo são aceitáveis apenas em arquivos puramente funcionais sem classes, ou quando são constantes públicas usadas por múltiplos módulos.
- Cada arquivo deve conter no máximo uma classe, salvo quando o arquivo definir apenas classes de tipo (`TypedDict`, `dataclass` usado como estrutura de dados, `Enum`).
- Em arquivos que contêm uma classe, não crie funções ou métodos soltos fora dela; toda lógica deve ser método da classe, método privado ou estar em módulo utilitário separado.

### Heurísticas

- Mantenha funções entre 4 e 20 linhas quando isso preservar clareza.
- Mantenha arquivos abaixo de 500 linhas quando a divisão por responsabilidade for natural.
- Evite mais de 2 níveis de indentação; extraia funções ou use retornos antecipados quando melhorar leitura.
- Prefira nomes específicos e fáceis de pesquisar.
- Evite nomes genéricos como `data`, `handler` e `Manager`, salvo quando forem convenção clara do framework ou do projeto.
- Antes de criar nomes genéricos, verifique usos existentes com `rg` e escolha um nome mais preciso quando o termo aparecer em muitos contextos.

## Contratos e compatibilidade

- Ao alterar API, schema, payload, CLI, evento, job, migration, integração externa ou outro contrato público, identifique callers e testes afetados.
- Pergunte se o usuário quer manter retrocompatibilidade antes de implementar estratégia compatível.
- Se o usuário não quiser retrocompatibilidade, implemente a mudança direta e ajuste os pontos afetados no projeto.

## Controle de escopo

- Prefira mudanças pequenas e coesas, com uma intenção principal por entrega.
- Como referência, tente manter a alteração abaixo de 900 linhas modificadas quando isso for viável.
- Se a task caminhar para mais de 900 linhas modificadas, avalie se a divisão em etapas melhora a revisão.
- Acima de 1.000 linhas modificadas, proponha divisão ou justifique claramente por que a mudança precisa ficar junta.
- Mudanças mecânicas, arquivos gerados, lockfiles, snapshots e renomeações amplas devem ser avaliados separadamente do tamanho do código escrito manualmente.
- Não misture feature, refatoração ampla, formatação, renomeação e atualização de dependências no mesmo trabalho sem necessidade direta.
- Separe refatoração preparatória de mudança comportamental quando isso facilitar revisão e reduzir risco.
- Se a task tiver múltiplas intenções independentes, informe o usuário e proponha uma sequência de entregas antes de expandir o escopo.
- Um bom limite prático é permitir que a revisão entenda motivo, diff e risco em 15 a 30 minutos.

## Testes

- Sempre crie ou atualize testes quando houver mudança de comportamento.
- Use a skill `python-test-generator` para criar ou ampliar testes Python.
- Use a skill `python-test-refactor` quando a task exigir reorganizar, consolidar ou modernizar testes existentes.
- Reutilize factories, fixtures e helpers de teste existentes.
- Se não for viável testar a mudança, explique o motivo e o risco residual.
- Pergunte ao usuário se deve executar os testes relevantes antes de rodá-los.
- Se o usuário preferir executar os testes por conta própria, não rode a suíte e informe quais comandos seriam relevantes.

## Validação

Antes de entregar:
1. Revise o diff para remover mudanças acidentais.
2. Verifique se a implementação segue a nomenclatura e arquitetura locais.
3. Verifique se não há código morto, duplicado ou temporário.
4. Confirme que testes foram adicionados ou atualizados quando aplicável.
5. Pergunte antes de executar testes, lint, typecheck ou build, salvo pedido explícito do usuário.
6. Não afirme que algo foi testado se o comando não foi executado.

## Resposta final

Ao finalizar, informe de forma objetiva:
- branch criada e commit base usado;
- arquivos principais alterados;
- comportamento implementado;
- testes ou validações executadas;
- qualquer limitação, risco residual ou validação não executada.
