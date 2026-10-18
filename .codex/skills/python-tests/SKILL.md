---
name: python-tests
description: cria, amplia, refatora e audita testes python com pytest para django com drf e fastapi com sqlmodel async. use quando o usuário pedir para criar testes, adicionar cobertura, escrever testes para função, service, model, endpoint ou fluxo, limpar testes legados, converter unittest para pytest, consolidar ou renomear testes, alinhar a suíte ao padrão atual ou avaliar a qualidade de uma suíte.
---

# Testes Python

## Objetivo

Criar, refatorar e auditar testes Python com `pytest`, consistentes com os padrões do repositório e capazes de provar comportamento real.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "crie testes para esse código" / "adicione cobertura para esse service" (modo criar)
- "refatore esses testes" / "converta para pytest" / "consolide os testes desse módulo" (modo refatorar)
- "avalie essa suíte" / "o que falta testar aqui?" (modo auditar)

## Procedimento

1. Identifique o modo: **criar**, **refatorar** ou **auditar**. Pedido misto (criar testes num arquivo legado) usa os dois primeiros, nessa ordem de prioridade: criar o que foi pedido e propor a refatoração.
2. Identifique o framework do alvo e leia **só** a referência correspondente:
   - Django com DRF: [references/django-drf.md](references/django-drf.md);
   - FastAPI com SQLModel async: [references/fastapi-sqlmodel.md](references/fastapi-sqlmodel.md);
   - Python agnóstico: nenhuma.
3. Leia o código de produção, os testes existentes e as fixtures/factories relacionadas. O padrão já usado pelo projeto prevalece sobre as referências; elas valem quando o projeto ainda não tem padrão.
4. Procure `unittest` nos arquivos de teste do escopo (ver "unittest") e informe o que encontrar.
5. Para escolher o que cobrir ou o que preservar, consulte [references/scenarios-by-target.md](references/scenarios-by-target.md).
6. Siga a seção do modo e execute testes conforme "Execução".

## Padrões comuns

### Princípios

- Comportamento > implementação: teste o resultado observável, não detalhes internos.
- Menor escopo confiável: use o menor tipo de teste capaz de provar o comportamento sem perder fidelidade.
- Determinismo: não dependa de horário real, rede externa, aleatoriedade sem seed ou estado residual.
- Uma responsabilidade por teste.
- Código, nomes, variáveis e arquivos em inglês; docstrings e comentários em português brasileiro. Todo teste tem docstring clara em português brasileiro.

### Organização

Espelhe o diretório do app (`src/`, `app/` ou a raiz da aplicação):

- `tests/unit/`: funções puras, validações de domínio, serializers, utilitários e lógica sem I/O real.
- `tests/integration/`: persistência, requests HTTP locais, service + repository, cache, filas e integração entre módulos.
- `tests/e2e/`: fluxos completos do usuário atravessando múltiplas camadas.

Exemplo: `app/billing/services/invoice_generator.py` → `tests/unit/billing/services/test_invoice_generator.py` e `tests/integration/billing/services/test_invoice_generator.py`.

Não mova arquivos sem justificar pelo espelhamento. Não duplique cenários idênticos em `unit` e `integration` sem motivo claro.

### Regras obrigatórias

- Use sempre `pytest`, com funções `test_...`.
- Nomes semânticos, como `test_should_fail_when_age_is_under_18`; evite `test_success` e `test_error`.
- Organize em Given / When / Then, com comentários curtos apenas quando agregarem leitura.
- Fixtures pequenas e reutilizáveis; extraia setup repetido para fixtures locais. Evite `conftest.py` global grande; prefira fixtures por módulo ou pasta.
- Crie apenas os dados mínimos necessários para provar o comportamento.
- Use factories para objetos complexos, com imports explícitos (ex.: `from tests.factories.factory_user import UserFactory`). Antes de criar uma factory, procure uma existente para aquele model; crie nova só quando não houver.
- Não faça chamadas reais para serviços externos em testes unitários ou de integração locais.
- Prefira `monkeypatch`, fakes ou overrides de dependência a mocks acoplados à implementação.
- Não invente factories, endpoints, regras de negócio ou fluxos não sustentados pelo código.
- Se a suíte estiver ambígua, decida pelo comportamento real do código, não por convenções antigas.

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

### Tempo e aleatoriedade

- Use o que o projeto já usa. Sem padrão, congele o tempo com `time-machine` ou `freezegun` em testes de vencimento, expiração, janela temporal e timestamps.
- Dados aleatórios (`faker`, sequências de factory) não podem decidir o resultado: fixe o valor relevante para o assert ou use seed fixa.

### Testes frágeis

- Não teste chamadas privadas ou ordem de chamadas sem valor funcional.
- Não dependa de ordenação quando a ordem não fizer parte do contrato.
- Não use snapshots de payload completo sem necessidade clara.
- Prefira asserts explícitos, pequenos e ligados ao comportamento.
- Não mocke todas as dependências quando o objetivo for validar integração local real.

## Modo criar

1. Classifique cada teste como `unit`, `integration` ou `e2e` (ver "Organização") antes de escrevê-lo.
2. Cubra os cenários relevantes para o comportamento pedido: caminho feliz, validações e erros esperados, bordas do domínio, permissões, efeitos colaterais observáveis (persistência, eventos, cache, filas) e a regressão específica quando for correção de bug.
3. Em listagens e detalhes com relacionamentos, fixe o número de queries (ver referência do framework).
4. No RED de um ciclo TDD, o código ainda não existe: parta do comportamento esperado e da assinatura pretendida (módulo, função ou endpoint) e não invente detalhes internos. O teste deve falhar pelo motivo esperado; falha por import, fixture ou setup não conta.

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

- Comece identificando duplicações, nomes genéricos, classes legadas e arquivos fora do espelhamento.
- Melhore testes existentes sem mudar o comportamento validado. Não misture refatoração de testes com mudança no código de produção.
- Rode os testes focados antes e depois: a mesma quantidade de testes deve passar (descontados os removidos por duplicação comprovada).
- Preserve a intenção antes de alterar forma, nome, fixture ou camada. Não apague teste útil só porque está feio.
- Converta padrões legados para `pytest` funcional (ver "unittest"); em suíte grande ou sensível, converta em etapas pequenas.
- Consolide testes do mesmo módulo no arquivo espelhado, mantendo cada cenário em local claro e rastreável.
- Remova duplicações apenas quando os cenários forem equivalentes de fato.
- Não preserve assert acoplado a detalhe interno se houver assert comportamental melhor.
- Não apague teste instável sem substituir por cobertura confiável ou explicar o risco.
- Remova sobras locais (`__pycache__`, arquivos temporários, diretórios vazios) quando fizer parte do trabalho pedido.

## Modo auditar

Somente leitura: não altere arquivos. Entregue uma lista priorizada com arquivo e linha:

1. Comportamentos do código de produção sem teste, começando por regra de negócio, permissão e escrita persistente.
2. Testes que não falhariam se o código testado quebrasse (assert fraco, mock que substitui o próprio alvo, fixture que não cria o que o teste supõe).
3. Testes frágeis (ver "Testes frágeis") e testes não determinísticos.
4. Cenários duplicados entre arquivos ou camadas.
5. Arquivos em `unittest` (ver "unittest") e fora do espelhamento.

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

**Auditar** — ordenada por prioridade:

| # | Onde | Problema | Correção sugerida |
|---|---|---|---|
| 1 | `orders/services/refund.py:40` | regra de estorno parcial sem teste | testar estorno parcial e total no service |

**Verificação** (todos os modos) — omitir a linha que não se aplicar:

| Item | Detalhe |
|---|---|
| Comandos executados | `pytest tests/unit/shipping/test_freight_calculator.py` → 3 passaram |
| `unittest` encontrado | `tests/test_orders.py`, `OrderTests(TestCase)`, 8 testes → sugerida troca por `pytest` |
| Sem teste (risco) | cenário relevante não coberto e o risco residual |
| Não executado | o que não rodou e o comando para rodar |

## Critérios de revisão

Antes de entregar, confirme:
1. O arquivo de teste está na camada correta e segue o espelhamento?
2. Cada teste prova comportamento real, falharia sem o código testado e evita acoplamento desnecessário à implementação?
3. Os testes ficaram determinísticos e isolados de rede externa, horário real e estado compartilhado?
4. Foram reutilizadas factories e fixtures existentes, sem fixture global ou factory duplicada desnecessária?
5. `unittest` encontrado foi informado, com a sugestão de troca por `pytest`?
6. No modo refatorar: a suíte ficou mais simples de manter, sem padrões legados evitáveis, com o comportamento coberto preservado, o código de produção intocado e a contagem de testes conferida antes e depois?
7. Os testes focados foram executados, e o usuário foi consultado antes de validações amplas?
8. A resposta final segue "Resposta final" do modo usado?
