---
name: django-tests
description: cria, amplia e refatora testes de projetos Django e DRF com pytest e pytest-django, usando os padrões incorporados nesta skill. use quando o usuário pedir para criar testes, adicionar cobertura, escrever teste para model, manager, controller, serializer, view, endpoint, task ou fluxo Django, e também para refatorar, consolidar, renomear, converter unittest, limpar testes legados ou alinhar a suíte ao padrão atual.
---

# Testes Django

## Objetivo

Criar e manter testes de projetos Django/DRF que provam comportamento real, rodam
de forma determinística e não vazam dados entre clientes.

## Quando usar

**Para criar ou ampliar:**
- "crie testes para esse model"
- "adicione cobertura para esse controller"
- "gere testes para esse endpoint"
- "complete os testes dessa manager"

**Para refatorar:**
- "refatore esses testes"
- "converta esses testes para pytest"
- "consolide os testes desse módulo"
- "limpe os testes legados"

Os padrões abaixo valem para os dois casos. O que muda é o procedimento inicial.

## Precedência

Ao chegar num projeto, separe duas coisas:

**As convenções locais vencem** — nome de fixture, forma de factory, comando de
execução, marcadores registrados. Leia `AGENTS.md`, `CLAUDE.md`, o `conftest.py` e
alguns testes antes de escrever, e use o que o projeto já usa.

**A estrutura de pastas desta skill é o alvo**, não uma sugestão. Em projeto que
hoje organiza a suíte de outro jeito, o teste novo já nasce no formato correto e a
suíte migra aos poucos — ver "Projeto legado".

## Modo criar

1. Leia as instruções locais e o código de produção, os testes existentes e as
   factories do app.
2. Identifique a camada do alvo: model, manager/queryset, controller, serializer,
   view/endpoint ou task.
3. Aplique a receita daquela camada — ver `references/test-recipes.md`.
4. Reutilize factories, fixtures e convenções existentes antes de criar qualquer coisa.
5. Escreva os testes e execute-os.

## Modo refatorar

1. Leia os testes existentes, o código de produção, as fixtures e as factories.
2. Identifique duplicação, nome genérico, classe legada e arquivo fora do espelhamento.
3. Preserve a intenção de todo teste válido antes de mudar forma, nome ou camada.
4. Converta padrão legado para `pytest` funcional quando isso reduzir complexidade.
5. Consolide testes do mesmo módulo no arquivo que segue o espelhamento correto.
6. Remova sobras locais (`__pycache__`, arquivo temporário, diretório vazio) quando
   fizer parte do trabalho pedido.

## Princípios

- Comportamento acima de implementação: teste o resultado observável, não o detalhe interno.
- Menor escopo confiável: use o teste mais simples capaz de provar o comportamento.
- Determinismo: sem horário real, rede externa ou estado residual entre testes.
- Uma responsabilidade por teste.
- Código, nomes, variáveis e arquivos em inglês; docstrings e comentários em
  português brasileiro.

## Onde o teste mora

O teste mora **dentro do app**, num pacote que espelha a camada exercitada — mesma
lógica de sub-camadas da skill `django-layered-architecture`: o núcleo existe sempre,
o resto surge quando o app precisa.

```
src/<app>/tests/
├── factories/          sempre — factories dos models do app
├── unit_tests/         sempre — model, manager, queryset, validator, serializer
├── api_tests/          se o app expõe endpoint
│
├── controller_tests/   se há controller com regra de negócio
├── tasks_tests/        se há Celery
├── admin_tests/        se há customização de admin
├── integration_tests/  se há fluxo entre módulos
└── e2e_tests/          se há fluxo ponta a ponta
```

Critério de classificação:

| O teste... | vai em |
|---|---|
| faz request por `APIClient` | `api_tests/` |
| chama o controller direto | `controller_tests/` |
| exercita model, manager, queryset, validator ou serializer | `unit_tests/` |
| executa uma task Celery | `tasks_tests/` |

Na dúvida entre dois níveis, prefira o mais baixo: é mais rápido e menos frágil.
Dentro do pacote, espelhe o caminho do código de produção:

```
Código:  src/billing/controllers/invoice_generator.py
Teste:   src/billing/tests/controller_tests/test_invoice_generator.py
```

### Projeto legado

Esta estrutura é o alvo mesmo em projeto que hoje organiza a suíte de outro jeito.
A migração é **incremental**, nunca big bang:

- Teste novo nasce já no formato correto, ainda que os vizinhos não estejam.
- Ao mexer num teste existente por outro motivo, mova-o junto quando o movimento
  for pequeno e óbvio.
- Não reestruture a suíte inteira de uma vez, nem como efeito colateral de outra
  task: isso é trabalho próprio e precisa de aval do usuário.
- Informe o usuário ao notar a divergência, para ele decidir se quer priorizar a
  migração.

## A receita por camada

`references/test-recipes.md` traz, para cada camada, o mínimo obrigatório, a tabela
de **gatilhos no código que exigem teste específico** e o que **não** testar.
Consulte antes de escrever: é o que decide a cobertura, não o julgamento do momento.

No modo refatorar, a mesma receita diz o que preservar — não remova cobertura de um
comportamento que a receita marca como obrigatório.

## Regras obrigatórias

### Base

- Use `pytest` com `pytest-django`, em funções `test_...`. Não use
  `unittest.TestCase` sem pedido explícito.
- Nomes semânticos: `test_should_fail_when_age_is_under_18`, nunca `test_success`.
- Organize em Given / When / Then, com comentário curto só quando ajudar a leitura.
- Não invente factory, endpoint, regra de negócio ou fluxo que o código não sustenta.
- Não duplique o mesmo cenário em níveis diferentes sem motivo claro.

### Dados de teste

- As factories do app vivem em `<app>/tests/factories/` e são importadas pelo
  caminho do app: `from tags.tests.factories import TagsFactory`.
- Antes de criar factory, procure a factory existente daquele model. Crie nova
  apenas quando não houver.
- Fixture de escopo amplo (client autenticado, organização raiz, mock de infra)
  fica no `conftest.py` raiz. Fixture específica do app fica no `conftest.py` do
  app, e a de um único módulo fica junto dele.
- Crie apenas os dados mínimos necessários para provar o comportamento.

### Banco e ORM

- Prefira a fixture `db` a `@pytest.mark.django_db`, salvo necessidade explícita.
- Use `transactional_db` apenas quando o caso precisar de transação real.
- Não mocke o ORM quando a intenção for validar persistência, filtro, integridade
  ou consulta. Use o banco de teste.

### Isolamento multi-tenant

Em projeto multi-cliente, o vazamento entre tenants é a falha mais cara possível, e
o teste de caminho feliz nunca a pega — ele usa um tenant só.

- Todo endpoint que lista ou recupera dado de cliente tem teste provando que o
  usuário de um cliente **não** alcança o dado de outro.
- O teste cria dado nos dois tenants e afirma tanto a presença do próprio quanto a
  ausência do alheio.
- Vale também para manager e queryset que recortam por organização.

### Tempo e determinismo

- Nunca dependa do relógio real. Congele o tempo com `freezegun` sempre que o
  comportamento envolver vencimento, vigência, expiração, janela ou agendamento.
- Teste a **borda** do limite, não só o meio: o instante exato do vencimento, um
  segundo antes e um segundo depois.
- Não dependa de ordenação por timestamp gerado no próprio teste sem congelar o tempo.

### Performance de query

- Endpoint de listagem e queryset com `select_related`/`prefetch_related` têm teste
  de contagem de queries com `django_assert_num_queries`.
- Prove que a contagem **não escala** com o volume: rode a mesma asserção em dois
  volumes diferentes com o mesmo número esperado. Um número fixo medido uma vez só
  vira um teste que quebra sem indicar regressão real.
- Comente de onde veio o número esperado.

### Mocks e serviços externos

- Nunca faça chamada real a serviço externo, em nenhum nível de teste.
- Simule fronteira externa com fake nomeado, não com stub inline anônimo — um fake
  com nome documenta o contrato que está sendo simulado.
- Use `pytest-mock` (`mocker`) e `requests-mock` conforme o caso.
- Mocke a fronteira externa, não a lógica interna que o teste deveria exercitar.
- Não mocke todas as dependências quando o objetivo for validar a integração real
  entre camadas.

## Refatoração segura

Vale no modo refatorar:

- Não misture refatoração de teste com mudança de comportamento do código de produção.
- Preserve a intenção antes de alterar forma, nome, fixture ou camada.
- Não apague teste útil só porque está feio.
- Ao tocar em `unittest.TestCase`, converta para função `pytest` quando a intenção
  puder ser preservada.
- Não mova arquivo sem justificar pelo espelhamento.
- Ao consolidar, mantenha cada cenário coberto em um lugar claro e rastreável.
- Remova duplicação apenas quando os cenários forem de fato equivalentes.
- Não apague teste instável sem substituir por cobertura confiável ou explicar o risco.
- Em suíte grande ou sensível, converta em etapas pequenas.

## Testes frágeis

- Não teste detalhe interno, chamada privada ou ordem de chamadas sem valor funcional.
- Não dependa de ordenação quando a ordem não faz parte do contrato.
- Não use snapshot de payload completo sem necessidade clara.
- Prefira asserts explícitos, pequenos e ligados ao comportamento.
- No modo refatorar, troque assert acoplado a detalhe interno por assert comportamental.

## Execução

- **Execute os testes que você criou ou alterou, sem pedir permissão.** Rodar teste
  é barato e reversível; entregar sem validar, não.
- Rode escopado, não a suíte inteira. Prefira o alvo que o projeto expõe (Makefile,
  tox, nox, script do `pyproject.toml`); na ausência, chame o `pytest` direto no
  caminho alterado. Na iteração, use `-k`, `--lf` e `--maxfail=1`.
- Confira os markers registrados em `pyproject.toml` antes de criar um novo, e
  aplique os que o projeto já usa para infraestrutura (mock de fila, limpeza de
  cache, testes lentos).
- No modo refatorar, rode a suíte afetada **antes e depois** e compare: a refatoração
  não pode mudar o conjunto de testes que passa.
- Peça confirmação apenas para comando destrutivo ou de efeito externo: migration
  contra banco real, deploy, escrita em serviço de terceiro.
- **Nunca afirme que um teste passa sem ter executado o comando e lido a saída.**
  Se falhou, diga que falhou e mostre o erro.

## Exemplos

Nos exemplos abaixo, `db` e `django_assert_num_queries` são fixtures do
`pytest-django`. `api_client` e `api_root_user_org` são fixtures **de projeto** —
use as equivalentes do repositório em que você estiver.

Comportamento com Given / When / Then:

```python
def test_should_apply_discount_when_coupon_is_valid(db):
    """Deve aplicar o desconto no valor total quando um cupom válido for fornecido."""
    # Given
    order = OrderFactory(total=100)

    # When
    apply_coupon(order, code="PROMO10")

    # Then
    assert order.total == 90
```

Isolamento entre clientes — afirma presença e ausência:

```python
def test_should_not_return_alerts_from_another_organization(db, api_client, api_root_user_org):
    """Usuário de uma organização não deve enxergar alertas de outra."""
    # Given
    own = AlertsFactory(organization=api_root_user_org)
    other = AlertsFactory(organization=OrganizationsFactory())

    # When
    response = api_client.get("/api/v1/alerts")

    # Then
    returned_ids = [item["id"] for item in response.json()["results"]]
    assert own.id in returned_ids
    assert other.id not in returned_ids
```

Contagem de queries que não escala com o volume:

```python
def test_list_query_count_does_not_scale(db, api_client, django_assert_num_queries):
    """A contagem de consultas não deve crescer com o número de registros."""
    # Constante medida executando o teste e fixando o valor observado,
    # verificada em dois volumes distintos (5 e 15).
    expected = 5

    AlertsFactory.create_batch(5)
    with django_assert_num_queries(expected):
        api_client.get(self.API_URL)

    AlertsFactory.create_batch(10)
    with django_assert_num_queries(expected):
        api_client.get(self.API_URL)
```

## Critérios de revisão

Sempre:
1. O teste está no pacote de camada correto e espelha o caminho do código?
2. A receita da camada foi aplicada — obrigatórios cobertos, gatilhos atendidos?
3. O teste prova comportamento real, sem acoplar a detalhe de implementação?
4. Ficou determinístico: tempo congelado quando relevante, sem rede, sem estado residual?
5. Reutilizou factory existente, criando nova só quando não havia?
6. Os testes foram executados e a saída foi lida?

No modo criar:
7. Endpoint que expõe dado de cliente tem teste de isolamento entre tenants?
8. Listagem tem teste de contagem de queries?

No modo refatorar:
9. A suíte ficou mais simples e o comportamento coberto foi preservado?
10. O código de produção permaneceu intacto?
