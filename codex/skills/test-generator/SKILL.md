---
name: test-generator
description: gera ou amplia testes em python com pytest para django e fastapi, usando os padrões de teste incorporados nesta skill. use quando o usuário pedir para criar testes, adicionar cobertura, escrever testes para uma função, serviço, model, endpoint, controller ou fluxo.
---

# Geração de Testes

## Objetivo

Criar ou complementar testes Python de forma consistente com os padrões do repositório.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "crie testes para esse código"
- "adicione cobertura para esse service"
- "gere testes para esse endpoint"
- "escreva testes para esse model"
- "complete os testes dessa função"

## Saída esperada

Criar ou atualizar testes em `tests/unit/`, `tests/integration/` ou `tests/e2e/`, conforme a camada correta. Os testes devem seguir os padrões incorporados nesta skill.

## Procedimento

Quando esta skill for usada:
1. Leia o código de produção, testes existentes e fixtures/factories relacionadas.
2. Identifique se o alvo pertence a Django, FastAPI ou código Python agnóstico.
3. Classifique o teste como `unit`, `integration` ou `e2e`.
4. Reutilize factories, fixtures e convenções existentes antes de criar novos elementos.
5. Espelhe o caminho do código de produção no caminho do teste.
6. Gere testes orientados a comportamento, não a detalhes internos.

## Princípios

- Comportamento > implementação: teste o resultado esperado, não detalhes internos.
- Menor escopo confiável: use o menor tipo de teste capaz de provar o comportamento sem perder fidelidade.
- Determinismo: não dependa de horário real, rede externa ou estado residual.
- Código, nomes, variáveis e arquivos devem estar em inglês.
- Docstrings e comentários devem estar em português brasileiro.
- Prefira uma responsabilidade por teste.

## Organização

Estruture os testes espelhando o diretório do app, como `src/`, `app/` ou a pasta raiz da aplicação:

- `tests/unit/`: funções puras, validações de domínio, serializers, utilitários e lógica sem I/O real.
- `tests/integration/`: persistência, requests HTTP locais, service + repository, cache, filas e integração entre módulos.
- `tests/e2e/`: fluxos completos do usuário atravessando múltiplas camadas.

Exemplo de espelhamento:

- Código: `app/billing/services/invoice_generator.py`
- Unit: `tests/unit/billing/services/test_invoice_generator.py`
- Integration: `tests/integration/billing/services/test_invoice_generator.py`

## Regras obrigatórias

- Use `pytest`.
- Prefira funções `test_...`; não use `unittest.TestCase`, salvo pedido explícito.
- Use nomes semânticos, como `test_should_fail_when_age_is_under_18`; evite `test_success` e `test_error`.
- Organize o teste em Given / When / Then, com comentários curtos apenas quando agregarem leitura.
- Prefira fixtures pequenas e reutilizáveis; extraia setup repetido para fixtures locais.
- Use factories para objetos complexos quando existirem; imports devem ser explícitos, como `from tests.factories.factory_user import UserFactory`.
- Crie apenas os dados mínimos necessários para provar o comportamento.
- Em Django, prefira a fixture `db` a `@pytest.mark.django_db`, salvo necessidade explícita.
- Em Django, use `transactional_db` apenas quando o caso precisar de transação real.
- Em Django, teste models, managers, querysets, services, sinais, views e endpoints com foco em comportamento observável.
- Em Django, evite mockar o ORM quando a intenção for validar persistência, filtros, integridade ou consultas.
- Em FastAPI, teste contrato HTTP completo: `status_code`, payload, headers e efeitos colaterais relevantes.
- Em FastAPI, use `TestClient` ou `AsyncClient`, conforme o estilo da aplicação.
- Em FastAPI, se a rota ou dependência for assíncrona, prefira testes assíncronos com `pytest.mark.asyncio` ou a estratégia async padrão do projeto.
- Em FastAPI, use `dependency_overrides` para isolar autenticação, gateways e clients de terceiros.
- Não faça chamadas reais para serviços externos em testes unitários ou de integração locais.
- Prefira `monkeypatch`, fakes ou `dependency_overrides` a mocks excessivamente acoplados à implementação.
- Não invente factories, endpoints, regras de negócio ou fluxos não sustentados pelo código.
- Não duplique cenários idênticos em `unit` e `integration` sem motivo claro.

## Exemplo

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

## Critérios de revisão

Antes de entregar, confirme:
1. O arquivo de teste foi salvo na camada correta?
2. O teste prova comportamento real?
3. O teste segue o espelhamento definido nesta skill?
4. O teste evita acoplamento desnecessário à implementação?
5. O teste ficou determinístico e isolado de rede externa, horário real e estado compartilhado?
