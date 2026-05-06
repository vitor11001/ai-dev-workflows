---
name: test-refactor
description: refatora, consolida e reorganiza testes python existentes para pytest, django e fastapi, seguindo o arquivo TESTING.md do repositório. use quando o usuário pedir para limpar testes legados, converter unittest, consolidar arquivos, renomear testes ou alinhar a suíte ao padrão atual.
---

# Refatoração de Testes

## Objetivo

Melhorar testes existentes sem mudar o comportamento validado, alinhando a suíte ao padrão atual do repositório.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "refatore esses testes"
- "converta esses testes para pytest"
- "organize a suíte"
- "consolide os testes desse módulo"
- "limpe os testes legados"

## Saída esperada

Arquivos de teste reorganizados, renomeados ou consolidados, preservando cobertura útil e seguindo o `TESTING.md`.

## Procedimento

Quando esta skill for usada:
1. Leia `TESTING.md` antes de editar a suíte.
2. Identifique duplicações, nomes genéricos, classes legadas e arquivos fora do espelhamento correto.
3. Preserve intenção e comportamento dos testes válidos.
4. Converta padrões legados para `pytest` funcional quando isso reduzir complexidade.
5. Consolide testes do mesmo módulo no arquivo que segue o espelhamento correto.
6. Remova sobras locais como `__pycache__`, arquivos temporários e diretórios vazios quando fizer parte do trabalho solicitado.

## Regras obrigatórias

- Não replique `unittest.TestCase` sem pedido explícito.
- Não mover arquivos arbitrariamente sem justificar pelo espelhamento.
- Não apagar testes úteis só porque estão feios; primeiro preserve a intenção.
- Prefira factories, fixtures pequenas e helpers locais.
- Se a suíte estiver ambígua, baseie a decisão no comportamento real do código, não em convenções antigas.

## Critérios de revisão

Antes de entregar, confirme:
1. A suíte ficou mais simples de manter?
2. O espelhamento com o código de produção ficou correto?
3. Houve preservação do comportamento já coberto?
4. Restaram padrões legados evitáveis?
