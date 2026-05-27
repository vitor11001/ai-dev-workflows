# ai-dev-workflows

Workflows, agentes, skills e scripts auxiliares pessoais para usar com Codex e outras ferramentas de IA para desenvolvimento.

## Estrutura

### Codex

- `codex/AGENTS.md`: instruções globais para uso do Codex neste repositório.
- `codex/skills/implementation-workflow`: skill para executar tarefas de programação ponta a ponta com mapeamento, implementação, testes e validação.
- `codex/skills/pr-description`: skill para gerar descrições de Pull Request com base no diff da branch atual.
  Ela também gera um título de PR e ignora arquivos de template de PR no contexto coletado.
- `codex/skills/test-generator`: skill para gerar testes Python com padrões de `pytest`, Django e FastAPI incorporados.
- `codex/skills/test-refactor`: skill para reorganizar e modernizar testes Python existentes com padrões de teste incorporados.
- `codex/skills/code-review`: skill para revisar diffs e identificar riscos técnicos.
- `codex/skills/commit-message`: skill para gerar mensagens de commit com base no diff.
- `codex/skills/onboarding`: skill para mapear e resumir um projeto rapidamente.
- `codex/skills/write-issue`: skill para investigar problemas na codebase e redigir issues para Plane.

## Instalação

```bash
./install.sh
```

O instalador exibe um menu com duas opções:

- instalação padrão por cópia;
- instalação por symlink, mantendo `~/.codex/skills/<skill>` apontando para `codex/skills/<skill>` neste repositório.

Também é possível executar diretamente:

```bash
./install.sh --copy
./install.sh --symlink
```

Durante a instalação:

- as skills existentes em `~/.codex/skills` são copiadas para um backup em `~/.codex/skills-backup/<timestamp>/`, quando já houver versões anteriores;
- scripts `.sh` dentro das skills instaladas recebem permissão de execução automaticamente.
- o arquivo `codex/AGENTS.md` é copiado para `~/.codex/ai-dev-workflows/AGENTS.md`;
- o instalador preserva o conteúdo existente em `~/.codex/AGENTS.md` e adiciona apenas uma diretiva `@.../ai-dev-workflows/AGENTS.md` quando ela ainda não existir;
- se `~/.codex/AGENTS.md` já existir e precisar ser alterado, um backup `~/.codex/AGENTS.md.bak.<timestamp>` é criado antes.

No modo symlink, as skills e o arquivo instalado em `~/.codex/ai-dev-workflows/AGENTS.md` apontam para os arquivos deste repositório. Depois da primeira instalação, um `git pull` no repositório já atualiza o conteúdo usado pelo Codex.

## Uso

Depois da instalação, a skill `pr-description` fica disponível no diretório de skills do Codex.

As demais skills instaladas seguem a mesma estrutura e podem ser usadas diretamente quando o pedido corresponder ao objetivo de cada uma.

Quando você pedir uma descrição de PR, o fluxo esperado deste repositório é:

1. Coletar o contexto da branch atual.
2. Ignorar arquivos de template de PR durante a coleta de contexto.
3. Gerar um título objetivo com base no diff.
4. Gerar uma descrição objetiva com base no diff.
5. Escrever o resultado em `pr_body.md`, com o título separado da descrição no mesmo arquivo.
