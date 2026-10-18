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
8. Crie ou atualize testes para toda mudança comportamental; em bug ou regra de negócio nova, siga o "Ciclo TDD".
9. Execute testes conforme "Execução de testes".
10. Reporte claramente o que foi ou não foi executado.

## Correção de bugs

Quando a task for corrigir um bug, execute estas etapas antes de editar código de produção:

1. Reproduza o problema: confirme o comportamento incorreto com um exemplo concreto, caso de teste ou sequência de passos. Se a investigação da task já registra a reprodução, confirme que ela ainda vale em vez de refazer.
2. Identifique a causa raiz, não o sintoma: entenda por que o bug acontece antes de propor correção. Parta da causa provável da investigação, quando existir, e confirme-a no código.
3. Escreva o teste que reproduz o bug, rode e confirme que ele falha pelo motivo esperado (RED do "Ciclo TDD"); a ausência desse teste frequentemente é parte do bug.
4. Corrija a causa raiz; evite adicionar condição protetora ou contornar o problema sem entender a origem.
5. Rode o teste de novo e confirme que passa.

## Ciclo TDD

Para bug ou regra de negócio nova (validação, cálculo, permissão, transição de estado), trabalhe um comportamento por vez:

1. Pegue o próximo comportamento de "Testes necessários" do plano, na ordem listada. Sem plano, derive a lista da task, do caso principal para as bordas.
2. RED: escreva um teste só para esse comportamento e rode. Ele deve falhar pelo motivo esperado (assert sobre o comportamento ausente). Falha por import, fixture, setup ou erro de sintaxe não conta: corrija o teste e rode de novo.
3. GREEN: implemente o mínimo para o teste passar e rode.
4. REFACTOR: melhore nomes, duplicação e estrutura sem mudar comportamento; rode os testes do arquivo.
5. Repita até cobrir a lista. Se um ciclo revelar ambiguidade de regra (ex.: `>` ou `>=`), pare e pergunte em vez de escolher.

Fora do ciclo:

- Refatoração sem mudança de comportamento: rode os testes existentes do módulo antes e depois.
- Migration, settings e configuração: valide com o comando próprio (ex.: `makemigrations --check`).
- Exploração de alternativa ou biblioteca: protótipo descartável primeiro; o código definitivo volta ao ciclo.

## Branch e pasta da task

### Pasta da task

- A task mora em `tmp/tasks/<ID>/`; as regras completas (identificador, `LOCAL-<slug>`, arquivos, pasta antiga) estão na skill `investigate`.
- Encontre os arquivos pelo nome (`*-investigacao.md`, `*-issue-original.md`, `*-plano-implementacao.md`), nunca pelo número; ao criar arquivo, continue a numeração.
- Ao rodar, registre uma linha no `0-sumario.md` com a data de `date '+%Y-%m-%d %H:%M %Z'`: `| <data> | <skill> | <o que fez> | <arquivo> |`. Atualize o cabeçalho quando Status ou Plane mudarem.
- Pasta antiga em `tmp/plans/<ID>/`: siga "Pasta antiga em `tmp/plans/`" da skill `investigate`.

### Antes de editar qualquer arquivo

1. Identificar a task: ID do Plane (ex.: `PROJ-123`) ou identificador local (`LOCAL-<slug>`). Se a pasta não existir, criar `tmp/tasks/LOCAL-<slug>/` só com o `0-sumario.md` (tipo e Status `em implementação`), para que a task pequena feita direto também tenha histórico; investigação e plano não são obrigatórios.
2. Ler o `0-sumario.md` e os arquivos da pasta: investigação, issue e plano. As decisões do plano prevalecem sobre a issue; divergência entre plano e pedido atual deve ser apontada ao usuário antes de implementar.
3. Atualizar a branch base do projeto (normalmente `develop`) com `git fetch` e fast-forward.
   - Se o acesso ao remoto falhar, avançar a base local até o último `origin/<base>` já baixado (`git merge --ff-only origin/<base>`), informar a falha ao usuário e registrar o commit usado.
   - Se a base avançou desde a análise do plano, conferir com `git diff --stat <commit-do-plano> HEAD -- <arquivos do escopo>` se algo relevante mudou.
4. Criar a branch a partir da base, no formato `<n>-<identificador>-<descrição-kebab>`, em que `n` é o número do PR na divisão do plano (ex.: `1-PROJ-123-freight-free-shipping-threshold`). Sem plano, usar `1`.
5. Confirmar com `git branch --show-current`. Nunca implementar direto na branch base, em `master`/`main` ou em branch de outra tarefa.

Ao terminar a implementação:

- Registrar no sumário uma linha ao iniciar e outra ao concluir cada PR (Status `em implementação`), com a branch.
- Atualizar a seção "Andamento" do plano com branch, commits, o que foi feito, validações executadas e pendências.
- Registrar a evidência de cada ciclo TDD em uma linha, sem colar a saída do `pytest`: `<comportamento>: RED <comando> → falhou (<motivo>); GREEN passou`.
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
- Use a skill `python-tests` para escrever testes: modo criar para criar ou ampliar, modo refatorar quando a task exigir reorganizar, consolidar ou modernizar testes existentes.
- Reutilize factories, fixtures e helpers de teste existentes.
- Se não for viável testar a mudança, explique o motivo e o risco residual.

## Execução de testes

- Rode sem perguntar os testes focados: arquivos de teste dos módulos tocados (`pytest <arquivo>` ou `-k <nome>`).
- Pergunte antes de rodar a suíte completa, `make ci`, lint ou typecheck do projeto inteiro e build.
- Se o teste focado falhar por infraestrutura (banco, Docker, variável de ambiente), pare e informe; não suba serviços por conta própria.
- Se o usuário preferir executar os testes por conta própria, não rode e informe quais comandos seriam relevantes.

## Validação

Antes de entregar:
1. Revise o diff para remover mudanças acidentais.
2. Verifique se a implementação segue a nomenclatura e arquitetura locais.
3. Verifique se não há código morto, duplicado ou temporário.
4. Confirme que testes foram adicionados ou atualizados quando aplicável e que cada ciclo TDD teve RED e GREEN executados.
5. Rode os testes focados dos módulos tocados; para validações amplas, siga "Execução de testes".
6. Não afirme que algo foi testado se o comando não foi executado.

## Resposta final

Entregue a resposta final em tabelas Markdown. Texto fora das tabelas só para uma frase de resumo no início e a recomendação de próximo passo no fim.

**Entrega** — uma linha por item; omitir a que não se aplicar:

| Item | Detalhe |
|---|---|
| Branch | `1-PROJ-123-freight-free-shipping-threshold`, criada de `develop` @ `a1b2c3d` |
| Comportamento | o que passou a funcionar, em uma frase |
| Limitações e riscos | risco residual, decisão pendente ou validação não executada |

**Arquivos alterados** — os principais, sem listar arquivos gerados:

| Arquivo | Mudança |
|---|---|
| `shipping/services/freight.py` | frete zero acima de R$ 500 |

**Verificação** — um comando por linha, com o resultado real; ciclos TDD entram com RED e GREEN:

| Comando | Resultado |
|---|---|
| `pytest tests/unit/shipping/test_freight_calculator.py` | RED: falhou (frete 25.00 ≠ 0); GREEN: 3 passaram |
| `make ci` | não executado; perguntar antes de rodar |

Quando a skill `python-tests` também tiver sido usada, não repita as tabelas dela: os testes entram na tabela de verificação.
