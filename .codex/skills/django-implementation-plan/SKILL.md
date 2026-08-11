---
name: django-implementation-plan
description: transforma uma issue ou demanda em plano de implementação Django decomposto por camada — model, manager, controller, serializer, view, task — em ordem de dependência, com divisão em PRs e testes por camada. use quando o usuário pedir para planejar uma issue, destrinchar uma demanda, quebrar em etapas, dizer o que muda em cada camada, montar plano antes de implementar ou dividir o trabalho em PRs.
---

# Plano de Implementação (Django)

## Objetivo

Transformar uma issue em um plano executável, decomposto pelas camadas da
arquitetura e ordenado por dependência, para que a implementação seja mecânica e
sem adivinhação.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "planeje essa issue"
- "o que precisa mudar para fazer isso?"
- "destrincha essa demanda em etapas"
- "divide esse trabalho em PRs"
- "o que vai em cada camada?"

Esta skill fica entre `write-issue`, que define o problema, e
`python-implementation-workflow`, que executa.

## O que esta skill não faz

**Não escreve código de produção.** O produto é o plano. Ler código é obrigatório;
alterar não. Se ao final o usuário pedir para implementar, aí sim use a skill
`python-implementation-workflow`.

## Procedimento

**Crie uma tarefa para cada item abaixo e conclua na ordem.** Etapa pulada aqui
não aparece agora: aparece como retrabalho na implementação, quando já custa caro.

1. **Entenda a demanda.** Leia a issue, o pedido ou a conversa. Separe o que é
   requisito do que é sugestão de solução.
2. **Investigue o código.** Um plano não ancorado no que existe é ficção — ver
   "Investigação".
3. **Feche o contrato** antes de decompor: rota, payload, resposta, códigos de
   status, permissão. É o que amarra todas as camadas.
4. **Decomponha por camada**, na ordem de dependência.
5. **Corte em PRs**, se o trabalho não couber em um.
6. **Varra os furos** — ver "Varreduras anti-furo".
7. **Escreva o arquivo.**
8. **Revise o que escreveu** — ver "Auto-revisão".
9. **Entregue para o usuário revisar e espere** — ver "Gate de revisão".

## Investigação

Antes de propor qualquer coisa, confirme no código:

- o model existe? que campos e constraints já tem?
- existe manager ou queryset que já faça o recorte necessário?
- existe controller para esse fluxo, ou é novo?
- que endpoints já existem nesse app e que padrão seguem?
- que testes cobrem a área hoje?

Use `rg` para localizar e leia os arquivos relevantes. **Não afirme que algo existe
sem ter procurado**, e não invente nome de campo, método ou rota. Quando não achar,
diga no plano que é criação nova.

## Onde o plano mora

```
tmp/planning/<issue>/AAAA-MM-DD-<assunto>.md
```

- `<issue>` identifica a demanda e vira a pasta dela: identificador quando houver,
  mais um slug curto — `MON-142-suspensao-de-alertas`. Sem identificador, só o slug.
- A pasta da issue guarda **tudo** sobre ela ao longo do tempo: o plano, notas de
  investigação, decisões, ajustes pós-review. Por isso é pasta, não arquivo solto.
- O nome do arquivo **começa sempre pela data** `AAAA-MM-DD`, para que a ordem
  cronológica seja a ordem alfabética.

Exemplo:

```
tmp/planning/MON-142-suspensao-de-alertas/
├── 2026-08-10-implementation-plan.md
├── 2026-08-13-desvios.md            escrito na implementação
└── 2026-08-14-ajustes-pos-review.md
```

**O plano é registro do que foi combinado e não se reescreve depois.** Quando a
implementação precisar divergir, o desvio vira arquivo novo e datado na mesma
pasta — a skill `python-implementation-workflow` faz isso ao validar. Assim o
histórico mostra o que foi decidido, o que mudou e por quê, em vez de só o estado
final.

## Decomposição por camada

Esta é a espinha do plano. Percorra as camadas **nesta ordem**, que é a ordem em
que uma depende da outra:

| # | Camada | A pergunta que o plano responde |
|---|---|---|
| 1 | **Model** | que dado passa a existir? campo, constraint, índice, migration |
| 2 | **Manager / QuerySet** | que consulta é nova ou muda? como recorta por tenant? |
| 3 | **Controller** | qual é a regra? o que valida? o que orquestra? transação e efeito colateral |
| 4 | **Serializer** | qual o contrato de entrada e saída? o que valida aqui? |
| 5 | **View / URL** | qual rota, método, permissão e códigos de status? |
| 6 | **Task / Signal** | o que roda fora do request? é idempotente? |
| 7 | **Admin** | precisa de visibilidade operacional? |
| 8 | **Documentação** | muda fronteira entre apps? há decisão a registrar? |

Para cada camada, escreva **o que muda, por que, e do que depende**.

**Camada sem trabalho aparece como "nada a fazer".** Não a omita: explícito prova
que foi considerada, omissão parece esquecimento — e quem implementa não sabe a
diferença.

Se estiver em dúvida sobre em qual camada algo mora, use a tabela "onde isso mora"
da skill `django-layered-architecture`. Os testes de cada camada saem da receita da
skill `django-tests`, e o plano já os lista.

O formato completo do documento está em `references/plan-template.md`.

## Divisão em PRs

O alvo é **PR pequeno, revisável e que não trave a aprovação de outro**. Trabalho em
camadas tende ao contrário — o controller precisa do model — então o corte exige
técnica, não boa vontade.

**Prefira fatia vertical a camada horizontal.** Uma capacidade pequena e completa
(model + controller + endpoint de um único caso) é independente de verdade. Um PR
"todos os models" seguido de um PR "todos os controllers" é sequencial por
construção: o segundo não faz sentido sem o primeiro.

**Quando a dependência for inevitável, faça o PR base puramente aditivo.** Model,
manager e controller ainda sem chamador não mudam comportamento algum — logo são
revisáveis e mergeáveis sozinhos, com risco baixo e aprovação rápida. O PR seguinte
liga o consumidor.

Regras do corte:

- Cada PR precisa ser **compreensível sozinho**: quem revisa não deve precisar abrir
  outro PR para julgar se este está certo.
- Cada PR entra na branch principal **sem quebrar nada**, mesmo que a funcionalidade
  ainda não esteja visível.
- Cada PR leva os próprios testes. PR sem teste não é fatia, é metade de coisa.
- Se um PR só faz sentido depois de outro, diga isso explicitamente no plano, com a
  ordem e o motivo.
- Refatoração preparatória vira PR próprio, antes da mudança de comportamento.
- Alvo prático: uma revisão que entenda motivo, diff e risco em 15 a 30 minutos.

No plano, para cada PR: **o que entrega, quais camadas toca, de que depende, e como
é verificado.**

## Varreduras anti-furo

Cobertura de camada não é cobertura de requisito. As cinco varreduras abaixo pegam
o que a decomposição deixa passar. Faça todas antes de escrever o documento.

### 1. Rastreabilidade requisito ↔ camada

Ligue cada requisito da issue à camada que o atende. O valor está em ser
**bidirecional**:

- requisito sem camada → **furo**: algo foi pedido e ninguém faz;
- camada sem requisito → **escopo inflado**: trabalho que ninguém pediu.

### 2. Impacto em quem já consome

Para cada model, método, rota ou constante que muda, procure quem depende hoje:

```
rg "<nome>" --type py
```

Cheque explicitamente outro app, task, management command, signal, admin, teste e
o contrato do frontend. **Consumidor esquecido é a causa mais comum de regressão
em mudança bem planejada.**

Task já enfileirada merece atenção própria: mudar a assinatura de uma task quebra
as mensagens que ainda estão na fila.

### 3. Bordas obrigatórias

Cada linha recebe o comportamento esperado ou "não se aplica, porque X". Silêncio
não é resposta.

| Borda | A pergunta |
|---|---|
| Vazio, nulo, zero | o que acontece com entrada ausente ou coleção vazia? |
| Inexistente | e se o registro referenciado não existir? |
| Estado já aplicado | repetir duplica efeito, ou é idempotente? |
| Concorrência | dois requests simultâneos no mesmo registro? |
| Volume | funciona com 10; e com 100 mil? |
| Tenant alheio | usuário de outro cliente alcança isso? |
| Sem permissão | qual comportamento e qual status? |

### 4. Dado existente e reversão

- Campo novo em tabela que já tem linhas: que valor elas recebem?
- A regra nova é violada por dado que já existe? Precisa de backfill ou limpeza antes?
- A migration reverte? Se não reverte, diga.
- Dá para desligar em produção sem reverter o deploy?

### 5. Incertezas assumidas

O que você não conseguiu confirmar vira seção do documento, com a suposição feita e
o impacto caso ela esteja errada. **Suposição nomeada é informação; suposição
silenciosa vira bug.**

Não confunda com "Perguntas pendentes": pendência bloqueia a implementação,
incerteza não bloqueia mas muda o risco.

## Perguntas progressivas

Não despeje todas as dúvidas de uma vez. Trabalhe por blocos, e só avance quando o
anterior fechar:

1. Escopo e fora de escopo
2. Contrato: rota, payload, resposta
3. Regras de domínio e validações
4. Persistência, transação e rollback
5. Efeitos: task, notificação, auditoria
6. Permissão e isolamento entre clientes
7. Testes e rollout

Para cada pergunta, **traga uma recomendação junto**. Pergunta sem recomendação
transfere trabalho ao usuário sem reduzir incerteza:

```md
3. O campo `deactivated` entra no payload de criação?

Recomendação: não. Configurações nascem ativas, e desativar já é uma ação separada.
```

Pergunte apenas o que muda a implementação. O que dá para descobrir lendo o código,
descubra.

## Registro de decisões

- Decisão fechada vira afirmação, não pergunta: `Decidido: configurações nascem
  ativas; o payload de criação não aceita deactivated.`
- Ao fechar uma decisão, **remova ou reescreva** o texto antigo que a contradiz.
  Documento que se contradiz é pior que documento incompleto.
- Decisão que depende de terceiro vira ponto de validação, com contexto,
  interpretação recomendada, impacto se mudar e a pergunta objetiva.

## Regras obrigatórias

- Não altere código de produção. O produto é o plano.
- Ancore no código real: nada de campo, método ou rota inventado.
- Percorra as oito camadas, marcando "nada a fazer" onde não houver trabalho.
- Feche o contrato antes de decompor.
- Todo PR proposto leva os próprios testes.
- Ao atualizar o plano, informe o caminho e o que mudou — não cole o documento
  inteiro, salvo pedido.

## Auto-revisão

Depois de escrever, releia o documento com os olhos de quem vai implementar a
partir dele — não com os olhos de quem acabou de escrever.

1. **Pendência disfarçada.** Sobrou "TBD", "a definir", "provavelmente" ou campo
   sem nome no meio do plano? Ou você decide, ou move para "Perguntas pendentes".
   O que não pode é ficar no corpo parecendo decidido.
2. **Contradição.** Alguma camada assume algo que outra decidiu diferente? O
   contrato bate com o que a view e o serializer descrevem?
3. **Cobertura.** As oito camadas foram percorridas, inclusive as com "nada a
   fazer"? As cinco varreduras foram feitas — rastreabilidade sem furo, impacto
   mapeado, bordas respondidas?
4. **Invenção.** Todo campo, método e rota citados existem no código, ou estão
   marcados explicitamente como criação nova?
5. **PR acoplado.** Algum PR proposto só é revisável abrindo outro? Cada um tem
   teste e critério de verificação?
6. **Pendência que não bloqueia.** As perguntas que restaram realmente impedem
   implementar, ou dá para decidir agora e seguir?
7. **Caminho.** O arquivo está em `tmp/planning/<issue>/` e começa pela data?

Corrija inline e siga. Não precisa revisar de novo.

## Gate de revisão

Depois da auto-revisão, entregue e **espere**. Não invoque
`python-implementation-workflow`, não escreva código e não comece nada antes do
usuário aprovar:

```md
Plano escrito em `<caminho>`.
Decisões fechadas: <n>. Pendências: <n>.
Revise antes de eu passar para a implementação.
```

Se o usuário pedir mudança, ajuste o documento e rode a auto-revisão outra vez.

O gate existe porque o plano é a entrada do `python-implementation-workflow`: erro
que passa daqui vira código errado, e aí custa muito mais para desfazer.
