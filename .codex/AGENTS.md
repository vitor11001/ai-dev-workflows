# Instruções específicas para `.codex/`

## Escopo

- Este arquivo complementa o `AGENTS.md` da raiz para tudo que estiver dentro de `.codex/`.
- Use estas instruções junto com as regras globais do repositório.

## Skills

- Quando eu pedir explicitamente uma skill pelo nome, use essa skill se ela estiver disponível.
- Quando o pedido corresponder claramente a uma skill existente no repositório, você pode usá-la.
- Se houver ambiguidade, prefira não acionar skill desnecessariamente.
- As skills disponíveis ficam em `.codex/skills/`.

## Skills disponíveis em `.codex/skills`

- `python-implementation-workflow`: executa tarefas de programação Python ponta a ponta com mapeamento, implementação, testes e validação.
- `pr-description`: gera descrições de pull request com base no diff da branch atual.
- `python-tests`: cria, refatora e audita testes Python com `pytest`, com referências para Django com DRF e FastAPI com SQLModel async.
- `code-review`: revisa diffs, branches e arquivos alterados com foco em bugs, regressões e riscos.
- `commit-message`: gera mensagens de commit com base nas alterações atuais.
- `onboarding`: analisa e resume a estrutura, arquitetura e convenções do projeto.
- `investigate`: investiga uma demanda (bug, hotfix, feature, melhoria ou débito) e registra o estado atual do código e o sumário da task em `tmp/tasks/<ID>/`.
- `plane-issue`: redige a issue da task a partir da investigação e publica no Plane quando confirmado.
- `implementation-plan`: planeja a implementação da task (mapa de impacto, testes, divisão em PRs e andamento).
