# ai-dev-workflows

Workflows, agentes, skills e scripts auxiliares pessoais para usar com Codex e outras ferramentas de IA para desenvolvimento.

## Estrutura

### Codex

- `codex/AGENTS.md`: instruções globais para uso do Codex neste repositório.
- `codex/skills/pr-description`: skill para gerar descrições de Pull Request com base no diff da branch atual.
- `codex/skills/test-generator`: skill para gerar testes Python seguindo o `TESTING.md`.
- `codex/skills/test-refactor`: skill para reorganizar e modernizar testes Python existentes.
- `codex/skills/code-review`: skill para revisar diffs e identificar riscos técnicos.
- `codex/skills/commit-message`: skill para gerar mensagens de commit com base no diff.
- `codex/skills/onboarding`: skill para mapear e resumir um projeto rapidamente.

### Guias

- `TESTING.md`: padrão de engenharia para criação e refatoração de testes Python por humanos e LLMs.

## Instalação

```bash
./install.sh
```

Durante a instalação:

- as skills existentes em `~/.codex/skills` são copiadas para um backup em `~/.codex/skills-backup/<timestamp>/`, quando já houver versões anteriores;
- scripts `.sh` dentro das skills instaladas recebem permissão de execução automaticamente.

## Uso

Depois da instalação, a skill `pr-description` fica disponível no diretório de skills do Codex.

As demais skills instaladas seguem a mesma estrutura e podem ser usadas diretamente quando o pedido corresponder ao objetivo de cada uma.

Quando você pedir uma descrição de PR, o fluxo esperado deste repositório é:

1. Coletar o contexto da branch atual.
2. Gerar uma descrição objetiva com base no diff.
3. Escrever o resultado em `pr_body.md`, quando aplicável.
