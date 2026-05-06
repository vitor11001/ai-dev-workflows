---
name: code-review
description: revisa diffs, branches e arquivos alterados com foco em bugs, regressões, riscos e lacunas de teste. use quando o usuário pedir review, revisão de código, análise de PR, análise de diff ou validação técnica antes de merge.
---

# Revisão de Código

## Objetivo

Analisar mudanças de código com foco primário em problemas reais e riscos de comportamento.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "faça um code review"
- "revise esse diff"
- "analise esse PR"
- "veja se essa mudança tem risco"
- "aponte problemas nesse código"

## Saída esperada

Uma lista de achados priorizados por severidade, com arquivo e linha quando possível. Se não houver achados, diga isso explicitamente e mencione riscos residuais ou lacunas de teste.

## Procedimento

Quando esta skill for usada:
1. Identifique o escopo da revisão: diff, branch atual ou arquivos específicos.
2. Leia primeiro as mudanças e depois o contexto mínimo necessário do código afetado.
3. Procure bugs, regressões, riscos de dados, falhas de contrato, problemas de concorrência, segurança e lacunas de teste.
4. Priorize achados concretos e reproduzíveis sobre opiniões estilísticas.
5. Mantenha o resumo breve; o foco principal deve ser nos findings.

## Regras obrigatórias

- Comece pelos achados, em ordem de severidade.
- Use referências de arquivo e linha quando disponíveis.
- Não dilua o review com sugestões cosméticas se houver riscos funcionais mais importantes.
- Se algo depender de hipótese, deixe isso explícito.
- Se não houver problemas relevantes, declare isso com clareza.

## Critérios de revisão

Antes de entregar, confirme:
1. Os achados são específicos e acionáveis?
2. Há evidência suficiente para cada ponto?
3. O review está focado em risco real, não em preferência pessoal?
