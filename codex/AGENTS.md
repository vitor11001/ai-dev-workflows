# Instruções específicas para `codex/`

## Escopo

- Este arquivo complementa o `AGENTS.md` da raiz para tudo que estiver dentro de `codex/`.
- Use estas instruções junto com as regras globais do repositório.

## Skills

- Quando eu pedir explicitamente uma skill pelo nome, use essa skill se ela estiver disponível.
- Quando o pedido corresponder claramente a uma skill existente no repositório, você pode usá-la.
- Se houver ambiguidade, prefira não acionar skill desnecessariamente.
- As skills disponíveis ficam em `codex/skills/`.

## Skills disponíveis em `codex/skills`

- `pr-description`: gera descrições de pull request com base no diff da branch atual.
- `test-generator`: gera testes Python com `pytest` seguindo o `TESTING.md`.
- `test-refactor`: refatora, consolida e reorganiza testes Python existentes.
- `code-review`: revisa diffs, branches e arquivos alterados com foco em bugs, regressões e riscos.
- `commit-message`: gera mensagens de commit com base nas alterações atuais.
- `onboarding`: analisa e resume a estrutura, arquitetura e convenções do projeto.
