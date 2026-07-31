---
name: pr-description
description: Use quando houver pedido para criar, gerar, escrever, revisar, melhorar ou atualizar título ou descrição de Pull Request, PR, branch ou `pr_body.md`.
---

# Descrição de Pull Request

## Princípio

Descrever o resultado líquido da branch para o revisor, com o menor texto que preserve contexto, comportamento e atenção necessária.

## Procedimento

1. Trabalhar no repositório atual.
2. Executar `scripts/pr_context.sh`, localizado no diretório desta skill.
   - Se o usuário informar a base, executar `scripts/pr_context.sh --base <ref>`.
   - Se o script apontar bases ambíguas, pedir a base ao usuário antes de continuar.
3. Interpretar o contexto nesta ordem:
   1. **Diff final:** define o comportamento que efetivamente ficou na branch.
   2. **Testes, contratos e migrations:** confirmam comportamento observável, compatibilidade e transições de dados.
   3. **Commits:** explicam motivação, decisões e breaking changes, sem substituir o diff final.
   4. **Nome da branch:** serve apenas como pista auxiliar.
4. Identificar uma mudança principal e agrupar alterações de suporte sob esse resultado. Tratar arquivos gerados, serializers, schemas e testes relacionados como uma única mudança de contrato ou comportamento quando fizerem parte do mesmo efeito.
5. Escrever o título e a descrição no formato abaixo.
6. Por padrão, criar ou atualizar `tmp/pr-body-<branch-name>.md`.
   - Se o usuário pedir apenas para visualizar, responder na conversa e não criar arquivo.
7. Ignorar templates de PR. Não fazer commit nem publicar no GitHub sem pedido explícito.

## Formato

```md
# <título>

<uma frase explicando o resultado do PR>

- <mudança relevante>
- <mudança relevante>

**Atenção:** <breaking change, migration, risco de segurança ou ação operacional>
```

Aplicar estas regras:

- Limitar o título a 72 caracteres quando possível.
- Começar o título com verbo no infinitivo ou substantivo técnico específico.
- Usar uma frase de objetivo e no máximo três bullets.
- Omitir bullets quando a frase de objetivo já for suficiente.
- Incluir `**Atenção:**` somente quando o contexto demonstrar breaking change, migration ou transição de dados relevante, risco de segurança ou ação operacional necessária.
- Omitir seções vazias e frases de preenchimento como “Não identificado pelo diff”.
- Descrever comportamento e impacto para o revisor, não inventariar arquivos.
- Não criar seção de testes por padrão.

## Verificação

Antes de entregar, confirmar:

1. Cada afirmação possui evidência no diff final, nos testes ou nos commits.
2. O texto descreve apenas mudanças posteriores ao merge-base.
3. Nenhuma alteração intermediária removida pelo diff final aparece como resultado.
4. O objetivo principal pode ser entendido sem ler os bullets.
5. Não há segredos, credenciais, contexto de produto, issue ou teste inventado.
