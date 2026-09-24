# Superfícies de revisão

Carregar apenas as seções tocadas pelo diff.

## Domínio e comportamento

- Traduzir a mudança em invariantes antes de avaliar a implementação.
- Conferir estados inicial, válido, inválido, vazio, limite e transições reversas.
- Procurar writers alternativos e efeitos em fluxos existentes.

## Segurança e tenant

- Separar autenticação, autorização de ação e escopo do objeto.
- Verificar usuário sem papel, membership inativa, tenant ausente e recurso alheio.
- Evitar enumeração: comparar 403/404 com a política existente.
- Conferir ownership novamente na escrita, não apenas na listagem.

## Banco e consultas

- Procurar N+1 em serializers, properties, loops, admin e paginação.
- Confirmar filtros no banco, índices compatíveis, ordenação determinística e limites.
- Em update/delete, verificar escopo do queryset e linhas afetadas.
- Em migrations, avaliar reversibilidade, lock, backfill e coexistência entre versões.

## Jobs e integrações

- Avaliar timeout, retry, idempotência, deduplicação e ordem de mensagens.
- Conferir transação de banco versus efeito externo e estratégia de compensação/outbox.
- Não fazer chamadas externas reais durante o review sem autorização.

## Qualidade estrutural

Reportar nomes fora do idioma exigido, tipos vagos, função grande, duplicação, comentário
obsoleto ou fronteira ruim apenas quando houver regra explícita ou impacto de manutenção.
Preferir risco funcional a preferência pessoal.

Duplicação de regra, a mesma decisão implementada em mais de um lugar com resultados
diferentes, não é estilo: seguir [sibling-implementations.md](sibling-implementations.md).

Classes e métodos em idioma diferente do inglês são achado de convenção mesmo quando o
comportamento estiver correto; incluir nome atual, local e sugestão objetiva em inglês.
