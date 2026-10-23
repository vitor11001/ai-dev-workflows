---
name: investigate
description: investiga uma demanda no código antes de decidir o que fazer com ela — bug, hotfix, feature nova, melhoria ou débito técnico — e registra o estado atual, o mapa do código e as hipóteses em tmp/tasks/<ID>/. use quando o usuário pedir para investigar, entender, analisar ou levantar o contexto de um problema, de uma funcionalidade nova ou de uma issue existente do Plane. é a base da plane-issue (redigir a issue) e da implementation-plan (planejar a implementação); não redige issue nem planeja solução.
---

# Investigação de Demanda

## Objetivo

Registrar o que a demanda é e como o código está hoje, com evidência, antes de qualquer decisão de issue ou de implementação. A investigação responde "o que existe e onde"; a `plane-issue` responde "o que pedir" e a `implementation-plan` responde "como fazer".

## Quando usar

- "investiga esse bug" / "por que isso acontece?"
- "quero implementar X; o que já existe?"
- "analisa a issue PROJ-123 antes de começarmos"
- Chamada pela `plane-issue` ou pela `implementation-plan` quando a pasta da task ainda não tem investigação.

Não use para corrigir: corrigir é da `python-implementation-workflow`, que começa desta investigação quando ela existe.

## Fluxo

1. Resolver o identificador e a pasta da task (ver "Pasta da task"). Se a pasta já existir, ler o `0-sumario.md` e os arquivos dela antes de qualquer coisa e continuar de onde parou.
2. Registrar a linha de início no sumário (ver "Sumário").
3. Classificar o tipo da demanda (ver "Tipos"). Na dúvida entre dois tipos, perguntar.
4. Se a demanda for uma issue que já existe no Plane, copiá-la para a pasta (ver "Issue existente").
5. Registrar a base analisada: branch e commit (`git log --oneline -1 origin/<base>`).
6. Investigar com o roteiro do tipo e montar o mapa do código atual.
7. Separar fatos (com `arquivo:linha`) de hipóteses. Perguntar ao usuário só o que bloqueia a investigação (ex.: como reproduzir, qual ambiente) e que o código não responde.
8. Gravar `N-investigacao.md`, atualizar o cabeçalho e registrar a linha de conclusão no sumário.

## Pasta da task

Toda task mora em `tmp/tasks/<identificador>/`, na raiz do repositório em que ela será resolvida. Esta skill é dona destas regras; as demais skills seguem o mesmo contrato.

### Identificador

- Issue existente no Plane: o ID exatamente como no Plane (ex.: `PROJ-123`). Confirmar com o usuário quando o ID vier só inferido do nome da branch.
- Demanda sem issue no Plane: `LOCAL-<slug>`, com `slug` de 2 a 5 palavras em kebab-case descrevendo a demanda (ex.: `LOCAL-frete-gratis-acima-500`). Antes de criar, conferir com `ls tmp/tasks/` que o identificador não está em uso.
- Quando a task local ganhar ID no Plane (pela `plane-issue` ou informado pelo usuário): renomear a pasta para o ID, registrar `Identificador anterior: LOCAL-<slug>` no cabeçalho do sumário e manter o nome das branches já criadas; as próximas usam o ID.

### Arquivos

Todo arquivo começa com número e hífen, na ordem de criação; o nome diz o papel. Ao criar arquivo novo, continuar a numeração; nunca renumerar. As skills encontram os arquivos **pelo nome**, nunca pelo número:

| Arquivo | Escrito por |
|---|---|
| `0-sumario.md` | todas as skills que tocam a pasta (sempre o primeiro) |
| `N-investigacao.md` | `investigate` |
| `N-issue-original.md` | `plane-issue` (texto redigido) ou `investigate` (cópia da issue do Plane) |
| `N-plano-implementacao.md` | `implementation-plan` |
| `N-exemplo-<assunto>.md` | `implementation-plan`, para apoiar uma decisão |
| `N-code-review-pr-<n>.md` | `code-review` |
| `N-pr-<n>-body.md` | `pr-description` |

### Pasta antiga em `tmp/plans/`

Se existir `tmp/plans/<identificador>/` e não existir `tmp/tasks/<identificador>/`, propor ao usuário mover a pasta. Ao mover, criar o `0-sumario.md` com uma linha por arquivo existente, datada pelo `stat` do arquivo e marcada como `(data reconstruída)`. Pastas antigas usam `1-issue-original.md` e `2-plano-implementacao.md`, que continuam válidos pelo nome.

## Sumário

`0-sumario.md` é o histórico da task: um cabeçalho de estado e uma tabela append-only com uma linha por execução de skill.

```md
# PROJ-123 — Frete grátis acima de R$ 500

> Tipo: feature · Status: planejada · Plane: publicado (https://app.plane.so/<workspace>/browse/PROJ-123/) · Identificador anterior: LOCAL-frete-gratis-acima-500

| Data e hora | Skill | O que fez | Arquivo |
|---|---|---|---|
| 2026-10-18 14:02 -03 | investigate | investigação iniciada, base `develop` @ `a1b2c3d` | `1-investigacao.md` |
| 2026-10-18 14:40 -03 | plane-issue | issue redigida e publicada como PROJ-123 | `2-issue-original.md` |
| 2026-10-18 15:10 -03 | implementation-plan | plano criado, 2 PRs | `3-plano-implementacao.md` |
```

- A data vem de `date '+%Y-%m-%d %H:%M %Z'`, executado na hora; nunca estimada de memória.
- Uma linha por execução, em uma frase; o detalhe fica no arquivo da etapa. Linhas antigas nunca são editadas nem removidas.
- Cabeçalho, atualizado por quem mudar o estado:
  - **Tipo:** `bug`, `hotfix`, `feature`, `melhoria` ou `débito`.
  - **Status:** `investigando`, `investigada`, `issue redigida`, `publicada`, `planejada`, `em implementação`, `em review`, `concluída` ou `descartada`.
  - **Plane:** `não publicado`, `publicado (<link>)` ou `existente (<link>)`.

## Tipos

| Tipo | Quando | Roteiro da investigação |
|---|---|---|
| `bug` | comportamento existente está errado | como reproduzir; onde o comportamento vive; causa raiz provável; impacto e quem é afetado; por que os testes atuais não pegaram |
| `hotfix` | bug em produção que precisa de correção urgente | o roteiro de `bug`, mais: urgência, mitigação imediata possível sem deploy e a menor correção segura |
| `feature` | comportamento que ainda não existe | o que já existe para reaproveitar; onde a funcionalidade se encaixa (pontos de extensão); padrões locais a seguir; dependências; restrições de permissão, contrato e dados; perguntas de produto em aberto |
| `melhoria` | comportamento existente funciona, mas deve mudar | comportamento atual e desejado; quem é afetado; o que muda de contrato (API, relatório, tela) e quem consome |
| `débito` | dívida técnica sem mudança de comportamento | onde está e quanto se espalhou; risco de manter; risco de mexer; testes que protegem a mudança |

## Investigação no código

Para todos os tipos:

- Ler as instruções locais (`AGENTS.md`, `CLAUDE.md`, `docs/`) da área envolvida.
- Buscar com `rg` pelos termos do conceito — nome do campo, rótulo, constante, mensagem de erro, rota —, não só pelo nome da função; a mesma regra costuma estar repetida em serializer, service, model e job.
- Ler inteiros os arquivos centrais da demanda; nos vizinhos (callers, testes, consumidores), só o trecho relevante.
- Levantar as restrições e permissões que já existem no fluxo, os testes que já cobrem parte dele e se a demanda já foi resolvida em parte em outro lugar.
- Não afirmar que endpoint, model, teste ou job existe sem ter encontrado.
- Não editar código: investigação é só leitura.

### Mapa do código atual

Toda investigação de tamanho médio ou maior (mais de um módulo, regra repetida, dado persistido ou contrato exposto) registra onde o conceito vive hoje:

```md
| Ponto | Onde | Papel |
|---|---|---|
| Regra de frete | `shipping/services/freight.py:42` | define |
| Regra de frete | `orders/serializers.py:88` | duplica |
| `calculate_freight` | `checkout/views.py:120`, `tasks/recalc.py:30` | chama |
| `Order.freight` | migration `0042` | persiste |
| `GET /orders/{id}` | `orders/views.py:55` | expõe |
```

- Papéis: `define`, `duplica`, `chama`, `testa`, `persiste`, `expõe` (API, schema, evento, relatório).
- Registrar implementações irmãs da mesma regra: elas são as candidatas a divergir.
- Incluir o que a mudança vai precisar respeitar: dados gravados, migrations aplicadas, consumidores da API, jobs agendados.
- O mapa descreve o estado atual; a coluna "Efeito da mudança" é acrescentada pela `implementation-plan`.

### Trabalho paralelo e falsos positivos

- Procurar trabalho ainda não integrado nos mesmos arquivos: `git log --oneline --all -- <arquivos>` e `git branch -a --contains <commit>`. Registrar por que importa (conflito provável, regra que o fluxo novo precisaria repetir).
- Registrar falsos positivos que uma busca por nome traria (mesmo nome de campo em outro domínio), para ninguém alterá-los por engano.

## Issue existente

Quando a demanda já for uma issue no Plane:

1. Copiar a issue para `N-issue-original.md`. Com a configuração do Plane disponível, usar o script da skill `plane-issue` (`scripts/plane.py get <ID>`, resolvido a partir do diretório daquela skill); sem ela, pedir ao usuário para colar o texto.
2. Montar a tabela `Premissa da issue | Estado atual | Onde (arquivo:linha)` para cada afirmação da issue que dependa do código.
3. Concluir explicitamente: a issue continua válida, está parcialmente resolvida ou está obsoleta.
4. Registrar problemas encontrados que a issue não menciona, separando o que cabe nela do que vira outra task.

## Arquivo da investigação

```md
# <identificador> — Investigação

> Tipo: <tipo> · Base: `<branch>` @ `<commit>` · Data: <data>

## Demanda
<o que foi pedido, nas palavras do usuário ou da issue>

## Estado atual
<como o sistema se comporta hoje, com `arquivo:linha`>

## <seções do roteiro do tipo>

## Mapa do código atual

## Trabalho paralelo

## Fatos e hipóteses
| Afirmação | Fato ou hipótese | Evidência |
|---|---|---|

## Perguntas em aberto
```

Omitir seção vazia. Hipótese nunca aparece como fato: se não foi possível confirmar, diga como confirmar.

## Investigação desatualizada

Quando outra skill encontrar uma investigação existente, ela confere a defasagem antes de usá-la: `git diff --stat <commit-da-investigação> HEAD -- <arquivos do mapa>`. Se algum arquivo do mapa mudou, reler esses arquivos, atualizar a investigação e registrar a atualização no sumário.

## Resposta final

Entregue em tabelas Markdown, com uma frase de resumo antes e a recomendação de próximo passo depois (normalmente `plane-issue` ou `implementation-plan`):

| Item | Detalhe |
|---|---|
| Task | `tmp/tasks/<identificador>/`, tipo `<tipo>` |
| Base | `<branch>` @ `<commit>` |
| Conclusão | causa provável, encaixe da feature ou validade da issue, em uma frase |
| Hipóteses abertas | o que não foi confirmado e como confirmar |

Depois, o mapa do código atual quando existir. Não cole a investigação inteira, salvo pedido.

## Critérios de revisão

1. A pasta e o sumário seguem "Pasta da task" e "Sumário", com datas vindas do comando `date`?
2. O tipo foi classificado e o roteiro dele foi seguido?
3. Toda afirmação sobre o código tem `arquivo:linha`, e toda hipótese está marcada como hipótese?
4. O mapa cobre as ocorrências do conceito, inclusive as duplicadas, persistidas e expostas?
5. Nenhum código foi editado e nenhuma solução foi desenhada?
