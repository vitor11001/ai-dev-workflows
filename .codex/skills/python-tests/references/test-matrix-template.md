# Modelo de matriz de testes

Matriz de cenários a montar **antes** de implementar um recorte com mais de um punhado de testes ou qualquer redesenho de legado. Ela fixa o que cada teste prova, em que modalidade e arquivo, e o que acontece com o legado. Remova as seções que não se aplicarem (sem legado, sem achados, sem E2E). Grave no diretório de trabalho da task, se o projeto tiver um (ex.: `tmp/tasks/<ID>/`); senão, entregue na resposta.

```markdown
# <ID> — <bloco>: matriz de <responsabilidade>

> Status: matriz definida; nada implementado.
> Base: <branch/sha>. Referências: <invariantes, docs, matrizes anteriores>.

## Responsabilidade do bloco

| Fonte | Responsabilidade neste bloco |
|---|---|
| `app/orders/services/refund.py` | estorno parcial e total, recusa de pedido já estornado |

### Fronteiras com outros blocos

| Assunto | Dono | Motivo |
|---|---|---|
| Permissão do endpoint de estorno | B05 | matriz de permissões cobre todos os endpoints |

## Avaliação do legado do recorte

| Arquivo legado | Funções | Avaliação |
|---|---|---|
| `tests/test_refund_coverage.py` | 6 | útil, mas mocka o próprio service; asserts com `or` |

### Testes mal preparados ou com asserção fraca

1. **Mock da lógica testada.** <qual teste, o que substitui, por que passa sem a regra>
2. **Preparo fora do caminho de produção.** <trava desligada pelo ambiente, backend implícito>

### Lacunas

1. <comportamento sem teste nenhum hoje>

### Achados de produção (somente leitura)

| # | Onde | Achado | Proposta |
|---|---|---|---|
| A1 | `refund.py:refund_order` | estorno duplicado quando duas requisições chegam juntas | reproduzir em REFUND-04 (RED esperado); corrigir só com autorização |

## Matriz proposta

Modalidade e atalhos: <o que é integração e por quê; fronteiras simuladas (só externas); autenticação
forçada ou real; relógio fixo; preparo de estado legado>.

### <Grupo> — <camada>

Destino: `tests/integration/orders/services/test_refund.py` (novo | existente).

| ID | Nome | Casos | Descrição e resultado esperado |
|---|---|---|---|
| REFUND-01 | `test_partial_refund_keeps_remaining_balance` | 3 | Estorno de 10%, 50% e 99%. Saldo restante exato, um registro de estorno, evento publicado na fake do gateway. |
| REFUND-02 | `test_refund_refusal_leaves_order_untouched` | 2 | Pedido cancelado e já estornado. Mensagem da recusa; pedido, saldo e eventos intactos. |

### E2E (só com garantia adicional)

| ID | Nome | Garantia adicional sobre a integração |
|---|---|---|
| E2E-01 | `test_customer_requests_refund_and_sees_balance` | Login real, pedido de estorno pela API e saldo consultado pela API; nada conferido pelo ORM. |

Total proposto: <n> funções/<m> casos (<x> unitários, <y> de integração, <z> E2E).

## Destino dos cenários legados

Legenda: **R** redesenhar; **C** consolidar em teste existente; **X** remover com justificativa; **B0n** fica para outro bloco.

| Legado | Destino |
|---|---|
| `test_refund_coverage.py#12` | R → REFUND-01 |
| `…#40` mock do service | X: acoplado ao mecanismo; mesma garantia em REFUND-02 |
| `…#58` permissão | B05 |

Arquivos que saem ao fim do bloco: <lista>. Os mistos perdem só as funções acima.

## Mutantes a reancorar e acrescentar

(Só se o projeto tiver catálogo de mutação.)

| Mutante | Alvo atual | Novo alvo |
|---|---|---|
| `estorno/saldo-ignorado` | `test_refund_coverage.py` | `test_refund.py` |

## Perguntas

1. <decisão necessária>. **Recomendação:** <opção e motivo>.

## Ordem em subetapas

1. **A, <tema>:** REFUND-01 a 03. Baseline do legado do recorte antes.
2. **B, <tema>:** REFUND-04 (reproduz A1 e para no RED).

Cada subetapa: baseline, implementação, mutantes reancorados e medidos, remoção só das funções
substituídas, testes focados.

## Andamento

- <data hora>: matriz definida; nenhum teste executado.
```

## Regras do preenchimento

- **ID** curto e estável por grupo (`REFUND-01`, `LOGIN-U01` para unitário). Não renumere depois de aprovado; cenário novo ganha o próximo número.
- **Nome** é o nome real da função de teste, semântico e em inglês.
- **Casos** conta as parametrizações; cada caso aparece na descrição.
- **Descrição e resultado esperado** diz o preparo que importa, o que se confere e o que deve ficar intacto nas recusas. "Funciona" ou "retorna sucesso" não serve.
- Comportamento que o legado já guarda bem é consolidado, não reescrito por reescrever.
- A matriz pode registrar caracterização de comportamento atual só como decisão explícita; achado de produção em aberto vai para "Achados", nunca para o resultado esperado.
- Perguntas sempre com recomendação. Feche-as (com data) antes da implementação e mova a decisão para o texto da matriz.
- O "Andamento" registra o que realmente rodou: comandos, quantos passaram, mutantes mortos, legados removidos. Nada de validação não executada.
