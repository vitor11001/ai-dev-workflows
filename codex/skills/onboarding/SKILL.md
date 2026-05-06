---
name: onboarding
description: mapeia rapidamente um projeto para explicar arquitetura, estrutura, stack, comandos, testes, convenções e áreas críticas. use quando o usuário pedir para analisar um projeto, entender um codebase, fazer onboarding técnico, resumir a arquitetura ou explicar como começar a trabalhar no repositório.
---

# Onboarding de Projeto

## Objetivo

Produzir um resumo operacional do repositório para acelerar entendimento humano ou de LLM.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "analise todo o projeto"
- "me explique esse repositório"
- "faça um onboarding técnico"
- "mapeie a arquitetura"
- "como começo a trabalhar nesse codebase?"

## Saída esperada

Um resumo conciso com stack, estrutura principal, pontos de entrada, convenções, estratégia de testes, comandos relevantes e riscos ou lacunas de documentação.

## Procedimento

Quando esta skill for usada:
1. Mapeie a estrutura do repositório e os arquivos de configuração mais relevantes.
2. Identifique a finalidade do projeto e seus componentes principais.
3. Localize pontos de entrada, scripts importantes, convenções de teste e documentação existente.
4. Resuma o que é essencial para começar a trabalhar sem tentar esgotar todos os detalhes.
5. Aponte riscos, lacunas e ambiguidades quando existirem.

## Regras obrigatórias

- Priorize sinais concretos do repositório sobre suposições.
- Diferencie fatos observados de inferências.
- Prefira uma visão operacional do projeto, não um inventário exaustivo.
- Se o projeto estiver subdocumentado, diga isso explicitamente.

## Critérios de revisão

Antes de entregar, confirme:
1. O resumo ajuda alguém a começar a trabalhar no projeto?
2. Há separação clara entre observação e inferência?
3. A análise destacou os pontos críticos sem se perder em detalhes marginais?
