# Instruções para agentes neste repositório

@/home/vitor11001/.codex/RTK.md

## Regras locais

- Responda em português brasileiro.
- Seja direto, técnico e prático.
- Preserve os padrões do repositório atual.
- Prefira mudanças pequenas e fáceis de revisar.
- Não faça commit, push, merge ou publique nada sem pedido explícito.
- Não execute comandos destrutivos sem confirmação.
- Não exponha tokens, chaves, credenciais ou dados sensíveis.
- Não afirme que algo foi testado se não foi executado.

## Testes Python

- Ao gerar, revisar, refatorar ou reorganizar testes Python, use `TESTING.md` como contexto obrigatório.
- Siga o guia para `pytest + Django` e `pytest + FastAPI`.
- Espelhe a estrutura do codigo em `tests/unit/`, `tests/integration/` e `tests/e2e/`.
- Prefira factories, fixtures pequenas e testes orientados a comportamento.
- Não mantenha ou introduza padrões legados com `unittest.TestCase`, salvo pedido explícito.

## Skills

- Quando eu pedir descrição de PR, use a skill `pr-description`, se disponível.
