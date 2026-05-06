---
name: pr-description
description: gera título e descrição de pull request para a branch atual usando commits, diff e arquivos alterados, ignorando templates de PR. use quando o usuário pedir em português para gerar, criar, montar, escrever, revisar, melhorar ou atualizar um título de PR, uma descrição de PR, pull request ou `pr_body.md`.
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

O resultado final deve ser escrito em português brasileiro.

Por padrão:
- crie ou atualize `pr_body.md`;
- escreva no mesmo arquivo um título curto, específico e fiel ao diff;
- separe visualmente o título e a descrição em blocos distintos.

Se o usuário pedir apenas para visualizar o resultado, mostre o título e a descrição na conversa e não crie arquivos.

## Procedimento

Quando esta skill for usada:
1. Trabalhe no repositório atual.
2. Identifique a branch atual e a branch base (`main` ou `master`).
3. **Coleta de Contexto:** Execute o script localizado em `ai-dev-workflows/codex/skills/pr-description/scripts/pr_context.sh` para obter o diff e as informações das mudanças.
4. Gere um título curto e objetivo, fiel ao diff coletado pelo script.
5. Gere uma descrição objetiva, fiel ao diff coletado pelo script.
6. Escreva ambos em `pr_body.md`, mantendo título e descrição separados.
7. Ignore templates de PR e não replique a estrutura deles na saída.
8. Não faça commit e não publique no GitHub sem pedido explícito.

## Formato do arquivo

O arquivo `pr_body.md` deve seguir esta estrutura:

```md
# <titulo do PR>

## Contexto
...

## Modificações
...

## Impacto
...
```

## Formato do título

O título deve:
- ter no máximo 72 caracteres quando possível;
- começar com verbo no infinitivo ou substantivo técnico claro;
- descrever o efeito principal da mudança, sem prefixos genéricos como "Atualizações" ou "Ajustes";
- não mencionar template, checklist ou conteúdo administrativo.

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
* **Título:** O título deve resumir a mudança principal sem repetir literalmente o nome da branch, salvo se isso for necessário para clareza.

## Critérios de Revisão
Antes de entregar, garanta que a descrição responda:
1. Por que o PR existe?
2. O que exatamente mudou?
3. Onde o revisor deve ter mais atenção?
4. O título deixa claro o objetivo principal do PR?
