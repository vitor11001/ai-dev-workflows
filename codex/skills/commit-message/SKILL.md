---
name: commit-message
description: gera mensagens de commit com base no diff atual, arquivos alterados e intenção da mudança. use quando o usuário pedir para criar, sugerir, melhorar ou revisar uma mensagem de commit sem efetuar o commit.
---

# Mensagem de Commit

## Objetivo

Gerar mensagens de commit curtas, claras e fiéis às mudanças realizadas.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "gere uma mensagem de commit"
- "sugira um commit message"
- "melhore essa mensagem de commit"
- "crie um título de commit para esse diff"

## Saída esperada

Uma ou mais sugestões de mensagem de commit, prontas para uso, sem efetuar o commit.

## Procedimento

Quando esta skill for usada:
1. Colete o contexto com o script `scripts/commit_context.sh` da própria skill.
2. Identifique o objetivo principal da mudança.
3. Sintetize o comportamento alterado em uma mensagem curta e específica.
4. Se a mudança misturar temas distintos, indique que o ideal seria separar commits ou ofereça mais de uma opção de mensagem.

## Regras obrigatórias

- Não faça commit.
- Não invente escopo que não esteja sustentado pelo diff.
- Prefira mensagens curtas e específicas.
- Se fizer sentido, use prefixos como `feat`, `fix`, `refactor`, `test`, `docs` ou `chore`.
- Evite mensagens genéricas como `update code` ou `fix issues`.

## Critérios de revisão

Antes de entregar, confirme:
1. A mensagem descreve a mudança principal?
2. A mensagem está curta o suficiente?
3. A mensagem não promete mais do que o diff realmente faz?
