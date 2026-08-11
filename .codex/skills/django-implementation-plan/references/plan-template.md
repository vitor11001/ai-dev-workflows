# Template do plano

Estrutura do documento gravado em `tmp/planning/<issue>/AAAA-MM-DD-<assunto>.md`.
Adapte as seções ao caso: corte o que não se aplica, nunca invente conteúdo para
preencher.

---

```md
# <Título da demanda>

> Issue: <identificador ou link> · Plano de AAAA-MM-DD

## Objetivo

Uma ou duas frases sobre o que muda para quem usa. Comportamento, não arquivo.

## Fora de escopo

O que foi considerado e deliberadamente ficou de fora, com o motivo. Evita que a
implementação cresça sozinha e que o revisor cobre o que não foi combinado.

## Contrato

O que amarra todas as camadas. Feche antes de decompor.

- **Rota:** `POST /api/v1/<recurso>`
- **Permissão:** `<slug da permissão>`
- **Entrada:** campos, tipos, obrigatoriedade
- **Saída:** shape da resposta
- **Status:** 201 criado · 400 payload inválido · 403 sem permissão · 409 conflito

Se o contrato já existe e não muda, escreva "sem mudança de contrato".

## Camadas

Percorra as oito, na ordem. Para cada uma: **o que muda, por quê, do que depende.**
Camada sem trabalho recebe "nada a fazer" — explícito.

### 1. Model
### 2. Manager / QuerySet
### 3. Controller
### 4. Serializer
### 5. View / URL
### 6. Task / Signal
### 7. Admin
### 8. Documentação

## Divisão em PRs

Para cada PR: o que entrega, camadas que toca, do que depende, como verificar.
Se couber em um só, diga isso.

## Riscos e cuidados

Migration em tabela grande, mudança de contrato consumida pelo frontend, efeito em
dado existente, concorrência, volume. O que pode dar errado e o que observar.

## Decisões fechadas

Em linguagem afirmativa, numeradas. Sem pergunta aqui.

## Perguntas pendentes

Só o que bloqueia a implementação. Cada uma com recomendação.

## Critérios de pronto

Como saber que acabou: comportamento observável, testes que passam, verificação
manual quando couber.
```

---

## Exemplo preenchido (trecho)

Como as camadas ficam quando bem escritas:

```md
## Camadas

### 1. Model — `AlertSuspension` (novo)
- Campos: `alert` (FK, `on_delete=CASCADE`), `until` (datetime), `created_by` (FK User).
- Constraint: no máximo uma suspensão ativa por alerta.
- Migration: sim, tabela nova. Sem backfill.
- **Depende de:** nada. É a base.

### 2. Manager — `AlertSuspensionManager.active_for(alert)`
- Retorna a suspensão vigente do alerta, ou `None`.
- Recorta por organização, como o resto do app.
- **Depende de:** camada 1.

### 3. Controller — `AlertSuspensionController.suspend`
- Valida `hours` entre 1 e 720; recusa se já houver suspensão ativa.
- Cria o registro e agenda a expiração com `transaction.on_commit`.
- Levanta `ConflictExc` quando já suspenso, para a view traduzir em 409.
- **Depende de:** camadas 1 e 2.

### 4. Serializer — `SuspendAlertInput`
- Valida `hours` como inteiro positivo. Sem regra de negócio.
- **Depende de:** nada.

### 5. View / URL — `AlertSuspendView`
- `POST /api/v1/alerts/<id>/suspend`, permissão `ALERT.SUSPEND`.
- Traduz `ConflictExc` em 409.
- **Depende de:** camadas 3 e 4.

### 6. Task — `expire_alert_suspension`
- Recebe o id, recarrega do banco, marca como expirada.
- Idempotente: rodar duas vezes não muda o resultado.
- **Depende de:** camada 1.

### 7. Admin — nada a fazer.

### 8. Documentação — nada a fazer.
    Não muda fronteira entre apps nem cria decisão estrutural.
```

E a divisão em PRs correspondente:

```md
## Divisão em PRs

**PR 1 — persistência da suspensão** (aditivo, sem consumidor)
- Camadas 1, 2 e 6. Model, migration, manager e task.
- Não muda comportamento algum: nada chama isso ainda.
- Depende de: nada. Mergeável sozinho.
- Verificação: testes de model, manager e task.

**PR 2 — endpoint de suspensão**
- Camadas 3, 4 e 5. Controller, serializer, view e rota.
- Depende de: PR 1, pelo model. Revisável em separado — a regra e o contrato se
  julgam sem reabrir o PR anterior.
- Verificação: testes de controller e de API, incluindo 409 e isolamento entre
  organizações.
```

Repare no que torna o PR 1 seguro: ele **só adiciona**. Nenhum caminho existente
passa a se comportar diferente, então a revisão é rápida e o merge não trava nada.
