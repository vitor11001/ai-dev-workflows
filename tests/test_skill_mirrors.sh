#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_skills="$repo_dir/.codex/skills"
claude_skills="$repo_dir/.claude/skills"

# As skills são mantidas duplicadas em .codex/ e .claude/. Compara as duas árvores inteiras,
# exceto `agents/`, que guarda metadados exclusivos do Codex (`openai.yaml`). Uma skill ou
# arquivo presente de um lado só também é falha.
if ! diff -r --exclude=agents "$codex_skills" "$claude_skills"; then
  printf 'skills divergentes entre .codex/skills e .claude/skills\n' >&2
  exit 1
fi

# Política de execução de testes e ciclo TDD precisam estar nas skills que escrevem ou
# reorganizam testes; sem ela, uma skill volta a pedir permissão para o RED e a outra não.
for skill_name in python-implementation-workflow python-tests; do
  grep -Fq 'Rode sem perguntar os testes focados' "$codex_skills/$skill_name/SKILL.md"
  if grep -Fq 'Pergunte antes de executar `pytest`' "$codex_skills/$skill_name/SKILL.md"; then
    printf 'regra antiga de execução em %s\n' "$skill_name" >&2
    exit 1
  fi
done
grep -Fq '## Ciclo TDD' "$codex_skills/python-implementation-workflow/SKILL.md"
grep -Fq '| Comando | Resultado |' "$codex_skills/python-implementation-workflow/SKILL.md"
grep -Fq 'Ciclos TDD:' "$codex_skills/implementation-plan/SKILL.md"

# O plano precisa levantar o impacto antes do desenho e revisar a si mesmo antes da entrega.
for section in '## Mapa de impacto' '## Premissas não verificadas' '## Revisão do plano' '## Profundidade por tipo'; do
  grep -Fq "$section" "$codex_skills/implementation-plan/SKILL.md"
done

# A investigate é dona da pasta da task, do sumário e dos tipos de demanda.
for section in '## Pasta da task' '## Sumário' '## Tipos' '### Mapa do código atual' '## Issue existente' '## Investigação desatualizada'; do
  grep -Fq "$section" "$codex_skills/investigate/SKILL.md"
done

# Toda skill que toca a pasta da task registra a execução no sumário com a data do comando,
# e nenhuma volta a usar a pasta antiga como destino.
for skill_name in investigate plane-issue implementation-plan python-implementation-workflow pr-description code-review; do
  grep -Fq '0-sumario.md' "$codex_skills/$skill_name/SKILL.md"
  grep -Fq "date '+%Y-%m-%d %H:%M %Z'" "$codex_skills/$skill_name/SKILL.md"
done
for skill_name in plane-issue implementation-plan python-implementation-workflow; do
  grep -Fq 'registre uma linha no `0-sumario.md`' "$codex_skills/$skill_name/SKILL.md"
done
if grep -rn 'task-planner\|write-issue\|/tmp/NNN\|2-plano-implementacao.md` para' "$codex_skills" "$claude_skills"; then
  printf 'referência a skill ou caminho antigo\n' >&2
  exit 1
fi

# plane-issue pergunta antes de publicar e publica pelo script, que confere a checklist.
grep -Fq 'Publico no Plane?' "$codex_skills/plane-issue/SKILL.md"
grep -Fq 'scripts/plane.py publish' "$codex_skills/plane-issue/SKILL.md"
[[ -f "$codex_skills/plane-issue/scripts/plane.py" ]]

# python-tests carrega só a referência do framework detectado: os links do SKILL.md precisam
# existir, e a regra de sinalizar unittest não pode sumir.
python_tests="$codex_skills/python-tests"
for reference_name in django-drf.md fastapi-sqlmodel.md scenarios-by-target.md; do
  [[ -f "$python_tests/references/$reference_name" ]]
  grep -Fq "references/$reference_name" "$python_tests/SKILL.md"
done
grep -Fq '### unittest' "$python_tests/SKILL.md"
grep -Fq '## Resposta final' "$python_tests/SKILL.md"
grep -Fq '| Arquivo de teste | Camada | Comportamento | Resultado |' "$python_tests/SKILL.md"

# O repositório é público: exemplos usam identificadores fictícios (`PROJ-123`), nunca IDs
# de issues reais do Plane.
if grep -rn 'MONV4' "$codex_skills" "$claude_skills"; then
  printf 'identificador de issue real nos exemplos das skills\n' >&2
  exit 1
fi

printf 'skill mirrors are in sync\n'
