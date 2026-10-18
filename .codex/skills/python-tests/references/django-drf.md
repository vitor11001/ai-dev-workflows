# Django com DRF

Padrões para testes com `pytest-django` e Django REST Framework. O padrão já usado pelo projeto prevalece; esta referência vale quando ele não existir.

## Banco

- Prefira a fixture `db` a `@pytest.mark.django_db`, salvo necessidade explícita.
- Use `transactional_db` apenas quando o caso precisar de transação real (ex.: `select_for_update`, `on_commit` sem captura, comportamento entre conexões).
- Não mocke o ORM quando a intenção for validar persistência, filtros, integridade ou consultas.
- Teste models, managers, querysets, services, signals, views e endpoints pelo comportamento observável.

## Cliente e autenticação

- Use `rest_framework.test.APIClient` numa fixture local (`api_client`); não use `APITestCase`.
- Autentique com `api_client.force_authenticate(user=user)`. Use login real só quando o teste for do próprio fluxo de autenticação.
- Monte URLs com `django.urls.reverse` pelo nome da rota, não com caminho literal.
- Envie JSON com `format="json"` (ou `content_type="application/json"`) quando o endpoint esperar JSON.

```python
@pytest.fixture
def api_client() -> APIClient:
    """Cliente DRF sem autenticação."""
    return APIClient()


def test_should_return_only_own_orders(db, api_client):
    """Deve listar apenas os pedidos do usuário autenticado."""
    # Given
    user = UserFactory()
    own_order = OrderFactory(user=user)
    OrderFactory()
    api_client.force_authenticate(user=user)

    # When
    response = api_client.get(reverse("orders-list"))

    # Then
    assert response.status_code == status.HTTP_200_OK
    assert [item["id"] for item in response.json()["results"]] == [own_order.id]
```

## Contrato HTTP

- Verifique `status_code` com as constantes de `rest_framework.status`, o payload e os headers que fizerem parte do contrato (`Location`, paginação, content type).
- Erro de validação do serializer: `400` com `{"campo": ["mensagem"]}`; verifique o campo e, quando fizer parte do contrato, o código (`response.json()["campo"][0]` ou `exception.detail[...].code`).
- Paginação: verifique o formato do paginador do projeto (`count`, `next`, `previous`, `results` no `PageNumberPagination`).
- Prefira `response.json()` para validar o contrato que o cliente recebe; `response.data` mostra o dado antes da renderização.

## Permissão

Matriz por papel em um `parametrize`:

```python
@pytest.mark.parametrize(
    ("role", "expected_status"),
    [
        pytest.param(None, status.HTTP_401_UNAUTHORIZED, id="anonymous"),
        pytest.param("viewer", status.HTTP_403_FORBIDDEN, id="viewer"),
        pytest.param("manager", status.HTTP_204_NO_CONTENT, id="manager"),
    ],
)
def test_delete_order_permission_by_role(db, api_client, role, expected_status):
    """Deve permitir excluir pedido apenas para gestor."""
    ...
```

- `401` contra `403` depende do esquema de autenticação: com `SessionAuthentication` como primeiro autenticador, anônimo recebe `403`. Confira a configuração antes de fixar o status.
- Inclua o caso de recurso de outro dono ou tenant (`404` ou `403`, conforme o projeto).

## Queries

- Em listagens e detalhes com relacionamentos, fixe o número de queries com `django_assert_num_queries` (ou `django_assert_max_num_queries` quando o número variar por motivo legítimo).
- Crie mais de um item relacionado para o teste detectar N+1: com um item só, a query extra não aparece.

```python
def test_should_list_orders_without_n_plus_one(db, api_client, django_assert_num_queries):
    """Deve listar pedidos com itens em número fixo de queries."""
    user = UserFactory()
    for order in OrderFactory.create_batch(3, user=user):
        OrderItemFactory.create_batch(2, order=order)
    api_client.force_authenticate(user=user)

    with django_assert_num_queries(3):
        api_client.get(reverse("orders-list"))
```

## Efeitos colaterais

- `transaction.on_commit`: use a fixture `django_capture_on_commit_callbacks(execute=True)` em vez de `transactional_db`.
- Signals: teste apenas quando forem comportamento real e observável; verifique o efeito, não a chamada do receiver.
- E-mail: fixture `mailoutbox`.
- Celery: isole o `.delay`/`.apply_async` com `monkeypatch` e verifique os argumentos, ou siga a configuração eager do projeto; não dependa de broker real.
- Configuração: fixture `settings` (`settings.FEATURE_X = True`), desfeita automaticamente ao fim do teste.
- Throttling: se interferir nos testes, desligue pela fixture `settings`, não removendo a classe da view.

## Factories

- `factory_boy` com `factory.django.DjangoModelFactory`.
- Use `SubFactory` para relações obrigatórias e `RelatedFactory`/`post_generation` para relações reversas e many-to-many.
- Prefira `build()` em testes unitários que não precisam de banco.
