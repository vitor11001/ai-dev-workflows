---
name: implementation-plan
description: planeja a implementação de uma demanda já investigada (o como) em Markdown, em tmp/tasks/<ID>/: mapa de impacto com o efeito da mudança, desenho, testes em ordem de ciclos TDD, perguntas com recomendação, divisão em PRs, premissas e andamento. use quando o usuário quiser transformar uma task, issue, review ou conversa em plano de implementação, dividir trabalho em PRs, atualizar escopo após review, criar checklist para outra LLM implementar ou registrar decisões e perguntas pendentes. se a task ainda não foi investigada, roda a investigate antes; para redigir a issue, use plane-issue.
---

# Plano de Implementação

## Objetivo

Planejar a implementação de forma executável, a partir da investigação da task: escopo, decisões, perguntas, arquivos prováveis, testes e critérios de pronto em Markdown. Priorizar clareza para humanos e para outra LLM executar depois.

## Fluxo principal

1. Entender a fonte do pedido (task, issue, review, branch atual, PR futuro ou conversa), localizar a pasta da task (ver "Pasta da task") e ler o `0-sumario.md` e os arquivos dela. Se o plano já existir, continuar de onde parou; pedido vindo de review atualiza o plano existente.
2. Se não houver `*-investigacao.md`, rodar a skill `investigate` antes. Se houver, conferir a defasagem conforme "Investigação desatualizada" da `investigate`.
3. Ler `*-issue-original.md` quando existir. Onde o plano divergir da issue, o plano prevalece, e a divergência é registrada em "Decisões já fechadas".
4. Ajustar a profundidade ao tipo da task (ver "Profundidade por tipo").
5. Montar o mapa de impacto a partir do mapa do código atual da investigação (ver "Mapa de impacto"); quando o usuário pedir, apresentar o mapa para revisão antes do desenho.
6. Separar claramente:
   - ajustes da branch/PR atual;
   - próximos PRs/branches;
   - fora de escopo.
7. Criar ou atualizar `N-plano-implementacao.md` na pasta da task, salvo se o usuário indicar outro caminho, e registrar a linha no sumário (Status `planejada`).
8. Registrar decisões tomadas e perguntas pendentes. Quando o usuário responder, atualizar o arquivo e reduzir a lista de pendências.
9. Quando houver dúvida, propor uma recomendação técnica antes de perguntar. Explicar o motivo em linguagem humana e mostrar um exemplo concreto (ver "Perguntas progressivas").
10. Antes de encerrar, aplicar "Revisão do plano". Encerrar quando o documento tiver decisões suficientes para implementação sem adivinhação perigosa.
11. Durante a implementação, manter a seção "Andamento" atualizada a cada PR.

## Pasta da task

- A task mora em `tmp/tasks/<ID>/`; as regras completas (identificador, `LOCAL-<slug>`, arquivos, pasta antiga) estão na skill `investigate`.
- Encontre os arquivos pelo nome (`*-investigacao.md`, `*-issue-original.md`, `*-plano-implementacao.md`), nunca pelo número; ao criar arquivo, continue a numeração.
- Ao rodar, registre uma linha no `0-sumario.md` com a data de `date '+%Y-%m-%d %H:%M %Z'`: `| <data> | <skill> | <o que fez> | <arquivo> |`. Atualize o cabeçalho quando Status ou Plane mudarem.
- Pasta antiga em `tmp/plans/<ID>/`: siga "Pasta antiga em `tmp/plans/`" da skill `investigate`.

Apoios visuais a uma decisão (tabelas de antes/depois, payloads, telas de relatório) vão em `N-exemplo-<assunto>.md`, criados quando a pergunta ficar difícil de entender só com texto.

### Branches

As branches de implementação seguem `<n>-<identificador>-<descrição-kebab>`, em que `n` é o número do PR na divisão do plano (ex.: `1-PROJ-123-freight-free-shipping-threshold`), criadas a partir da base registrada no plano. Registrar a branch de cada PR na seção "Andamento".

## Profundidade por tipo

| Tipo | Plano |
|---|---|
| `hotfix` | curto: causa, menor correção segura, teste de regressão, rollback e um PR; só os blocos de pergunta que bloqueiam |
| `bug` | causa raiz da investigação, correção, testes de regressão e o que mais a mesma causa afeta |
| `feature` e `melhoria` | completo: contrato, fluxos, desenho, testes por camada, divisão em PRs e rollout |
| `débito` | etapas pequenas que mantêm o comportamento, com os testes que protegem cada etapa |

## Mapa de impacto

Em task média ou grande, partir do mapa do código atual da investigação e acrescentar a coluna "Efeito da mudança" antes de propor o desenho. Task pequena e clara (um arquivo, regra óbvia) dispensa o mapa.

```md
## Mapa de impacto

| Ponto | Onde | Papel | Efeito da mudança |
|---|---|---|---|
| Regra de frete | `shipping/services/freight.py:42` | define | altera |
| Regra de frete | `orders/serializers.py:88` | duplica | unificar chamando o service; se ampliar demais o escopo, alterar junto e abrir issue de unificação |
| `calculate_freight` | `checkout/views.py:120`, `tasks/recalc.py:30` | chama | sem mudança; cobrir com teste |
| `Order.freight` | migration `0042` | persiste | pedidos antigos mantêm o valor? → pergunta 4 |
```

- Se o desenho tocar algo que o mapa da investigação não tem, buscar com `rg` pelos termos do conceito e acrescentar a linha, registrando a atualização da investigação no sumário.
- Antes de propor código novo, conferir as implementações irmãs registradas na investigação.
- Duplicação encontrada se resolve unificando por padrão; manter as duas cópias só com justificativa de escopo registrada no plano.
- Todo ponto com efeito `altera`, `duplica` ou com pergunta aberta precisa reaparecer no desenho, em "Testes necessários" ou em "Perguntas pendentes".

## Estilo do documento

Usar seções úteis e diretas. Preferir esta estrutura, adaptando ao caso:

```md
# <identificador> — <título>

> Investigação: `N-investigacao.md` · Issue: `N-issue-original.md` (quando existir). Onde este arquivo divergir da issue, este prevalece.

## Objetivo
## Base / Premissas
## Fora de escopo
## Decisões já fechadas
## Contrato final
## Fluxos esperados
## Mapa de impacto
## Desenho de implementação recomendado
## Arquivos prováveis a alterar
## Testes necessários
## Ordem de implementação sugerida
## Cuidados importantes
## Comandos de verificação
## Critérios de pronto
## Divisão em PRs
## Premissas não verificadas
## Perguntas pendentes
## Andamento
```

Em "Premissas não verificadas", registrar o que o plano supõe sem ter conseguido confirmar no código, com o motivo (ex.: "suponho que o frontend não lê `freight_label`; o repositório do frontend não estava disponível"). Cada premissa vira pergunta pendente ou cuidado importante; nunca fica implícita no desenho.

Em "Testes necessários", listar os comportamentos na ordem dos ciclos TDD da implementação, do caso principal para as bordas. Cada item é um comportamento só, com o arquivo de teste provável; se depender de pergunta pendente, apontar o número dela:

```md
## Testes necessários

1. Pedido acima de R$ 500 tem frete zero — `tests/unit/shipping/test_freight_calculator.py`.
2. Pedido de exatamente R$ 500 paga frete — mesmo arquivo (depende da pergunta 3).
3. Cupom que reduz o total abaixo de R$ 500 volta a cobrar frete — `tests/integration/orders/test_checkout.py`.
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
- Ciclos TDD: <comportamento>: RED `<comando>` → falhou (<motivo>); GREEN passou.

Validado: <comandos e resultados reais>. Pendente: <push, PR, review>.
```

Registrar só validações que foram executadas, com o resultado obtido. Ciclos TDD ocupam uma linha por comportamento, sem colar saída do `pytest`. O sumário recebe só uma linha por PR iniciado e concluído; o detalhe fica aqui.

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


## Código no planejamento

- Ler inteiros os arquivos que o plano vai alterar; nos vizinhos (callers, testes, consumidores), ler só o trecho relevante.
- `git status --short --branch` para entender branch e sujeira local; para PR em andamento, `git diff --stat` e `git diff --name-status` contra a base.
- Não assumir que endpoint, serializer ou teste existe sem procurar; o que a investigação não cobriu, buscar com `rg` e acrescentar a ela.
- Não editar código quando o pedido é apenas planejamento.

## Regras de escopo

- Se o usuário pede documento só da branch atual, não misturar próximos PRs no mesmo arquivo.
- Se o usuário pede próximos PRs, criar documento próprio para cada PR quando o escopo for grande.
- Se uma review pede remover algo, registrar explicitamente arquivos/rotas/testes a remover.
- Se o schema/OpenAPI for gerado automaticamente no projeto, documentar que não deve ser editado manualmente.
- Se endpoints existentes são usados pelo frontend, priorizar compatibilidade; se quebrar contrato for necessário, explicar o motivo em linguagem humana.

## Revisão do plano

Antes de entregar o plano, conferir contra o próprio documento e corrigir o que falhar:

1. Todo ponto do mapa de impacto com efeito `altera`, `duplica` ou pergunta aberta tem passo, teste ou pergunta correspondente?
2. O desenho contradiz algo registrado no mapa, na investigação (inclusive a validade da issue) ou nas decisões fechadas?
3. O plano cria algo que já existe no projeto (helper, validação, endpoint, factory)?
4. Algum passo depende de fato não verificado que ainda não está em "Premissas não verificadas"?

Se a revisão mudar o desenho, registrar em uma linha o que mudou e por quê.

## Saída padrão

Entregue em tabelas Markdown, com uma frase de resumo antes e as perguntas pendentes seguintes depois:

| Item | Detalhe |
|---|---|
| Plano | `tmp/tasks/<ID>/N-plano-implementacao.md` (criado ou atualizado) |
| Divisão | `<n>` PRs, com o contrato de cada um (não muda, aditivo, breaking) |
| Decisões adicionadas | uma por linha |
| Perguntas pendentes | as do próximo bloco, numeradas |

Não colar o documento inteiro, a menos que o usuário peça.
