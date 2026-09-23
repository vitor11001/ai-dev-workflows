---
name: task-planner
description: Planejamento técnico de tasks, issues, PRs e branches em Markdown. Use quando o usuário quiser transformar uma task/revisão/conversa em plano de implementação, dividir trabalho em PRs, atualizar escopo após review, criar checklist para outra LLM implementar, registrar decisões e perguntas pendentes, ou salvar/atualizar arquivos .md de planejamento.
---

# Task Planner

## Objetivo

Planejar tasks técnicas de forma implementável, mantendo escopo, decisões, perguntas, arquivos prováveis, testes e critérios de pronto em Markdown. Priorizar clareza para humanos e para outra LLM executar depois.

## Fluxo principal

1. Entender a fonte da demanda: task, issue, review, branch atual, PR futuro, conversa ou arquivo existente.
2. Resolver o identificador da issue e a pasta do plano (ver "Pasta da issue"). Se a pasta já existir, ler os arquivos dela antes de qualquer coisa e continuar de onde parou.
3. Na primeira criação do plano, registrar a data e hora de início (ver "Registro de início").
4. Investigar o repositório quando o plano depender do código atual. Usar `rg`, `git diff`, `git status`, `sed` e testes existentes para ancorar decisões.
5. Quando a demanda vier de uma issue existente, verificar se ela ainda é válida contra o código atual e procurar trabalho paralelo (ver "Validade da issue").
6. Separar claramente:
   - ajustes da branch/PR atual;
   - próximos PRs/branches;
   - fora de escopo.
7. Criar ou atualizar os arquivos na pasta da issue, salvo se o usuário indicar outro caminho.
8. Registrar decisões tomadas e perguntas pendentes. Quando o usuário responder, atualizar o arquivo e reduzir a lista de pendências.
9. Quando houver dúvida, propor uma recomendação técnica antes de perguntar. Explicar o motivo em linguagem humana e mostrar um exemplo concreto (ver "Perguntas progressivas").
10. Encerrar quando o documento tiver decisões suficientes para implementação sem adivinhação perigosa.
11. Durante a implementação, manter a seção "Andamento" atualizada a cada PR.

## Pasta da issue

Todo plano mora em `tmp/plans/<identificador>/`, na raiz do repositório em que a issue será implementada.

### Identificador

- Issue existente no Plane: usar o ID dela, exatamente como no Plane (ex.: `MONV4-58`).
- Confirmar o ID com o usuário quando ele não tiver sido informado explicitamente ou vier só inferido do nome da branch.
- Issue que não existe no Plane: usar `LOCAL-<slug>`, com `slug` de 2 a 5 palavras em kebab-case descrevendo o problema (ex.: `LOCAL-escopo-justificativa-alertas`). Antes de criar, conferir com `ls tmp/plans/` que o identificador não está em uso.
- Quando a issue local ganhar ID no Plane:
  - renomear a pasta para o ID;
  - registrar no cabeçalho do plano `Identificador anterior: LOCAL-<slug>`;
  - branches já criadas mantêm o nome; as próximas usam o ID.

### Arquivos numerados

Todo arquivo da pasta começa com número e hífen, na ordem de leitura: `1-...`, `2-...`, `3-...`. Ao criar um arquivo novo, continuar a numeração existente; nunca renumerar arquivos antigos.

Conjunto padrão:

- `1-issue-original.md`: cópia da issue como estava quando o planejamento começou, para consulta offline. Para issue local, a descrição do problema como o usuário a trouxe.
- `2-plano-implementacao.md`: análise, decisões, divisão em PRs, pendências e andamento. É o arquivo principal; onde divergir da issue, ele prevalece.
- `N-exemplo-<assunto>.md`: apoio visual a uma decisão (tabelas de antes/depois, payloads, telas de relatório). Criar quando a pergunta ficar difícil de entender só com texto.
- Outros apoios seguem a mesma numeração (ex.: `N-pr-<n>-body.md`, criado pela skill `pr-description`).

### Branches

As branches de implementação seguem `<n>-<identificador>-<descrição-kebab>`, em que `n` é o número do PR na divisão do plano (ex.: `1-MONV4-58-justification-harden-scope-lock-and-requester`). Registrar a branch de cada PR na seção "Andamento".

## Registro de início

Na primeira vez que o plano for criado, obter a data e hora reais com `date '+%Y-%m-%d %H:%M %Z'` e gravá-las no cabeçalho de `2-plano-implementacao.md`:

```md
> Início: 2026-09-23 10:31 -03
```

- Não estimar a hora de memória; usar o comando.
- Nunca sobrescrever o início em atualizações posteriores. Datas de decisões e de PRs vão nas seções próprias.
- Se o plano já existir sem início registrado, perguntar ao usuário ou usar a data de criação do arquivo mais antigo da pasta (`stat`), deixando escrito de onde veio.

## Validade da issue

Quando a demanda for uma issue já escrita (principalmente se estiver aberta há algum tempo):

1. Registrar a base analisada: branch e commit (`git log --oneline -1 origin/<base>`).
2. Montar uma tabela `Premissa da issue | Estado atual | Onde (arquivo:linha)` para cada afirmação da issue que dependa do código.
3. Concluir explicitamente: a issue continua válida, está parcialmente resolvida ou está obsoleta.
4. Registrar problemas encontrados na análise que a issue não menciona, separando o que entra no escopo do que vira issue própria.
5. Procurar trabalho paralelo ainda não integrado que toque os mesmos arquivos: `git log --oneline --all -- <arquivos>` e `git branch -a --contains <commit>`. Explicar por que importa (regra que o fluxo novo precisaria repetir, conflito provável) e registrar o encaminhamento.
6. Registrar falsos positivos que uma busca por nome traria (mesmo nome de campo em outro domínio), para ninguém alterá-los por engano.

## Estilo do documento

Usar seções úteis e diretas. Preferir esta estrutura, adaptando ao caso:

```md
# <identificador> — <título>

> Início: <AAAA-MM-DD HH:MM TZ>
> Texto original: `1-issue-original.md`. Onde este arquivo divergir da issue, este prevalece.

## Objetivo
## Base / Premissas
## Fora de escopo
## Decisões já fechadas
## Contrato final
## Fluxos esperados
## Desenho de implementação recomendado
## Arquivos prováveis a alterar
## Testes necessários
## Ordem de implementação sugerida
## Cuidados importantes
## Comandos de verificação
## Critérios de pronto
## Divisão em PRs
## Perguntas pendentes
## Andamento
```

Para documentos de branch atual, detalhar mais:

- o que deve ser removido;
- o que deve ser reaproveitado;
- quais endpoints/contratos ficam intactos;
- quais nomes/vocabulários devem mudar;
- quais testes apagar, renomear, criar ou adaptar.

Para documentos de PR futuro, detalhar mais:

- dependência/rebase sobre PR anterior;
- contrato final esperado;
- payloads de entrada;
- respostas esperadas;
- camada de view, serializer, controller/serviço;
- validações e transações;
- rollback;
- auditoria;
- testes por camada.

## Perguntas progressivas

Não despejar todas as perguntas se o usuário quiser responder aos poucos. Trabalhar por blocos:

1. Escopo e fora de escopo.
2. Endpoints/contratos.
3. Payload e resposta.
4. Validações de domínio.
5. Transação, persistência e rollback.
6. Auditoria/observabilidade.
7. Testes e rollout.
8. OpenAPI/docs/schema.

Para cada bloco:

- fazer perguntas numeradas;
- incluir uma recomendação quando for possível inferir;
- depois de cada resposta, atualizar o `.md` e marcar a decisão como fechada;
- manter perguntas pendentes somente quando a decisão ainda afeta implementação.

Toda pergunta leva, além da recomendação:

- **Por que importa:** o que muda na implementação conforme a resposta. Se não mudar nada, não perguntar.
- **Exemplo concreto** quando a decisão tiver forma visível (coluna de relatório, payload, mensagem de erro, nome de campo): mostrar antes/depois com dados fictícios. Se o exemplo for grande ou tiver várias opções, criar um `N-exemplo-<assunto>.md` e apontar para ele.

Exemplo de pergunta boa:

```md
12. O campo `deactivated` deve existir no payload de criação?

Recomendação: não aceitar `deactivated`; configurações nascem ativas e desativar é uma ação separada já existente.
```

## Divisão em PRs

Quando a entrega for grande, dividir em PRs que funcionem sozinhos e registrar em tabela:

```md
| PR | Conteúdo | Contrato | Depende de |
|---|---|---|---|
| 1. <nome> | <o que entra> | Não muda / Aditivo / Aviso no schema / **Breaking** | — |
```

- Ordenar para que nenhum PR quebre o consumidor (frontend, integrações) antes que o substituto exista.
- Para remover endpoint, campo ou fluxo usado por outro time, usar transição em etapas:
  1. neutralizar o risco sem mudar o formato do contrato (ex.: campo aceito mas ignorado);
  2. marcar como obsoleto no código (`TODO(<identificador>)` explicando por que sai) e no OpenAPI (`deprecated`);
  3. remover em PR próprio, marcado como breaking, só depois que o consumidor migrar.
- Separar PRs que mudam saída visível ao cliente (relatório, tela) dos que só mudam regra interna.

## Andamento

Ao implementar cada PR, registrar no fim do plano:

```md
### PR <n> — branch `<n>-<identificador>-<descrição>` (criada de <base> @ <commit>, <data>)

Commits: `<sha>` (<resumo>), ...
- <o que foi implementado e decisões tomadas durante a implementação>

Validado: <comandos e resultados reais>. Pendente: <push, PR, review>.
```

Registrar só validações que foram executadas, com o resultado obtido.

## Registro de decisões

Quando uma decisão for tomada, atualizar o documento em linguagem afirmativa:

```md
12. Decidido: não aceitar `deactivated`; configurações nascem ativas.
```

Evitar deixar texto antigo contradizendo a decisão. Remover ou reescrever recomendações que viraram decisões.

Quando houver uma decisão que o usuário levará a supervisor, registrar como ponto de validação:

```md
## Ponto para validação com supervisor

- Contexto da dúvida.
- Interpretação recomendada.
- Impacto se a decisão mudar.
- Pergunta objetiva de produto/arquitetura.
```

## Investigação no código

Quando existir repo disponível, investigar antes de planejar detalhes implementáveis:

- `git status --short --branch` para entender branch e sujeira local;
- `git diff --stat` e `git diff --name-status` para PR em andamento;
- `rg` por nomes de models, serializers, views, rotas e testes;
- ler arquivos relevantes com `sed`;
- evitar editar código quando o pedido é apenas planejamento.

Não assumir que endpoint, serializer ou teste existe sem procurar. Se a pergunta for conceitual, pode responder sem varredura ampla, mas planos de implementação devem ser ancorados no código.

## Regras de escopo

- Se o usuário pede documento só da branch atual, não misturar próximos PRs no mesmo arquivo.
- Se o usuário pede próximos PRs, criar documento próprio para cada PR quando o escopo for grande.
- Se uma review pede remover algo, registrar explicitamente arquivos/rotas/testes a remover.
- Se o schema/OpenAPI for gerado automaticamente no projeto, documentar que não deve ser editado manualmente.
- Se endpoints existentes são usados pelo frontend, priorizar compatibilidade; se quebrar contrato for necessário, explicar o motivo em linguagem humana.

## Saída padrão

Ao criar ou atualizar arquivo:

- informar o caminho da pasta e dos `.md` criados ou alterados;
- resumir decisões adicionadas;
- listar perguntas pendentes seguintes;
- não colar o documento inteiro salvo, a menos que o usuário peça.

## Nomes de arquivo

Seguir "Pasta da issue": `tmp/plans/<identificador>/<n>-<slug>.md`, por exemplo:

- `tmp/plans/MONV4-58/1-issue-original.md`;
- `tmp/plans/MONV4-58/2-plano-implementacao.md`;
- `tmp/plans/MONV4-58/3-exemplo-relatorio-revisor.md`;
- `tmp/plans/LOCAL-escopo-justificativa-alertas/2-plano-implementacao.md`.

Usar arquivo solto em `tmp/` só quando o usuário pedir explicitamente.
