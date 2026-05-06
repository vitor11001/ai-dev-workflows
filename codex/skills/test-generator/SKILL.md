---
name: test-generator
description: gera ou amplia testes em python com pytest para django e fastapi, seguindo o arquivo TESTING.md do repositório. use quando o usuário pedir para criar testes, adicionar cobertura, escrever testes para uma função, serviço, model, endpoint, controller ou fluxo.
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

Criar ou atualizar testes em `tests/unit/`, `tests/integration/` ou `tests/e2e/`, conforme a camada correta. Os testes devem seguir o `TESTING.md`.

## Procedimento

Quando esta skill for usada:
1. Leia `TESTING.md` antes de propor ou editar testes.
2. Identifique se o alvo pertence a Django, FastAPI ou código Python agnóstico.
3. Classifique o teste como `unit`, `integration` ou `e2e`.
4. Reutilize factories, fixtures e convenções existentes antes de criar novos elementos.
5. Espelhe o caminho do código de produção no caminho do teste.
6. Gere testes orientados a comportamento, não a detalhes internos.

## Regras obrigatórias

- Use `pytest`.
- Prefira funções `test_...`; não use `unittest.TestCase`, salvo pedido explícito.
- Escreva nomes de teste em inglês.
- Escreva docstrings e comentários em português brasileiro.
- Em Django, prefira a fixture `db` a `@pytest.mark.django_db`, salvo necessidade explícita.
- Em FastAPI, teste contrato HTTP e use `dependency_overrides` quando houver dependências externas.
- Não invente factories, endpoints, regras de negócio ou fluxos não sustentados pelo código.

## Critérios de revisão

Antes de entregar, confirme:
1. O arquivo de teste foi salvo na camada correta?
2. O teste prova comportamento real?
3. O teste segue o espelhamento definido no `TESTING.md`?
4. O teste evita acoplamento desnecessário à implementação?
