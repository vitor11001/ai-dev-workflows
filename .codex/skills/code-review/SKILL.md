---
name: code-review
description: Use quando o usuário pedir review, revisão técnica ou validação antes de merge de Pull Request, branch, diff, commit ou arquivos alterados; também em segunda revisão após ajustes e investigação de bugs, regressões, domínio, segurança, autorização, OpenAPI, testes, performance, paginação ou N+1.
---

# Technical PR Review

## Princípio central

Revisar risco real, não aparência. Um achado só entra no relatório quando liga uma
invariante violada a um caminho de execução, impacto concreto, atribuição ao diff e
correção compatível com a arquitetura.

## Fluxo obrigatório

1. Ler todas as instruções aplicáveis ao repositório e à área alterada.
2. Determinar branch, base real, merge-base, commits exclusivos, worktree e escopo. Em
   repositório Git, executar `scripts/review_context.sh <base>` desta skill, resolvendo o
   caminho a partir do diretório deste `SKILL.md`, quando a base for conhecida.
3. Ler primeiro o diff; depois, apenas o contexto necessário: callers, models,
   serializers, views, controllers, jobs, signals, rotas, schema, cliente gerado, testes e
   decisões relacionadas.
4. Para cada suspeita, comparar com a base usando `git show <base>:<arquivo>` ou
   equivalente. Classificar a atribuição conforme [references/finding-quality.md](references/finding-quality.md).
5. Derivar invariantes e superfícies de risco a partir do diff. Não usar checklist como
   licença para inventar problemas.
6. Se houver escrita, transação, lock, job concorrente ou estado lido antes de gravar, ler
   [references/concurrency-transactions.md](references/concurrency-transactions.md) e montar
   ao menos uma interleaving adversarial.
7. Se houver API, evento, schema, CLI ou artefato gerado, ler
   [references/api-contract-rollout.md](references/api-contract-rollout.md).
8. Validar autorização, tenant, inputs externos, efeitos parciais, queries, paginação,
   compatibilidade e consumidores. Usar [references/review-surfaces.md](references/review-surfaces.md)
   para as superfícies tocadas pelo diff.
9. Rodar os menores testes e gates capazes de provar ou refutar os riscos. Não corrigir o
   código durante o review, salvo pedido explícito.
10. Aplicar o gate de qualidade de achado abaixo; omitir preferência cosmética sem risco.
11. Criar `tmp/YYYYMMDD-HHMMSS-code-review-<slug>.md` na raiz revisada, reproduzindo a
    revisão entregue ao usuário.

## Gate de qualidade do achado

Todo achado deve declarar:

- **Arquivo/trecho** com linha ou símbolo pesquisável.
- **Problema** e invariante violada.
- **Impacto** observável.
- **Cenário de risco** reproduzível ou sequência causal completa.
- **Atribuição:** introduzido; preexistente agravado; preexistente fora do escopo; ou
  dívida deliberada da cadeia.
- **Confiança:** confirmado, demonstrado ou ponto de atenção.
- **Sugestão de correção** objetiva.

Se faltar evidência para afirmar o defeito, investigar mais. Se ainda faltar, rebaixar
para ponto de atenção ou omitir. Não transformar gate vermelho em achado sem entender a
causa e o plano de integração.

## Testes derivados da mudança

| Mudança | Verificação mínima |
|---|---|
| Escrita persistente | sucesso, recusa, rollback, idempotência e concorrência relevante |
| Permissão/tenant | anônimo, papel inferior, papel permitido e recurso alheio |
| Endpoint/serializer | payload válido, inválido, ausente, status e response body |
| OpenAPI/gerado | implementação, schema versionado, geração e consumidor |
| Query/listagem | escopo, paginação, ordenação e contagem de queries |
| Signal/job/task | retry, duplicidade, efeito parcial e execução concorrente |

Teste faltante só é achado quando deixa risco relevante sem prova. Caso contrário,
registrar como lacuna menor ou não listar.

## Severidade e veredito

- **Crítica:** vazamento, corrupção/perda de dados, indisponibilidade provável ou
  regressão grave central → **Bloquear aprovação**.
- **Alta:** bug funcional importante, quebra de tenant/autorização/cliente, escrita
  inconsistente ou risco sério → no mínimo **Requer ajustes antes de aprovar**.
- **Média:** comportamento incorreto comum, teste crítico ausente, performance plausível
  ou contrato incompleto → normalmente **Requer ajustes antes de aprovar**.
- **Baixa:** convenção explícita, manutenção ou cobertura menor → **Aprovável com ajustes
  menores** quando forem os únicos achados.
- Sem achado relevante → **Aprovável**.

Não elevar severidade por gosto. Explicar frequência, alcance, detectabilidade e
reversibilidade quando influenciarem a classificação.

## Formato da resposta

1. `### Resumo executivo`
2. `### Achados` — ordenar por severidade; dizer explicitamente quando não houver.
3. `### Testes faltantes`
4. `### OpenAPI e contrato de API`
5. `### Segurança e autorização`
6. `### Banco, transações e performance`
7. `### Regressões possíveis`
8. `### Itens sem problema encontrado`
9. `### Validações executadas`
10. `### Veredito` — escolher exatamente uma opção definida acima.

Começar pelos achados quando o usuário pedir apenas “review”. Em segunda revisão,
revalidar o estado atual e registrar quais achados anteriores foram corrigidos, permanecem
ou deixaram de se aplicar.

## Erros comuns

- Revisar apenas linhas adicionadas e ignorar callers ou writers concorrentes.
- Reportar bug da base como se tivesse sido introduzido pelo PR.
- Bloquear stacked PR por dívida explicitamente destinada a uma branch posterior sem
  avaliar merge e rollout independentes.
- Chamar hipótese de “bug” sem sequência causal ou estado final observável.
- Confundir cobertura alta com cobertura do risco alterado.
- Listar estilo e duplicação antes de domínio, segurança, contrato e escrita.
