# ai-dev-workflows

Workflows, agentes, skills e scripts auxiliares pessoais para usar com Codex, Claude Code e outras ferramentas de IA para desenvolvimento.

## Estrutura

O repositório mantém dois conjuntos paralelos de skills com o mesmo conteúdo, adaptados para cada ferramenta:

- `.codex/`: skills e instruções para o **Codex** da OpenAI.
- `.claude/`: skills e instruções para o **Claude Code** da Anthropic.

### `.codex/`

- `.codex/AGENTS.md`: instruções globais para uso do Codex neste repositório.
- `.codex/skills/python-implementation-workflow`: executa tarefas de programação Python ponta a ponta com mapeamento, implementação, testes e validação.
- `.codex/skills/pr-description`: gera descrições de Pull Request com base no diff da branch atual. Também gera um título de PR e ignora arquivos de template de PR no contexto coletado.
- `.codex/skills/python-tests`: cria, refatora e audita testes Python com `pytest`, com referências para Django com DRF e FastAPI com SQLModel async.
- `.codex/skills/code-review`: revisa diffs e identifica riscos técnicos.
- `.codex/skills/commit-message`: gera mensagens de commit com base no diff.
- `.codex/skills/onboarding`: mapeia e resume um projeto rapidamente.
- `.codex/skills/investigate`: investiga uma demanda (bug, hotfix, feature, melhoria ou débito) e registra o estado atual do código e o sumário da task em `tmp/tasks/<ID>/`.
- `.codex/skills/plane-issue`: redige a issue da task a partir da investigação e publica no Plane quando confirmado (script `scripts/plane.py`).
- `.codex/skills/implementation-plan`: planeja a implementação da task: mapa de impacto, testes, divisão em PRs e andamento.

### `.claude/`

- `.claude/CLAUDE.md`: instruções globais para uso do Claude Code neste repositório.
- `.claude/skills/*`: mesmas skills da pasta `.codex/`, adaptadas para o Claude Code (mesma estrutura `SKILL.md` com frontmatter).

## Instalação

```bash
./install.sh
```

O instalador faz duas perguntas em sequência:

1. Qual ferramenta instalar: **Codex**, **Claude** ou **Ambos**.
2. Qual modo de instalação: **Cópia** (padrão) ou **Symlink**.

Também é possível executar diretamente com flags:

```bash
./install.sh --copy-codex
./install.sh --copy-claude
./install.sh --copy-all

./install.sh --symlink-codex
./install.sh --symlink-claude
./install.sh --symlink-all
```

### Destinos por ferramenta

| Ferramenta | Skills instaladas em       | Instruções globais          | Arquivo do usuário          |
|------------|----------------------------|-----------------------------|-----------------------------|
| Codex      | `~/.codex/skills/<skill>`  | `~/.codex/ai-dev-workflows/AGENTS.md` | `~/.codex/AGENTS.md`  |
| Claude     | `~/.claude/skills/<skill>` | `~/.claude/ai-dev-workflows/CLAUDE.md` | `~/.claude/CLAUDE.md` |

### Comportamento da instalação

Durante a instalação (em ambos os modos e para ambas as ferramentas):

- as skills existentes no diretório de destino são copiadas para um backup em `~/.<codex|claude>/skills-backup/<timestamp>/`, quando já houver versões anteriores;
- scripts `.sh` dentro das skills instaladas recebem permissão de execução automaticamente;
- o arquivo de instruções (`AGENTS.md` para Codex, `CLAUDE.md` para Claude) é instalado em `~/.<codex|claude>/ai-dev-workflows/`;
- o instalador preserva o conteúdo existente em `~/.<codex|claude>/<AGENTS|CLAUDE>.md` e adiciona apenas uma diretiva `@.../ai-dev-workflows/<AGENTS|CLAUDE>.md` quando ela ainda não existir;
- se o arquivo de usuário já existir e precisar ser alterado, um backup `*.bak.<timestamp>` é criado antes.

No modo **symlink**, as skills e o arquivo de instruções do projeto apontam para os arquivos deste repositório. Depois da primeira instalação, um `git pull` no repositório já atualiza o conteúdo usado pela ferramenta.

O modo symlink também remove links que apontam para uma skill deste repositório que deixou de existir, e ativa os git hooks de `.githooks/` (`git config core.hooksPath .githooks`, sem sobrescrever um valor já configurado). Os hooks reaplicam a instalação por symlink em modo silencioso:

| Hook | Quando |
|---|---|
| `post-merge` | depois de `git merge` ou `git pull` |
| `post-checkout` | na troca de branch (não no checkout de arquivo) |
| `post-rewrite` | depois de `git rebase` ou `git pull --rebase` |

Assim, uma skill nova ganha link, uma skill removida perde o link, e as skills acompanham a branch atual. Os hooks só agem na ferramenta já instalada por symlink; instalação por cópia não é alterada. Só são impressas mudanças efetivas (`[claude] link criado: ...`).

## Uso

Depois da instalação, as skills ficam disponíveis no diretório de skills correspondente à ferramenta (`~/.codex/skills/` ou `~/.claude/skills/`).

As skills são acionadas pelo agente quando o pedido corresponder ao objetivo de cada uma. Também é possível invocá-las explicitamente pelo nome.

Quando você pedir uma descrição de PR, o fluxo esperado deste repositório é:

1. Coletar o contexto da branch atual.
2. Ignorar arquivos de template de PR durante a coleta de contexto.
3. Gerar um título objetivo com base no diff.
4. Gerar uma descrição objetiva com base no diff.
5. Escrever o resultado em `pr_body.md`, com o título separado da descrição no mesmo arquivo.

## Fluxo de uma task

Cada demanda (bug, hotfix, feature, melhoria ou débito) mora em `tmp/tasks/<ID>/` no repositório em que será resolvida, com `<ID>` igual ao ID do Plane ou `LOCAL-<slug>` enquanto não houver issue:

```
investigate ─► plane-issue (opcional) ─► implementation-plan ─► python-implementation-workflow ─► code-review ─► pr-description
```

- `0-sumario.md` registra tipo, status, situação no Plane e uma linha datada por skill executada.
- `investigate` é a base: `plane-issue` e `implementation-plan` a executam antes quando a investigação ainda não existe.
- `plane-issue` sempre pergunta antes de publicar; muita correção não vai para o Plane.

### Configuração do Plane

Para publicar e buscar issues, crie `~/.config/ai-dev-workflows/plane.env` (com `chmod 600`):

```bash
PLANE_WORKSPACE=<slug-do-workspace>
PLANE_API_TOKEN_FILE=<caminho do arquivo com o token>
```

O script `plane-issue/scripts/plane.py` lê o token desse arquivo e o envia só no header da API (Plane Cloud). `python3 -I .claude/skills/plane-issue/scripts/plane.py check` valida a configuração e lista os projetos.
