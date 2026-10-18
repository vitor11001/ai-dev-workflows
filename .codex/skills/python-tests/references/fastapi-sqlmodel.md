# FastAPI com SQLModel async

Padrões para testes de aplicação FastAPI async com SQLModel (`AsyncSession`) e PostgreSQL. O padrão já usado pelo projeto prevalece; esta referência vale quando ele não existir.

## Plugin async

- Use o plugin que o projeto já usa. Sem padrão: `pytest-asyncio`, com a configuração explícita no `pyproject.toml`; o modo padrão é `strict` e o escopo de loop padrão das fixtures está mudando entre versões, então não dependa do default:

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "session"
asyncio_default_test_loop_scope = "session"
```

- Engine e testes precisam rodar no mesmo event loop. Engine com escopo de sessão em loop diferente do teste gera erro de "attached to a different loop" (comum com `asyncpg`). Mantenha os dois escopos de loop iguais, como acima, ou crie o engine por teste.
- Com `anyio` (exemplo da documentação do FastAPI), marque os testes com `@pytest.mark.anyio` e defina a fixture `anyio_backend` retornando `"asyncio"`.

## Banco e sessão

- Teste de integração usa o mesmo banco de produção (PostgreSQL), em banco de teste próprio. SQLite tem outro comportamento de tipos, constraints e transações; serve só para teste unitário sem I/O real.
- Isole cada teste com transação externa e savepoint: o código pode chamar `commit()`, que cai num savepoint, e o rollback no teardown desfaz tudo.

```python
from collections.abc import AsyncIterator

import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession


@pytest.fixture(scope="session")
async def engine() -> AsyncIterator[AsyncEngine]:
    """Engine do banco de teste, com o schema criado uma vez por sessão."""
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as connection:
        await connection.run_sync(SQLModel.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def session(engine: AsyncEngine) -> AsyncIterator[AsyncSession]:
    """Sessão isolada: tudo que o teste gravar é desfeito no teardown."""
    async with engine.connect() as connection:
        transaction = await connection.begin()
        async with AsyncSession(
            bind=connection,
            join_transaction_mode="create_savepoint",
            expire_on_commit=False,
        ) as session:
            yield session
        await transaction.rollback()
```

- Se o projeto usa migrations (Alembic), crie o schema rodando as migrations no banco de teste em vez de `create_all`, para testar o schema real.
- `expire_on_commit=False` evita lazy load implícito depois do `commit()`, que em sessão async falha com `MissingGreenlet`.

## Cliente HTTP

- Use `httpx.AsyncClient` com `ASGITransport` e sobrescreva a dependência de sessão para usar a sessão isolada.
- Limpe `app.dependency_overrides` no teardown; override que vaza contamina os testes seguintes.
- `ASGITransport` não dispara o lifespan da aplicação. Se o teste depender do startup (conexões, cache, clients), envolva a app com `LifespanManager` do pacote `asgi-lifespan`.

```python
from collections.abc import AsyncIterator

import pytest
from httpx import ASGITransport, AsyncClient


@pytest.fixture
async def client(session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """Cliente HTTP da aplicação usando a sessão isolada do teste."""
    app.dependency_overrides[get_session] = lambda: session
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
    app.dependency_overrides.clear()


async def test_should_create_order(client: AsyncClient, session: AsyncSession):
    """Deve criar o pedido e retornar 201 com o id gerado."""
    # When
    response = await client.post("/orders", json={"total": "100.00"})

    # Then
    assert response.status_code == 201
    assert await session.get(Order, response.json()["id"]) is not None
```

- Rota síncrona ou projeto que já usa `TestClient`: preserve o `TestClient` do projeto.

## Autenticação e configuração

- Autenticação: sobrescreva a dependência que resolve o usuário (`app.dependency_overrides[get_current_user] = lambda: user`). Teste o fluxo real de token apenas nos testes do próprio mecanismo de autenticação.
- Configuração: sobrescreva a dependência `get_settings` com um `Settings` de teste. Se `get_settings` usa `lru_cache`, chame `get_settings.cache_clear()` no teardown.
- Gateways e clients de terceiros: sobrescreva a dependência que os fornece com um fake; nunca chame o serviço real.

## Contrato HTTP

- Verifique `status_code`, payload, headers do contrato e efeitos colaterais relevantes.
- Erro de validação do Pydantic: `422` com `detail` em lista; verifique o campo por `loc` e o `type`, não a mensagem inteira:

```python
assert response.status_code == 422
assert response.json()["detail"][0]["loc"] == ["body", "total"]
```

- Erro de domínio traduzido por `HTTPException` ou exception handler: verifique o status e o corpo que o handler monta, passando pela app (não chamando a função da rota direto).

## Permissão

Matriz por papel em um `parametrize`, montando o usuário de cada papel e sobrescrevendo a dependência de usuário. Anônimo é o caso sem override (a dependência real recusa a requisição). Inclua o recurso de outro dono ou tenant.

## Queries

Fixe o número de queries em listagens e detalhes com relacionamentos, contando pelo evento do engine síncrono interno:

```python
from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import event


@pytest.fixture
def count_queries(engine: AsyncEngine):
    """Conta as queries executadas dentro do bloco `with count_queries() as queries`."""

    @contextmanager
    def counter() -> Iterator[list[str]]:
        statements: list[str] = []

        def before_cursor_execute(conn, cursor, statement, *args):
            statements.append(statement)

        event.listen(engine.sync_engine, "before_cursor_execute", before_cursor_execute)
        try:
            yield statements
        finally:
            event.remove(engine.sync_engine, "before_cursor_execute", before_cursor_execute)

    return counter
```

- Crie mais de um item relacionado para o teste detectar N+1.
- Em sessão async, acessar relação não carregada falha com `MissingGreenlet` em vez de gerar query extra; o teste de queries pega o caso em que a relação é carregada por query separada por item (`selectinload` esquecido em loop, por exemplo).

## Efeitos colaterais

- `BackgroundTasks` rodam depois da resposta, no mesmo processo do cliente de teste: verifique o efeito após a requisição, ou sobrescreva a dependência que a task usa.
- Filas e jobs externos: sobrescreva o publisher com um fake e verifique a mensagem publicada.

## Factories

- `factory_boy` não persiste com sessão async. Sem padrão no projeto, use funções builder async em `tests/factories/`, com defaults válidos e overrides por argumento:

```python
async def make_user(session: AsyncSession, **overrides: object) -> User:
    """Cria e persiste um usuário válido, aceitando campos sobrescritos."""
    user = User(**{"email": f"user-{uuid4().hex[:8]}@example.com", "is_active": True, **overrides})
    session.add(user)
    await session.flush()
    return user
```

- Use `flush()`, não `commit()`, nos builders: o objeto ganha id e continua dentro da transação do teste.
- Se o projeto já usa `polyfactory` com persistência async, siga o padrão dele.
