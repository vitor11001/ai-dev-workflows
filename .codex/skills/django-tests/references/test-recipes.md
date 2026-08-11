# Receita de testes por camada

Para cada camada: o **mínimo obrigatório**, os **gatilhos** no código que exigem um
teste específico, e o que **não** testar.

Como usar: leia o código do alvo, procure os gatilhos presentes e escreva o teste
correspondente. Gatilho ausente, teste ausente — não invente cenário que o código
não sustenta.

No modo refatorar, a mesma tabela diz o que preservar: não remova cobertura de um
obrigatório nem de um gatilho presente.

---

## Model

**Sempre:** criação válida com os dados mínimos persiste e é recuperável.

| Se o model tem... | Teste que... |
|---|---|
| `unique=True`, `UniqueConstraint` | a duplicata levanta `IntegrityError` |
| `default=` | o default é aplicado quando o campo é omitido |
| `choices` / `TextChoices` | valor fora do enum é rejeitado |
| `null=False` sem default | omitir o campo falha |
| `clean()` ou `CheckConstraint` | a combinação inválida de campos é rejeitada |
| `@property` ou método calculado | o cálculo, incluindo borda — zero, vazio, nulo |
| `save()` sobrescrito | o efeito real: slug, normalização, campo derivado |
| `on_delete` diferente de `CASCADE` | o que acontece ao apagar o pai |
| campo de data, vigência ou expiração | a borda do limite, com o tempo congelado |
| soft delete ou `is_active` | o manager padrão não retorna o inativo |
| signal (`post_save`, `pre_delete`) | o efeito observável — não que o signal disparou |
| `__str__` usado em admin, log ou UI | o formato produzido |
| `Meta.ordering` que o contrato promete | a ordem retornada |

**Não teste:** campo sem regra própria; que o Django persiste (é o ORM); `Meta`
que ninguém consome; migrations.

---

## Manager e QuerySet

**Sempre:** retorna exatamente o conjunto esperado — afirme o que entra **e** o que
fica de fora.

| Se o manager... | Teste que... |
|---|---|
| recorta por organização ou cliente | dado de outro tenant não aparece |
| agrega (`Count`, `Sum`, `Avg`) | o resultado com 0, 1 e N registros |
| usa `select_related`/`prefetch_related` | a contagem de queries não escala com o volume |
| é encadeável | compõe com outro filtro sem perder o recorte |
| filtra por data ou janela | as duas bordas do intervalo |
| exclui inativo ou deletado | o excluído não volta em nenhum caminho |

**Não teste:** que `.filter()` funciona; método que só delega sem lógica própria.

---

## Serializer

**Sempre:** nada por si só. Serializer sem lógica própria é coberto pelo teste de
API — não crie arquivo de teste para ele.

| Se o serializer tem... | Teste que... |
|---|---|
| `validate_<campo>` | o valor válido passa e o inválido levanta, com a mensagem esperada |
| `validate()` entre campos | a combinação inválida é rejeitada |
| `SerializerMethodField` | o valor calculado, incluindo o caso nulo |
| `read_only` / `write_only` | campo `read_only` enviado no payload é ignorado |
| `to_representation` sobrescrito | o formato de saída |
| serializer aninhado | o shape do aninhamento |

**Não teste:** que `required=True` obriga (é o DRF); serializer trivial.

---

## Controller

**Sempre:**
1. o fluxo feliz retorna o resultado esperado;
2. **cada validação defensiva** levanta a exceção certa, com a mensagem certa.

O item 2 não é opcional. O controller revalida porque task, signal, command e outro
controller chegam nele sem passar por serializer — e o teste de API **não** cobre
esses caminhos. Se a validação só tem teste via HTTP, ela está sem cobertura onde
mais importa.

| Se o controller... | Teste que... |
|---|---|
| escreve em mais de uma tabela | a falha no meio faz rollback e deixa o banco intacto |
| dispara task Celery | a task foi enfileirada com os argumentos certos |
| chama serviço externo | o sucesso e a falha do externo, com fake nomeado |
| é idempotente por contrato | chamar duas vezes produz um efeito só |
| converte exceção de domínio | sai a exceção traduzida, não a original |
| tem ramo condicional de negócio | os dois ramos |
| aplica regra de acesso | o caso permitido e o negado |

**Não teste:** que o controller chamou o método X do model; via HTTP o que dá para
provar chamando o controller direto.

---

## View e Endpoint

**Sempre:**
- caminho feliz: status esperado e shape do payload;
- anônimo → `401`;
- autenticado sem permissão → `403`;
- recurso inexistente → `404`;
- payload inválido → `400`/`422`, citando o campo.

| Se o endpoint... | Teste que... |
|---|---|
| expõe dado de cliente | usuário de um tenant não alcança o dado de outro |
| é listagem | a contagem de queries não escala com o volume |
| tem filtro ou busca | retorna só o compatível — e o incompatível fica de fora |
| tem paginação ou ordenação | os metadados e a ordem que o contrato promete |
| escreve (`POST`/`PUT`/`PATCH`) | persistiu de fato — recarregue do banco e confira |
| é `PATCH` | altera só o que foi enviado e preserva o restante |
| exclui | o estado final: removido, desativado ou marcado |
| retorna data, enum ou campo calculado | o formato serializado |
| dispara efeito colateral | o efeito aconteceu, não apenas que o status foi 200 |
| é idempotente por contrato | repetir a request não duplica o efeito |

**Não teste:** que o DRF pagina ou ordena; a regra de negócio que já tem teste no
controller — aqui prove só a tradução para HTTP.

---

## Task Celery

**Sempre:** a task chama o controller com os argumentos certos.

| Se a task... | Teste que... |
|---|---|
| tem retry | reenfileira na exceção esperada — e não em qualquer outra |
| é idempotente | duas execuções produzem um efeito só |
| tem lock ou guarda de boot | a segunda execução concorrente não duplica o trabalho |
| trata exceção externa | não estoura, registra e segue a política definida |

**Não teste:** o Celery; a regra de negócio — ela está no controller, teste lá.

---

## Quanto é suficiente

A cobertura está completa quando todo obrigatório da camada e todo gatilho presente
no código têm teste. Não persiga percentual: um app com 100% de linhas e sem teste
de isolamento entre tenants está pior coberto que um com 70% e esse teste presente.

Se um gatilho da tabela não se aplica ao alvo, não force. Se você precisou de um
cenário que não está aqui, ele provavelmente vale para outros alvos também — vale
propor a inclusão na receita.
