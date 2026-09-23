# Concorrência e transações

Ler quando o diff toca escrita persistente, transação, lock, cache mutável, job, signal,
retry ou mais de um caminho que altera o mesmo agregado.

## Modelo mínimo

1. Listar o estado lido e o instante em que foi lido.
2. Listar validações executadas antes da escrita.
3. Listar linhas/recursos travados e o início/fim de cada transação.
4. Procurar outro writer: endpoint, admin, task, signal, command, webhook ou callback.
5. Montar uma sequência `A1 → B1 → B2 → A2` que maximize estado obsoleto.
6. Calcular o estado final no banco, não apenas o estado das instâncias em memória.

## Checklist

- A validação e a escrita usam a mesma versão do agregado?
- Todos os writers concorrentes travam a mesma linha?
- A ordem dos locks é consistente entre fluxos?
- O isolamento usado realmente impede a interleaving?
- `update_fields`, update parcial, bulk update ou upsert pode combinar estado novo e antigo?
- `clean()`/validação de aplicação usa dados que ficaram obsoletos antes do SQL?
- Há constraint, unique index, FK composta ou exclusion constraint protegendo a invariante?
- Retry ou redelivery duplica efeito não idempotente?
- Exceção depois de efeito externo deixa commit parcial ou mensagem órfã?

Lock em entidade relacionada não protege automaticamente a linha escrita. `atomic()` sem
lock ou constraint também não impede lost update, write skew ou validação sobre snapshot
obsoleto.

## Evidência e teste

Preferir teste de integração no banco real, com transações/conexões distintas e barreiras
determinísticas. O teste deve controlar a ordem dos passos e afirmar a invariante final.
Não usar `sleep` como sincronização principal. Se a reprodução for impraticável, descrever
a interleaving completa e marcar a confiança como “demonstrado”.
