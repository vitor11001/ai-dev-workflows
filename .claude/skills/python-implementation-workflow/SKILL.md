---
name: python-implementation-workflow
description: executa tarefas de programação Python ponta a ponta como workflow de engenharia senior. use quando o usuário pedir para implementar, alterar, corrigir, refatorar ou evoluir código em projetos Python, incluindo mapeamento inicial, preservação de padrões, implementação, testes e validação.
---

# Workflow de Implementação (Python)

## Objetivo

Executar tarefas de programação Python de ponta a ponta com mudanças pequenas,
consistentes com o projeto e validadas por testes efetivamente executados.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "implemente essa feature"
- "corrija esse bug"
- "altere esse comportamento"
- "refatore esse fluxo"
- "adicione suporte para..."
- "faça essa task"

## Fase 1 — Mapear

1. Entenda a task e identifique requisitos explícitos, implícitos e ambiguidades.
2. Leia as instruções locais antes de qualquer coisa: `AGENTS.md`, `CLAUDE.md`,
   `README.md`, `docs/` e o que estiver no diretório em que vai mexer.
3. **Procure um plano existente** em `tmp/planning/<issue>/`. Se houver, ele é a
   fonte das decisões já fechadas — leia antes de formar opinião própria sobre a
   solução.
4. **Descubra a versão do Python e o ferramental** em `pyproject.toml`,
   `mise.toml`, `.python-version`, `.pre-commit-config.yaml`, `Makefile`,
   `tox.ini`, `noxfile.py` ou `justfile`: formatador, linter, type checker,
   gerenciador de dependência e como rodar os testes.
5. Mapeie estrutura, pontos de entrada, testes e arquivos relacionados.
6. Localize código existente que já resolva parte do problema antes de criar
   código novo.
7. Identifique os padrões locais de nomenclatura, organização, imports, erros,
   logging e testes.
8. Pergunte apenas quando a ambiguidade puder levar a uma implementação errada ou
   arriscada. Nunca pergunte por informação que pode ser descoberta lendo o projeto.

## Fase 2 — Planejar

**Se existe plano em `tmp/planning/`, ele substitui esta fase.** Não replaneje o
que já foi decidido: as decisões do plano valem como fechadas, e refazê-las gera
implementação divergente do que foi combinado. Se você discordar de algo,
**diga antes de desviar** — nunca implemente diferente em silêncio.

Sem plano prévio:

- Mudanças pequenas e claras: execute direto após mapear o contexto.
- Alterações restritas a `__init__.py` com intenção clara: execute direto.
- Mudanças médias, grandes, arriscadas ou com múltiplas alternativas plausíveis:
  apresente um plano curto antes de editar.
- Se o escopo real parecer maior do que a task indicava, pare e informe o usuário
  antes de expandir.

## Fase 3 — Implementar

Implemente a menor mudança coerente com o comportamento pedido.

### Regras

- Preserve os padrões do repositório acima de qualquer preferência desta skill.
- Use a skill `django-layered-architecture` para decidir em qual camada o código
  novo deve morar em projetos Django/DRF.
- Não duplique código, helpers, abstrações, constantes, validações ou fluxos já
  existentes; prefira APIs, services, factories e utilitários locais.
- Só crie abstração nova diante de duplicação real, complexidade recorrente ou
  padrão equivalente já presente no projeto.
- Não faça refatoração ampla sem necessidade direta para a task.

### Versão da linguagem e das bibliotecas

- **Sintaxe que você não reconhece pode ser recurso novo, não erro.** Antes de
  "corrigir", confirme na versão que o projeto declara.
- Exemplo real: a partir do Python 3.14 ([PEP 758](https://peps.python.org/pep-0758/)),
  `except ValueError, TypeError:` sem cláusula `as` dispensa parênteses.
  Reintroduzi-los quebra o padrão do projeto — e o formatador desfaz na execução
  seguinte.
- Não use recurso mais novo que a versão suportada pelo projeto.
- O mesmo vale para bibliotecas: **confirme que o método, o parâmetro e o
  comportamento existem na versão instalada** antes de usar. Leia a assinatura no
  código da dependência ou na doc daquela versão — não escreva de memória.
- Assinatura que você "lembra" de uma versão diferente falha em runtime ou, pior,
  é aceita e ignorada.

### Tipagem

- Anote toda função e método novo ou alterado, incluindo o tipo de retorno.
- Sintaxe moderna: `X | None` em vez de `Optional[X]`, `list[str]` e
  `dict[str, int]` em vez de `List`/`Dict`, `Self` em vez do nome da própria classe.
- No lugar de `Any`, escolha o que descreve o contrato: `Protocol` para contrato
  estrutural, `TypedDict` para dicionário de forma conhecida, generics para
  container, união explícita para alternativas.
- `Any` só quando o valor é genuinamente dinâmico — e com comentário dizendo por quê.

### Exceções

- Ao relançar dentro de um `except`, **encadeie**: `raise DomainValidationError(...) from exc`.
  Sem o `from`, a causa original desaparece do traceback e o diagnóstico se perde.
- Use a hierarquia de exceção do projeto. Crie exceção nova apenas quando o chamador
  precisar distinguir aquele caso.
- Nunca `except:` nu, nem `except Exception` amplo sem relançar ou registrar.
- A mensagem cita o valor inválido e o formato esperado.

### Segurança

- Segredo vem do ambiente ou do cofre do projeto, **nunca do código** — nem em
  default, nem em teste, nem em comentário.
- Nunca `eval`, `exec` ou `pickle.loads` sobre dado que veio de fora.
- Ao montar consulta, comando ou caminho a partir de entrada externa, parametrize
  ou valide contra uma lista fechada. Não concatene.

### Transações e efeitos colaterais

- Envolva em `transaction.atomic()` a escrita que precisa ser tudo ou nada.
- **Nunca dispare task, e-mail, webhook ou qualquer efeito externo de dentro de um
  `atomic()`.** Use `transaction.on_commit(...)`. O worker pode pegar a task antes
  do commit, não encontrar o registro e falhar de forma intermitente — o bug mais
  caro de diagnosticar nessa combinação.
- `select_for_update()` quando duas execuções concorrentes puderem ler e escrever o
  mesmo registro. Só funciona dentro de `atomic()`.
- Efeito colateral idempotente sempre que o fluxo permitir: `on_commit` não garante
  execução única se o processo cair no meio.

### Convenções

- Código, variáveis, funções, métodos, classes, módulos e arquivos em inglês.
- Docstrings e comentários em português brasileiro, incluindo nos testes.
- Uma responsabilidade por função, uma por módulo.
- Prefira retornos antecipados a `if`s aninhados; evite passar de 2 níveis de
  indentação.
- Prefira nomes específicos e fáceis de pesquisar. Antes de usar um nome genérico
  como `data`, `handler` ou `Manager`, procure com `rg` e escolha algo mais preciso.
- Funções entre 4 e 20 linhas e arquivos abaixo de 500 linhas, quando a divisão
  for natural e preservar clareza.

Imports, estrutura de arquivos e classes, docstrings, idiomas modernos e
dependências: ver `references/python-conventions.md`.

Em projetos Django — controllers com Pydantic, ORM e performance, migrations,
Celery, signals, logs e settings: ver `references/django-conventions.md`.

## Fase 4 — Testar

- Toda mudança de comportamento cria ou atualiza teste. Sem exceção.
- Use a skill `django-tests` para criar, ampliar ou refatorar testes em projetos Django.
- Reutilize factories, fixtures e helpers de teste já existentes.
- **Execute os testes do que você alterou, sem pedir permissão.** Rodar teste é
  barato e reversível; entregar sem validar, não.
- Peça confirmação apenas para comando destrutivo ou de efeito externo: migration
  contra banco real, deploy, publicação, escrita em serviço de terceiro.
- Se não for viável testar a mudança, diga o motivo e o risco residual.

## Fase 5 — Validar e reportar

- **Rode o formatador, o linter e o type checker do projeto**, com a configuração
  dele e pelos alvos que ele expõe. Não formate à mão: o formatador desfaz na
  execução seguinte e a mudança manual só gera ruído no diff.
- Revise o diff e remova mudança acidental, código morto, duplicado ou temporário.
- Confirme que a implementação segue a nomenclatura e a arquitetura locais.
- Confirme que os testes foram criados ou atualizados, e que passaram — lendo a
  saída, não presumindo.
- **Divergiu do plano?** Registre em `tmp/planning/<issue>/AAAA-MM-DD-desvios.md`:
  o que o plano dizia, o que foi feito e por quê. Não edite o plano original — ele
  é o registro do que foi combinado. O desvio é informação nova, e é o que alguém
  vai querer entender daqui a três meses.

Na resposta final, informe:
- arquivos principais alterados;
- comportamento implementado;
- comandos executados e seu resultado real;
- limitação, risco residual ou validação não executada.

**Nunca afirme que algo foi testado, passou ou funciona sem ter executado o comando
e lido a saída.** Se um teste falhou, diga que falhou e mostre o erro.

## Atalhos proibidos

Quando algo fica vermelho, a saída é entender — não silenciar.

- **Nunca altere um teste para o código passar.** Se o teste falhou, ou o código
  está errado, ou o contrato mudou de propósito. No segundo caso, diga ao usuário
  antes de mexer no teste.
- Não remova asserção, não afrouxe comparação e não troque valor esperado para
  fechar a conta.
- `# type: ignore`, `# noqa` e `skip` são último recurso: use o código específico
  (`# type: ignore[arg-type]`, `# noqa: E501`) e comente por que a supressão é
  legítima. Supressão ampla e sem comentário é proibida.
- Não aumente timeout, não adicione `sleep` e não marque teste como flaky para
  contornar comportamento que você não entendeu.
- Se você não consegue resolver sem um desses atalhos, isso é sinal de parar e
  reportar — ver "Quando parar".

## Correção de bugs

Antes de editar código:
1. Reproduza o problema com exemplo concreto, caso de teste ou sequência de passos.
2. Identifique a causa raiz, não o sintoma.
3. Verifique se deveria existir teste cobrindo o caso — a ausência costuma ser
   parte do bug.
4. Corrija a causa raiz; não adicione condição protetora para contornar sem
   entender a origem.
5. Adicione o teste de regressão que teria pego a falha.

## Contratos e compatibilidade

- Ao alterar API, schema, payload, CLI, evento, job, migration ou integração
  externa, identifique callers e testes afetados antes de mudar.
- Pergunte se o usuário quer retrocompatibilidade antes de implementar estratégia
  compatível; se não quiser, faça a mudança direta e ajuste os pontos afetados.
- Destaque toda breaking change na resposta final.

## Controle de escopo

- Uma intenção principal por entrega. Não misture feature, refatoração ampla,
  formatação, renomeação e atualização de dependência no mesmo trabalho.
- O alvo é uma revisão que entenda motivo, diff e risco em 15 a 30 minutos. Se a
  mudança passar disso, proponha dividir em etapas ou justifique por que precisa
  ficar junta.
- Avalie à parte mudança mecânica, arquivo gerado, lockfile e renomeação ampla:
  inflam o diff sem inflar o risco.

### Código adjacente com problema

Ao encontrar bug, violação de padrão ou dívida **fora do escopo da task**:

- **Reporte, não corrija em silêncio.** Descreva o que viu, onde, e por que é
  problema — deixe a decisão de corrigir com o usuário.
- Corrija junto apenas se for pré-requisito real para a task, e diga que fez isso.
- A exceção é risco imediato — segredo exposto, perda de dado, falha de segurança:
  avise antes de qualquer outra coisa.
- Não deixe passar em silêncio só porque está fora do escopo. Achado não relatado
  é achado perdido.

## Quando parar

Pare e reporte ao usuário, em vez de continuar tentando, quando:

- a mesma correção falhar 3 vezes seguidas — descreva o que tentou, o que observou
  e qual hipótese caiu;
- o teste continuar vermelho e você não souber explicar por quê;
- a abordagem se revelar errada no meio da implementação — não empilhe remendo
  sobre a base errada;
- a task exigir decisão de produto, de contrato ou de prioridade;
- a mudança exigir credencial, acesso ou informação que você não tem.

Relatar bloqueio cedo custa menos que entregar algo que não funciona. Ao parar,
diga o que já está feito, o que falta e qual decisão você precisa.
