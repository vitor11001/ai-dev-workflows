---
name: pr-description
description: gera descrições de pull request para a branch atual usando commits, diff, arquivos alterados e template de PR quando existir. use quando o usuário pedir em português para gerar, criar, montar, escrever, revisar, melhorar ou atualizar uma descrição de PR, pull request ou arquivo pr_body.md.
---

# Descrição de Pull Request

## Objetivo

Gerar uma descrição clara, objetiva e útil para revisão de código com base nas mudanças da branch atual.

A descrição deve ajudar quem vai revisar o PR a entender:
- O contexto da mudança;
- O que foi modificado;
- Quais impactos, riscos ou pontos de atenção existem.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "gere a descrição do PR"
- "crie a descrição do pull request"
- "monta o texto do PR"
- "gera o pr_body"
- "atualize a descrição do PR"
- "melhore a descrição do PR"
- "me ajude a escrever a descrição do pull request"

## Saída esperada

A descrição final deve ser escrita em português brasileiro. Por padrão, crie ou atualize um arquivo chamado `pr_body.md`. Se o usuário pedir apenas para visualizar a descrição, mostre o conteúdo na conversa e não crie arquivo.

## Procedimento

Quando esta skill for usada:
1. Trabalhe no repositório atual.
2. Identifique a branch atual e a branch base (`main` ou `master`).
3. **Coleta de Contexto:** Execute o script localizado em `ai-dev-workflows/codex/skills/pr-description/scripts/pr_context.sh` para obter o diff e as informações das mudanças.
4. Gere uma descrição objetiva, fiel ao diff coletado pelo script.
5. Não faça commit e não publique no GitHub sem pedido explícito.

## Formato padrão (na ausência de template)

### ## Contexto
Explique por que esta mudança existe. Se não estiver evidente, escreva: *Não identificado pelo diff.*

### ## Modificações
Liste as alterações em bullets. Agrupe mudanças relacionadas.

### ## Impacto
Explique riscos, mudanças de comportamento, performance ou segurança. Se não houver, escreva: *Nenhum impacto relevante identificado pelo diff.*

## Regras de escrita e segurança

* **Idioma:** Português brasileiro, tom profissional e frases diretas.
* **Precisão:** Não invente testes, contextos de produto, issues ou requisitos que não estejam explícitos no diff ou nos commits.
* **Segurança:** Nunca inclua segredos, tokens, chaves ou credenciais na descrição.
* **Fidelidade:** Se o script não retornar informações suficientes para uma seção, use "Não identificado pelo diff".
* **Qualidade:** A descrição deve ser específica para o código alterado, evitando generalismos.

## Critérios de Revisão
Antes de entregar, garanta que a descrição responda:
1. Por que o PR existe?
2. O que exatamente mudou?
3. Onde o revisor deve ter mais atenção?
