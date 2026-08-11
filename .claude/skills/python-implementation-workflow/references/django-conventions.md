# Convenções Django

Assuntos Django que não entram no caminho quente da skill. Transações e ORM ficam
inline no `SKILL.md` porque previnem bug direto; o que está aqui é disciplina de
manutenção. Consulte quando a task tocar um destes assuntos.

## Controllers: entrada e saída com Pydantic

- O controller modela entrada e saída com Pydantic — não com dicionário solto nem
  com o serializer do DRF, que só existe no caminho HTTP.
- O import é **sempre** aliased: `from pydantic import BaseModel as PydanticBaseModel`.
  `BaseModel` sem alias colide conceitualmente com o `Model` do Django e torna
  ambíguo, na leitura, de qual camada aquela classe é.
- Nomeie pelo papel: `<Algo>Input` para entrada, `<Algo>Output` para saída, ambos
  herdando de `PydanticBaseModel`.
- Use `validate_call` no método do controller quando a validação couber na assinatura.

```python
from pydantic import BaseModel as PydanticBaseModel, ConfigDict, validate_call


class EventInput(PydanticBaseModel):
    """Entrada validada para criação de evento."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    occurred_at: datetime
    tag_link: TagLinks
```

É assim que o controller cumpre a revalidação que a arquitetura exige: task, signal
e management command chegam nele sem passar por serializer, e o modelo Pydantic
valida em qualquer caminho de entrada.

## ORM e performance

- Ao escrever a query, já declare `select_related` (FK e OneToOne) e
  `prefetch_related` (reverso e M2M) para o que o consumidor vai acessar. N+1 se
  resolve na escrita, não no teste.
- `bulk_create` e `bulk_update` em vez de laço de `save()` — lembrando que eles
  **não** disparam signals nem `save()` sobrescrito.
- `.exists()` para saber se há registro; `.count()` só quando o número importa.
  Nunca `len(queryset)` para contar.
- `.iterator()` quando o volume não couber confortavelmente em memória.
- QuerySet é lazy: não force avaliação (lista, `len`, `bool`) se ainda vai filtrar.
- Não escreva SQL cru quando manager ou queryset resolverem. Se for inevitável,
  **parametrize** — nunca interpole string na query.

## Migrations

- Não crie migration sem mudança real de model ou necessidade explícita de dados.
- **Revise a migration gerada antes de finalizar.** O `makemigrations` acerta a
  maior parte, não tudo: confira nome de constraint, ordem de dependência e o
  efeito de um default novo em tabela grande.
- Nunca edite migration antiga já aplicada sem orientação explícita.
- Campo novo não-nulo em tabela existente precisa de default ou de migration em
  etapas — schema, backfill, constraint.
- Migration de dados: pequena, reversível quando possível e coberta por validação.
  Separe de migration de schema sempre que der.

## Celery

- Task fina: valida o mínimo, chama o controller, trata o erro. A regra de negócio
  fica no controller, onde é testável sem Celery.
- **Passe identificador, não objeto.** O worker recarrega do banco; objeto
  serializado na fila chega desatualizado.
- Prefira task idempotente: ela será reexecutada.
- Retry, backoff e tratamento de erro explícitos. Não confie no comportamento padrão.
- Task agendada precisa de guarda contra execução concorrente quando o trabalho não
  for idempotente.

## Signals

- Signal serve para efeito genérico e desacoplado — auditoria, invalidação de cache,
  indexação. Não serve para regra de negócio.
- **Regra de negócio em signal esconde o fluxo:** quem lê o controller não vê o que
  acontece, e o teste precisa conhecer um efeito invisível no código.
- Quando o efeito faz parte do caso de uso, chame explicitamente no controller.
- Se usar signal, teste o efeito observável — não que o signal disparou.
- Lembre que `bulk_create` e `bulk_update` não disparam signals.

## Logs e segredos

- JSON estruturado em log de debug e observabilidade. Texto simples apenas em saída
  de CLI voltada ao usuário.
- **Nunca logue API key, token, senha ou dado sensível.** Mascare.
- Stack trace completo apenas em modo debug.
- Log em task segue o mesmo padrão estruturado do resto do projeto.

## Settings e artefatos gerados

- Não altere settings, infraestrutura ou automação fora do escopo pedido.
- Em projeto com settings modulares por área, a configuração nova vai no módulo do
  assunto, não no `base`.
- Não edite à mão artefato gerado pelo pipeline — schema OpenAPI, lockfile,
  estáticos coletados. Rode o alvo que o regenera.
