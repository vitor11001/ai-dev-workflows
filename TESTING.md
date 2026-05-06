# TESTING.md - Guia de Testes para Humanos e LLMs

Este documento define os padrões de engenharia de testes do repositório. LLMs como Codex, GPT e Gemini devem usar este arquivo como contexto obrigatório ao gerar, revisar ou refatorar testes em Python.

O guia cobre dois cenários principais:

- `pytest + Django`
- `pytest + FastAPI`

## Princípios de Ouro

1. **Comportamento > Implementação:** teste o resultado esperado, não os detalhes internos.
2. **Nomenclatura Semântica:** o nome do teste deve ser uma frase explicativa em inglês.
3. **Linguagem:**
   - **Código (nomes, variáveis e arquivos):** inglês (`en-US`).
   - **Documentação (docstrings e comentários):** português brasileiro (`pt-BR`).
4. **Menor Escopo Confiável:** prefira o menor tipo de teste capaz de provar o comportamento sem perder fidelidade.
5. **Determinismo:** testes devem ser reproduzíveis, sem depender de horário real, rede externa ou estado residual.

## Arquitetura e Organização

A estrutura de testes deve espelhar o diretório do app, como `src/`, `app/` ou a pasta raiz da aplicação.

| Tipo | Localizacao | Criterio de Uso |
| :--- | :--- | :--- |
| **Unit** | `tests/unit/` | Funções puras, validações de domínio, serializers, utilitários e lógica sem I/O real. |
| **Integration** | `tests/integration/` | Persistência, requests HTTP locais, service + repository, cache, filas e integração entre módulos. |
| **E2E** | `tests/e2e/` | Fluxos completos do usuário atravessando múltiplas camadas. |

### Regra de Mirroring

- **App:** `app/billing/services/invoice_generator.py`
- **Teste unitário:** `tests/unit/billing/services/test_invoice_generator.py`
- **Teste de integração:** `tests/integration/billing/services/test_invoice_generator.py`

## Padrões Pytest Obrigatórios

Ao gerar código Python, siga estes padrões:

- **Estilo funcional:** use funções (`def test_...`) e evite classes (`TestClass`).
- **Docstrings em pt-BR:** descreva o cenário de forma clara e concisa.
- **Given / When / Then:** organize o teste nessa ordem, com comentarios curtos apenas quando agregarem leitura.
- **Uma responsabilidade por teste:** cada teste deve validar um comportamento claro.
- **Fixtures pequenas e reutilizáveis:** extraia setup repetido para fixtures locais.

### Exemplo de Anatomia de um Teste

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

## Regras Específicas para Django

- Use `pytest` com `pytest-django`.
- Para acesso ao banco, prefira a fixture `db` como argumento em vez de `@pytest.mark.django_db`.
- Para casos que precisem de transação real, use `transactional_db` apenas quando necessário.
- Teste models, managers, querysets, services e sinais com foco em comportamento observavel.
- Para views e endpoints Django, prefira `client`, `admin_client` ou fixtures locais equivalentes.
- Evite mockar o ORM quando a intenção for validar persistência, filtros, integridade ou consultas.
- Ao testar validações ou regras de domínio ligadas a models, use factories e dados mínimos.

### Exemplo Django

```python
def test_should_persist_invoice_with_calculated_total(db):
    """
    Deve persistir a fatura com o total calculado a partir dos itens informados.
    """
    # Given
    customer = CustomerFactory()

    # When
    invoice = create_invoice(customer=customer, items=[{"amount": 40}, {"amount": 60}])

    # Then
    assert invoice.total == 100
    assert Invoice.objects.filter(id=invoice.id).exists()
```

## Regras Específicas para FastAPI

- Use `pytest` com `httpx` e `TestClient` ou `AsyncClient`, conforme o estilo da aplicacao.
- Se a rota ou dependência for assíncrona, prefira testes assíncronos com `pytest.mark.asyncio` ou a estratégia async padrão do projeto.
- Teste contratos HTTP completos: `status_code`, payload, headers e efeitos colaterais relevantes.
- Use `dependency_overrides` para isolar dependências externas, como autenticação, gateways e clients de terceiros.
- Não faça chamadas reais para serviços externos em testes unitários ou de integração locais.
- Para banco, repositórios e sessão, use fixtures explícitas e descarte o estado ao fim do teste.

### Exemplo FastAPI

```python
@pytest.mark.asyncio
async def test_should_return_404_when_invoice_does_not_exist(async_client):
    """
    Deve retornar 404 quando a fatura solicitada não existir.
    """
    # When
    response = await async_client.get("/invoices/999")

    # Then
    assert response.status_code == 404
    assert response.json() == {"detail": "Invoice not found"}
```

## Factories e Dados

- **Factories > dicionários:** use FactoryBoy, ou equivalente, para criar objetos complexos.
- **Localização:** cada factory deve ficar em seu próprio arquivo, como `tests/factories/factory_user.py`.
- **Imports:** sempre explícitos, como `from tests.factories.factory_user import UserFactory`.
- **Dados mínimos:** crie apenas o necessário para provar o comportamento.
- **Mocks:** prefira `monkeypatch`, fakes ou `dependency_overrides`. Evite mocks excessivamente acoplados à estrutura interna da função testada.

## Consolidação e Legado

Ao trabalhar em arquivos existentes:

- **Consolidação:** se múltiplos arquivos testarem o mesmo módulo, consolide no arquivo que segue o espelhamento correto.
- **Padrão atual:** não replique o legado. Se houver `unittest.TestCase`, converta para funções Pytest.
- **Migração gradual:** ao tocar em testes antigos, aproveite para alinhar nomenclatura, docstrings e organização.
- **Limpeza:** remova `__pycache__`, arquivos temporários e pastas vazias geradas localmente.

## Checklist para LLMs

Sempre que uma LLM for gerar testes, siga este checklist:

1. **Identificar a camada:** este código toca banco de dados, HTTP local ou API externa?
   - Se não, salvar em `tests/unit/`.
   - Se sim e o alvo for código interno do projeto, salvar em `tests/integration/`.
   - Se cobrir fluxo completo do usuario, salvar em `tests/e2e/`.
2. **Identificar o framework:** o alvo pertence a Django ou FastAPI?
   - Django: usar `db`, `client` e factories.
   - FastAPI: usar `TestClient` ou `AsyncClient`, mais `dependency_overrides` quando preciso.
3. **Verificar factory:** existe uma factory para a entidade em `tests/factories/`? Se sim, use-a obrigatoriamente.
4. **Nomear corretamente:** use o prefixo `test_` seguido pela condicao e o resultado esperado, como `test_should_fail_when_age_is_under_18`.
5. **Preservar isolamento:** remover dependência de rede externa, horário real e estado compartilhado.
6. **Limpeza:** ao refatorar, remova `__init__.py` desnecessarios dentro das pastas de teste e elimine pastas vazias.

## O que Não Fazer

- Não use `unittest.TestCase`.
- Não crie `conftest.py` globais gigantes; prefira `conftest.py` locais por módulo ou pasta.
- Não use nomes genéricos como `test_success` ou `test_error`; seja específico sobre o comportamento.
- Não substitua testes de integração por mocks de tudo quando houver dependência real de banco ou integração interna relevante.
- Não teste detalhes internos como ordem de chamadas privadas, nomes de variáveis locais ou implementações intermediárias sem valor funcional.
- Não duplicar cenários idênticos em `unit` e `integration` sem motivo claro.
