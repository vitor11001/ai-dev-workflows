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
7. Pergunte antes de executar `pytest` ou validações demoradas, salvo pedido explícito do usuário.

## Princípios

- Comportamento > implementação: teste o resultado esperado, não detalhes internos.
- Menor escopo confiável: use o menor tipo de teste capaz de provar o comportamento sem perder fidelidade.
- Determinismo: não dependa de horário real, rede externa ou estado residual.
- Código, nomes, variáveis e arquivos devem estar em inglês.
- Docstrings e comentários devem estar em português brasileiro.
- Testes devem ter docstrings claras em português brasileiro.
- Prefira uma responsabilidade por teste.

## Estratégia de casos

Cubra os cenários relevantes para o comportamento solicitado:

- caminho feliz principal;
- validações, erros e exceções esperadas;
- bordas relevantes do domínio;
- permissões, autenticação ou autorização quando existirem;
- efeitos colaterais observáveis, como persistência, eventos, cache, filas ou chamadas internas;
- regressão específica quando o pedido for correção de bug.

## Sugestões por alvo

Use esta lista como cardápio de cenários. Escolha os testes que provam o comportamento alterado, as regras de domínio e os riscos relevantes. Não crie cenários artificiais sem relação com a mudança.

### Views, controllers e endpoints

- Sucesso principal: status esperado, payload esperado e formato do contrato.
- Objeto inexistente: `404` ou erro equivalente.
- Entrada inválida: `400`, `422` ou erro equivalente, com campo inválido e mensagem esperada.
- Permissão, autenticação e autorização: usuário anônimo, sem permissão e com permissão quando aplicável.
- Filtros e busca: retorna apenas dados compatíveis com query params.
- Paginação e ordenação: página, limite, ordenação e metadados quando fizerem parte do contrato.
- Criação: persiste objeto com campos corretos e retorna contrato correto.
- Atualização parcial ou total: altera apenas o esperado e preserva o restante.
- Exclusão: remove, desativa ou marca corretamente e responde com status esperado.
- Idempotência: repetir request não duplica efeito quando o contrato exigir.
- Efeitos colaterais: evento, service interno, job, cache ou outra integração observável.
- Erros de domínio: exceções esperadas são traduzidas para resposta correta.
- Serialização: campos calculados, datas, enums e relacionamentos no formato esperado.
- Escopo de usuário ou multi-tenant: usuário não acessa dados de outro dono ou tenant.
- Headers relevantes: `Location`, cache, content type ou autenticação quando fizerem parte do contrato.

### Controllers ou services de aplicação

- Fluxo feliz: retorna o resultado esperado.
- Validação de entrada: rejeita valores inválidos.
- Orquestração observável: integra repositórios, gateways ou services no nível certo sem testar detalhe irrelevante.
- Transações: commit, rollback ou atomicidade quando aplicável.
- Efeitos colaterais: eventos, jobs, logs relevantes, cache ou notificações.
- Erros recuperáveis: fallback, retry ou tradução de erro quando existir.
- Erros de domínio: propaga ou converte exceção conforme contrato.
- Não duplicidade: não cria registros duplicados em chamadas repetidas quando isso for regra.
- Permissões e regras de acesso quando o controller aplicar regra antes de chamar domínio.

### Models

- Criação válida com dados mínimos.
- Defaults aplicados corretamente.
- Validações de campo: obrigatório, tamanho, formato e escolhas/enums.
- Validações de domínio: combinações inválidas de campos são rejeitadas.
- Constraints e unicidade.
- Relacionamentos: `ForeignKey`, `OneToOne`, `ManyToMany`, cascade, protect ou set null quando relevante.
- Métodos e properties com valores calculados corretos.
- Managers, querysets e scopes retornando exatamente o conjunto esperado.
- Estados e transições permitidas ou proibidas.
- Persistência de campos calculados: totals, slugs, campos normalizados e timestamps.
- Soft delete e flags de ativo/inativo.
- Ordenação ou `Meta` quando impactar comportamento.
- Signals e hooks apenas quando forem comportamento real e observável.
- Representação textual como `__str__` quando usada por admin, logs ou UI.
- Regras de data e timezone quando houver vencimento, expiração ou janela temporal.

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
- Antes de criar uma factory, procure uma factory existente para aquele model específico.
- Crie uma factory nova apenas quando não existir factory para aquele model específico.
- Evite criar `conftest.py` global grande; prefira fixtures locais por módulo ou pasta.
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

## Testes frágeis

- Não teste detalhes internos, chamadas privadas ou ordem de chamadas sem valor funcional.
- Não dependa de ordenação quando a ordem não fizer parte do contrato.
- Não use snapshots de payload completo sem necessidade clara.
- Prefira asserts explícitos, pequenos e ligados ao comportamento.
- Não mocke todas as dependências quando o objetivo for validar integração local real.

## Execução

- Pergunte ao usuário antes de rodar `pytest`, lint, typecheck ou validações demoradas.
- Se o usuário preferir executar os testes, informe os comandos relevantes em vez de rodá-los.
- Não afirme que algo foi testado se o comando não foi executado.

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
6. O comportamento principal, erro/borda relevante e efeitos colaterais foram cobertos quando aplicável?
7. Foi reutilizada factory/fixture existente ou criada factory nova apenas quando não havia factory para o model específico?
8. O usuário foi consultado antes de executar testes ou validações demoradas?
