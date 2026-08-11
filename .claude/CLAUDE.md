# Instruções específicas para `.claude/`

## Escopo

- Este arquivo complementa o `AGENTS.md` da raiz para tudo que estiver dentro de `.claude/`.
- Use estas instruções junto com as regras globais do repositório.

## Skills

- Quando eu pedir explicitamente uma skill pelo nome, use essa skill se ela estiver disponível.
- Quando o pedido corresponder claramente a uma skill existente no repositório, você pode usá-la.
- Se houver ambiguidade, prefira não acionar skill desnecessariamente.
- As skills disponíveis ficam em `.claude/skills/`.

## Skills disponíveis em `.claude/skills`

- `python-implementation-workflow`: executa tarefas de programação Python ponta a ponta, em fases, com mapeamento, implementação, testes e validação.
- `pr-description`: gera descrições de pull request com base no diff da branch atual.
- `django-tests`: cria, amplia e refatora testes Django/DRF com `pytest`, incluindo a receita de testes por camada.
- `code-review`: revisa diffs, branches e arquivos alterados com foco em bugs, regressões e riscos.
- `commit-message`: gera mensagens de commit com base nas alterações atuais.
- `onboarding`: analisa e resume a estrutura, arquitetura e convenções do projeto.
- `write-issue`: investiga problemas na codebase e redige issues para Plane.
- `django-implementation-plan`: destrincha uma issue em plano de implementação Django por camada, com divisão em PRs.
- `django-layered-architecture`: estrutura projetos e apps Django/DRF em camadas e decide onde cada código deve morar.
