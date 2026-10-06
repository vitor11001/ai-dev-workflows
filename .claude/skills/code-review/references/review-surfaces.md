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

## Reorganização de código

Num PR cujo objetivo declarado é extrair, dividir, mover ou agrupar código, a estrutura
resultante é o produto, e a régua de "sem impacto de comportamento" não basta. Para cada
unidade criada ou renomeada (módulo, classe, função pública):

- Listar o que ela contém e comparar com o que o nome promete. Responsabilidade que o
  nome não anuncia (a flag que liga o recurso dentro de `RedisFailOpen`, a normalização
  de entrada dentro de um wrapper de I/O) é achado de coesão.
- Perguntar: quem procura onde X é decidido chega a este nome? Se não, o leitor
  seguinte vai duplicar X ou alterá-lo no lugar errado.
- Desconfiar de justificativa técnica no docstring ("fica aqui para evitar import
  circular") que explica o lugar, mas não o nome: muitas vezes o ciclo se resolve com um
  módulo próprio e bem nomeado.
- Equivalência de comportamento (AST, suíte verde, sonda de patch) prova que nada
  quebrou, não que a divisão ficou boa. Registrar as duas avaliações separadamente.

Severidade normalmente baixa ("convenção explícita ou manutenção"), mas o achado entra
no relatório: num PR de reorganização, é a avaliação da própria entrega.
