---
name: python-tests
description: cria, amplia, refatora, redesenha e audita testes python com pytest para django com drf e fastapi com sqlmodel async. use quando o usuário pedir para criar testes, adicionar cobertura, escrever testes para função, service, model, endpoint ou fluxo, limpar ou redesenhar testes legados, montar a matriz de cenários de uma suíte, converter unittest para pytest, consolidar ou renomear testes, alinhar a suíte ao padrão atual ou avaliar a qualidade de uma suíte.
---

# Testes Python

## Objetivo

Criar, refatorar e auditar testes Python com `pytest`, consistentes com os padrões do repositório e capazes de provar comportamento real. O alvo é proteger os contratos necessários, não aumentar a quantidade de testes nem atingir um número de cobertura.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "crie testes para esse código" / "adicione cobertura para esse service" (modo criar)
- "refatore esses testes" / "converta para pytest" / "consolide os testes desse módulo" / "redesenhe a suíte legada desse app" (modo refatorar)
- "avalie essa suíte" / "o que falta testar aqui?" (modo auditar)

## Procedimento

1. Identifique o modo: **criar**, **refatorar** ou **auditar**. Pedido misto (criar testes num arquivo legado) usa os dois primeiros, nessa ordem de prioridade: criar o que foi pedido e propor a refatoração.
2. Identifique o framework do alvo e leia **só** a referência correspondente:
   - Django com DRF: [references/django-drf.md](references/django-drf.md);
   - FastAPI com SQLModel async: [references/fastapi-sqlmodel.md](references/fastapi-sqlmodel.md);
   - Python agnóstico: nenhuma.
3. Leia o código de produção, a responsabilidade do componente (invariantes, docs da área, `AGENTS.md` da pasta de testes), os testes existentes e as fixtures/factories relacionadas. O padrão já usado pelo projeto prevalece sobre as referências; elas valem quando o projeto ainda não tem padrão.
4. Procure `unittest` nos arquivos de teste do escopo (ver "unittest") e informe o que encontrar.
5. Para escolher o que cobrir ou o que preservar, consulte [references/scenarios-by-target.md](references/scenarios-by-target.md).
6. Recorte com mais de um punhado de testes, ou qualquer redesenho de legado: monte a matriz de cenários antes de escrever código, no formato de [references/test-matrix-template.md](references/test-matrix-template.md), e avance em blocos pequenos. A aprovação de um bloco não autoriza implementar a matriz inteira.
7. Siga a seção do modo e execute testes conforme "Execução".

## Padrões comuns

### Princípios

- Comportamento > implementação: teste o resultado observável, não detalhes internos.
- Menor escopo confiável: use o menor tipo de teste capaz de provar o comportamento sem perder fidelidade (ver "Modalidade").
- Determinismo: não dependa de horário real, rede externa, aleatoriedade sem seed ou estado residual.
- Uma responsabilidade por teste.
- Código, nomes, variáveis e arquivos em inglês; docstrings e comentários em português brasileiro. Todo teste tem docstring clara em português brasileiro.

### Organização

Use o layout que o projeto já adota. Sem padrão, espelhe o diretório do app (`src/`, `app/` ou a raiz da aplicação) dentro de uma pasta por modalidade:

- `tests/unit/`: funções puras, validações de domínio, serializers, utilitários e lógica sem I/O real.
- `tests/integration/`: persistência, requests HTTP locais, service + repository, cache, filas e integração entre módulos.
- `tests/e2e/`: jornadas completas pelas interfaces públicas.

Exemplo: `app/billing/services/invoice_generator.py` → `tests/unit/billing/services/test_invoice_generator.py` e `tests/integration/billing/services/test_invoice_generator.py`. Projetos com testes dentro de cada app costumam usar `unit_tests/`, `integration_tests/` e `e2e_tests/`, com as pastas de contexto também sufixadas (`models_tests/user_tests/test_receivers.py` para `models/user/receivers.py`); siga a variante que o projeto escolheu.

- Espelhe o local da implementação, não o tipo do mecanismo: receivers de `models/user/receivers.py` ficam em `.../user/test_receivers.py`, não numa pasta genérica `signals/`.
- Não mova arquivos sem justificar pelo espelhamento, não crie diretórios vazios nem uma modalidade só para completar a árvore, e não crie arquivo novo numa estrutura antiga por imitação do legado.
- Não duplique cenários idênticos em `unit` e `integration` sem motivo claro.
- Efeitos de domínio de outro módulo ou app ficam nos testes dele; não copie a suíte vizinha para testar uma integração.
- Toda `@pytest.fixture` fica no `conftest.py` da pasta, nunca dentro de `test_*.py`, no menor contexto compartilhado que a usa. Fixture que só vale para um arquivo entra no `conftest.py` sem `autouse` e é ativada no arquivo por `pytest.mark.usefixtures` (ou recebida como argumento).
- Módulo auxiliar dentro das pastas de teste (fake, cenário, sonda, constantes compartilhadas) começa com `_`, por exemplo `_clock_fake.py`. Ficam sem o prefixo só `test_*.py`, `conftest.py`, `__init__.py` e o módulo de factories que o projeto já usa. Se o projeto tiver convenção própria, ela prevalece.

### Modalidade

Classifique pelo comportamento e pela fronteira comprovados, não pela quantidade de camadas percorridas, pelo nome da ferramenta ou por começar num endpoint.

| Modalidade | Responsabilidade |
|---|---|
| Unitário | Regra isolada sem banco, cache, rede ou filesystem reais. Instância não persistida de model é aceitável quando o comportamento não depende de I/O. |
| Integração | Persistência, relações do ORM, signals registrados, transações, cache real e HTTP local atravessando as camadas relevantes, inclusive com autenticação forçada ou conferência pelo ORM. |
| E2E | Jornada completa pela interface pública, com autenticação real quando ela faz parte da jornada e resultado conferido pelas interfaces públicas. Use só quando acrescentar uma garantia que a integração não dá. |

- Começar pela API não torna o teste E2E: request pelo cliente de teste com `force_authenticate` ou conferência pelo ORM é integração. E2E não usa atalho de autenticação para um passo que pertence à jornada nem prova o resultado final só pelo banco; fixtures podem preparar as precondições.
- E2E de backend não exige navegador nem servidor separado. Documente no módulo se roda no processo de testes ou por HTTP real e quais fronteiras ficam fora (provedor externo, frontend, ingress).
- Não chame de unitário um teste que substitui `save`, managers ou relações por mocks. Confira as dependências da factory: `build()` não garante ausência de banco se um atributo lazy criar outro registro.
- Antes de criar o teste, registre na matriz a modalidade, a fronteira exercitada e os atalhos do cenário (autenticação forçada, dependências simuladas, consultas diretas ao banco). Na revisão, se o cenário não exercita a fronteira declarada, ajuste a modalidade ou o cenário.

### Regras obrigatórias

- Use sempre `pytest`, com funções `test_...` em arquivos `test_<assunto>.py`; sem classes `Test*` (fakes nomeadas continuam sendo classes).
- Nomes semânticos, como `test_should_fail_when_age_is_under_18`; evite `test_success`, `test_error` e arquivos `*_coverage.py`.
- Organize em Given / When / Then. Os comentários de fase entram quando o teste tem preparo, ação e conferência distintos; ficam de fora nos testes de duas ou três linhas.
- Fixtures pequenas e reutilizáveis, conforme "Organização". Evite `conftest.py` global grande.
- Crie apenas os dados mínimos necessários e fixe os valores que decidem o resultado.
- Use factories para objetos complexos, com imports explícitos (ex.: `from tests.factories.factory_user import UserFactory`). Antes de criar uma factory, procure uma existente para aquele model; crie nova só quando não houver.
- Estado legado que a validação atual recusaria: se o projeto tiver helper explícito de escrita sem validação para testes, use-o; não simule um preparo válido que esconda o estado inválido nem contorne a validação com escrita crua.
- Não faça chamadas reais para serviços externos em testes unitários ou de integração locais.
- Simule só as fronteiras externas (provedor de e-mail, gateway, relógio, rede), com fakes nomeadas em módulos `_*.py`. Prefira `monkeypatch`, fakes ou overrides de dependência a mocks acoplados à implementação.
- Não mocke a lógica que o teste pretende provar: queryset falso, `MagicMock` do controller ou do model, `patch` da regra acionada. Teste assim passa sem a regra e fixa o defeito como contrato.
- O preparo exercita o caminho de produção. Se a configuração de teste desliga uma trava, troca a classe de autenticação ou o backend (ex.: `DEBUG` ligado, host ausente, e-mail em memória implícito), ligue o caminho real quando ele for parte do comportamento medido e declare a fake quando não for.
- Senha ou token fictício que dispara detector de segredos (Bandit, gitleaks, detect-secrets): use constante com nome claro e a supressão pontual que o projeto adota, com o motivo; não troque o valor por um que mude o cenário.
- Não invente factories, endpoints, regras de negócio ou fluxos não sustentados pelo código.
- Se a suíte estiver ambígua, decida pelo comportamento real do código, não por convenções antigas.
- Rota, view ou método removido não leva teste de 404/405 confirmando a remoção.

### Asserções que medem a regra

- Confira efeitos observáveis: valores persistidos, vínculos, resposta, auditoria, mensagens enviadas e, nas recusas, a ausência de alteração indevida. Uma exceção ou um status isolado pode ser insuficiente.
- Tenha ao menos uma asserção que só o comportamento correto satisfaz. Conferir apenas o lado que o defeito provável também produz (a conta zerada, quando o defeito zera todas) não mede a regra; confira também o que deveria ser preservado.
- Rollback: prove que o efeito aconteceu antes da falha provocada e que o estado relevante foi restaurado depois. Um 500 sozinho não prova rollback.
- Signals e hooks: dispare pelo caminho real (save, delete, endpoint) e confira o efeito do receiver registrado. Mockar `send` ou o receiver não prova nada.
- Não acople preparo nem asserção ao mecanismo que implementa a regra (cache privado, `cache_clear()` de um `@cache` que é a regra, nome de atributo interno). Prepare o cenário por dados; remover o mecanismo deve fazer o teste falhar numa asserção, não no setup.
- Teste que caracteriza comportamento atual duvidoso (um 400 que deveria ser 200) não vira contrato em silêncio: ou é decisão registrada, ou o docstring aponta a lacuna.

### unittest

O padrão é sempre `pytest`. Em qualquer modo, ao encontrar nos arquivos de teste do escopo `unittest.TestCase`, `django.test.TestCase`/`TransactionTestCase`/`SimpleTestCase`, `rest_framework.test.APITestCase`, `setUp`/`tearDown` ou `self.assert*`:

1. Informe o usuário: arquivo, classe e quantidade aproximada de testes.
2. Sugira a conversão para `pytest` funcional, com o equivalente de cada recurso (`setUp` → fixture, `self.assertEqual` → `assert`, `self.client` → fixture `api_client`, `TestCase` do Django → fixture `db`).
3. No modo criar, escreva os testes novos em `pytest` no arquivo espelhado; não converta os testes legados sem confirmação.
4. No modo refatorar, a conversão faz parte do trabalho.

`unittest.mock` não é estilo de teste: pode continuar. Se o projeto tiver `pytest-mock`, sugira `mocker` ao tocar no arquivo, sem tratar como migração obrigatória.

### parametrize

- Bordas da mesma regra (limite, abaixo, acima, vazio) viram um teste com `pytest.mark.parametrize` e `ids` legíveis.
- Cenários com setup, fluxo ou assert diferentes ficam em testes separados; não force `parametrize` com `if` dentro do teste.
- Matriz de permissão (anônimo, papel inferior, papel permitido, recurso alheio) é um `parametrize` com o status esperado de cada papel; o como fica na referência do framework.

### Tempo, concorrência e aleatoriedade

- Use o que o projeto já usa. Sem padrão, congele o tempo com `time-machine` ou `freezegun` (ou injete um relógio fake) sempre que o instante decidir a expectativa: vencimento, expiração, janela temporal, timestamps. Teste a borda exata (um segundo antes, no limite, um segundo depois).
- Biblioteca que confere o tempo pelo relógio real por dentro (ex.: `pyjwt` com `iat`/`exp`): o relógio fixo parte do segundo atual e só avança; um instante no passado ou no futuro faz o token ser recusado por outro motivo.
- Nunca use `sleep` para sincronizar. Concorrência real (trava de linha, disputa entre transações) usa conexões e threads reais, `threading.Event`/`Barrier` com timeout, e fecha conexões e libera threads em `finally`.
- Dados aleatórios (`faker`, sequências de factory) não podem decidir o resultado: fixe o valor relevante para o assert ou use seed fixa. Factory que sorteia relação (pai, cliente) pode cair no caso errado; fixe-a quando ela decide o cenário.

### Testes frágeis

- Não teste chamadas privadas ou ordem de chamadas sem valor funcional.
- Não dependa de ordenação quando a ordem não fizer parte do contrato.
- Não use snapshots de payload completo sem necessidade clara.
- Prefira asserts explícitos, pequenos e ligados ao comportamento; nada de `assert a or b` que passa com qualquer um dos lados.
- Não mocke todas as dependências quando o objetivo for validar integração local real.

## Modo criar

1. Classifique cada teste como `unit`, `integration` ou `e2e` (ver "Modalidade") antes de escrevê-lo.
2. Cubra os cenários relevantes para o comportamento pedido: caminho feliz, validações e erros esperados, bordas do domínio, permissões, efeitos colaterais observáveis (persistência, eventos, cache, filas) e a regressão específica quando for correção de bug.
3. Em listagens e detalhes com relacionamentos, fixe o número de queries (ver referência do framework).
4. No RED de um ciclo TDD, o código ainda não existe: parta do comportamento esperado e da assinatura pretendida (módulo, função ou endpoint) e não invente detalhes internos. O teste deve falhar pelo motivo funcional esperado; falha por import, fixture, sintaxe ou preparo não é RED.
5. Comportamento que já existe não tem RED a fabricar: não altere produção para ver o teste falhar. Para medir a força das asserções, mute o código numa cópia temporária (ou pelo catálogo de mutantes, se o projeto tiver um) e confirme que a suíte falha por asserção.

Exemplo:

```python
def test_should_apply_discount_when_coupon_is_valid(db):
    """
    Deve aplicar o desconto no valor total quando um cupom válido for fornecido.
    """
    # Given
    user = UserFactory()
    order = OrderFactory(user=user, total=100)

    # When
    apply_coupon(order, code="PROMO10")

    # Then
    assert order.total == 90
```

## Modo refatorar

- Comece identificando duplicações, nomes genéricos, classes legadas, mocks da própria lógica e arquivos fora do espelhamento.
- Melhore testes existentes sem mudar o comportamento validado. Não misture refatoração de testes com mudança no código de produção.
- Rode os testes focados antes e depois: a mesma quantidade de testes deve passar (descontados os removidos por duplicação comprovada).
- Preserve a intenção antes de alterar forma, nome, fixture ou camada. Não apague teste útil só porque está feio, é difícil ou falha.
- Converta padrões legados para `pytest` funcional (ver "unittest"); em suíte grande ou sensível, converta em etapas pequenas.
- Consolide testes do mesmo módulo no arquivo espelhado, mantendo cada cenário em local claro e rastreável.
- Remova duplicações apenas quando os cenários forem equivalentes de fato, registrando qual teste passa a guardar o comportamento.
- Não preserve assert acoplado a detalhe interno se houver assert comportamental melhor.
- Não apague teste instável sem substituir por cobertura confiável ou explicar o risco. Não desative a coleta nem use `skip`/`xfail` para esconder regressão.
- Remova sobras locais (`__pycache__`, arquivos temporários, diretórios vazios) quando fizer parte do trabalho pedido.

### Redesenho de suíte legada

Mover ou copiar arquivos não basta quando nome, preparo, camada ou asserções não expressam a responsabilidade do teste. Para redesenhar um app ou módulo inteiro, siga [references/legacy-suite-redesign.md](references/legacy-suite-redesign.md): matriz com o destino de cada cenário legado → baseline → redesenho em blocos → reancorar mutantes → remover o legado substituído → contagem antes e depois. O legado ainda não analisado continua ativo até o bloco correspondente fechar.

### Defeito de produção encontrado em etapa de testes

Análise ou redesenho de testes não autoriza mudar produção. Ao descobrir um defeito: reproduza-o com um teste que falha pela regra, registre-o (onde, achado, proposta) e corrija só com autorização do usuário. Enquanto não houver decisão, não fixe o defeito como contrato nem o esconda com `skip`/`xfail`; deixe o achado na matriz e na resposta final.

## Modo auditar

Somente leitura: não altere arquivos. Entregue uma lista priorizada com arquivo e linha:

1. Comportamentos do código de produção sem teste, começando por regra de negócio, permissão e escrita persistente.
2. Testes que não falhariam se o código testado quebrasse: assert fraco ou com `or`, mock que substitui o próprio alvo (queryset falso, `MagicMock` do controller), fixture que não cria o que o teste supõe, asserção que o defeito provável também satisfaz.
3. Testes cujo preparo passa por outro caminho que não o de produção (trava ou autenticação desligada pelo ambiente de teste, backend implícito) e testes que caracterizam um defeito como contrato.
4. Testes frágeis (ver "Testes frágeis") e testes não determinísticos (relógio real, `sleep`, relação sorteada pela factory).
5. Cenários duplicados entre arquivos ou camadas e modalidade mal classificada (integração chamada de E2E, unitário com mock do ORM).
6. Arquivos em `unittest` (ver "unittest"), fora do espelhamento, fixtures fora do `conftest.py` e testes de rota removida.

Para cada item, sugira a correção em uma linha. Termine com a recomendação de por onde começar.

## Execução

- Rode sem perguntar os testes focados: arquivos de teste criados, alterados ou reorganizados (`pytest <arquivo>` ou `-k <nome>`).
- Pergunte antes de rodar a suíte completa, `make ci`, lint ou typecheck do projeto inteiro e build.
- Se o teste focado falhar por infraestrutura (banco, Docker, variável de ambiente), pare e informe; não suba serviços por conta própria.
- Se o usuário preferir executar os testes, informe os comandos relevantes em vez de rodá-los.
- Não afirme que algo foi testado se o comando não foi executado.

## Resposta final

Entregue a resposta final em tabelas Markdown: a tabela do modo usado e, depois, a tabela de verificação. Texto fora das tabelas só para uma frase de resumo no início e a recomendação de próximo passo no fim.

**Criar** — uma linha por comportamento coberto; factories e fixtures novas entram como linhas próprias, com o motivo em "Comportamento":

| Arquivo de teste | Camada | Comportamento | Resultado |
|---|---|---|---|
| `tests/unit/shipping/test_freight_calculator.py` | unit | pedido acima de R$ 500 tem frete zero | passou |

**Refatorar** — uma linha por arquivo alterado, e uma por teste removido, com a justificativa:

| Arquivo | O que mudou | Testes antes → depois |
|---|---|---|
| `tests/integration/orders/test_checkout.py` | convertido de `APITestCase` para `pytest` | 12 → 12 passando |

No redesenho de suíte legada, acrescente a tabela de destino descrita em [references/legacy-suite-redesign.md](references/legacy-suite-redesign.md).

**Auditar** — ordenada por prioridade:

| # | Onde | Problema | Correção sugerida |
|---|---|---|---|
| 1 | `orders/services/refund.py:40` | regra de estorno parcial sem teste | testar estorno parcial e total no service |

**Verificação** (todos os modos) — omitir a linha que não se aplicar:

| Item | Detalhe |
|---|---|
| Comandos executados | `pytest tests/unit/shipping/test_freight_calculator.py` → 3 passaram |
| `unittest` encontrado | `tests/test_orders.py`, `OrderTests(TestCase)`, 8 testes → sugerida troca por `pytest` |
| Mutantes | criados, alterados ou reancorados → mortos por asserção, equivalentes ou lacuna conhecida |
| Defeito de produção | onde, como foi reproduzido e se foi corrigido com autorização ou ficou registrado |
| Sem teste (risco) | cenário relevante não coberto e o risco residual |
| Não executado | o que não rodou e o comando para rodar |

## Critérios de revisão

Antes de entregar, confirme:
1. O arquivo de teste está na modalidade correta, pela fronteira comprovada, e segue o espelhamento?
2. Cada teste prova comportamento real, falharia por asserção sem o código testado (não por import ou setup) e evita acoplamento à implementação e ao mecanismo da regra?
3. Só as fronteiras externas foram simuladas, com fakes nomeadas, e o preparo passa pelo caminho de produção?
4. Os testes ficaram determinísticos e isolados de rede externa, horário real, `sleep` e estado compartilhado?
5. Foram reutilizadas factories e fixtures existentes, com toda fixture em `conftest.py` e sem fixture global ou factory duplicada desnecessária?
6. `unittest` encontrado foi informado, com a sugestão de troca por `pytest`?
7. No modo refatorar: a suíte ficou mais simples de manter, sem padrões legados evitáveis, com o comportamento coberto preservado, o código de produção intocado e a contagem de testes conferida antes e depois? No redesenho, todo cenário legado tem destino registrado?
8. Defeito de produção encontrado foi reproduzido e registrado, sem correção não autorizada, `skip`/`xfail` ou caracterização enganosa?
9. Os testes focados foram executados, e o usuário foi consultado antes de validações amplas?
10. A resposta final segue "Resposta final" do modo usado?
