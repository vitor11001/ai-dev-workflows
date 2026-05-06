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

Cada sugestão deve:
- ter um título em uma única linha;
- ter no máximo 3 linhas no total;
- omitir corpo quando o título sozinho já for suficiente.

## Procedimento

Quando esta skill for usada:
1. Colete o contexto com o script `scripts/commit_context.sh` da própria skill.
2. Identifique o objetivo principal da mudança.
3. Sintetize o comportamento alterado em uma mensagem curta e específica.
4. Escreva o título do commit em uma única linha.
5. Se incluir corpo, limite a mensagem inteira a no máximo 3 linhas.
6. Se a mudança misturar temas distintos, indique que o ideal seria separar commits ou ofereça mais de uma opção de mensagem.

## Regras obrigatórias

- Não faça commit.
- Não invente escopo que não esteja sustentado pelo diff.
- Prefira mensagens curtas e específicas.
- O título deve caber em uma única linha.
- A mensagem completa deve ter no máximo 3 linhas.
- Prefira entregar apenas o título quando ele já comunicar a mudança com clareza.
- Se fizer sentido, use prefixos como `feat`, `fix`, `refactor`, `test`, `docs` ou `chore`.
- Evite mensagens genéricas como `update code` ou `fix issues`.

## Critérios de revisão

Antes de entregar, confirme:
1. A mensagem descreve a mudança principal?
2. O título está em uma única linha?
3. A mensagem inteira tem no máximo 3 linhas?
4. A mensagem não promete mais do que o diff realmente faz?
