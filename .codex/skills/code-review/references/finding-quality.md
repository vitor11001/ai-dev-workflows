# Qualidade e atribuição de achados

## Atribuição obrigatória

Comparar a suspeita com o baseline do escopo antes de comentar: merge-base para branch,
pai selecionado para commit e HEAD para alterações locais combinadas. Staged e unstaged
isolados usam, respectivamente, HEAD e índice. A ponta atual da base de destino serve
para integração, não para atribuir ao PR mudanças posteriores ao merge-base.

| Classificação | Quando usar | Tratamento |
|---|---|---|
| Introduzido neste diff | O comportamento inseguro não existia na base | Reportar normalmente |
| Preexistente agravado | O padrão já existia, mas o diff amplia alcance, permissão, frequência ou impacto | Reportar nas linhas novas e declarar a raiz preexistente |
| Preexistente fora do escopo | O diff não muda probabilidade nem impacto | Se material e comprovado, registrar separadamente; nunca tratar como achado da branch |
| Dívida deliberada da cadeia | Plano atribui a correção/geração a PR posterior | Avaliar se merge ou deploy intermediário é possível; registrar condição de integração |

Não usar “preexistente” para absolver uma expansão real do risco. Não usar “stacked PR”
para aceitar um estado intermediário que pode ser liberado sozinho.

## Riscos preexistentes observados

Usar esta categoria quando todas as condições forem verdadeiras:

1. O problema surgiu ao ler o contexto necessário do diff: caller, callee, handler,
   writer concorrente, model, contrato ou teste relacionado.
2. Há invariante violada, caminho alcançável, impacto material e evidência confirmada ou
   demonstrada na fronteira correspondente.
3. A comparação com a base prova que o diff não introduz nem agrava o risco.

Relatar em seção própria com arquivo/trecho, impacto, evidência e indicação objetiva de
issue ou correção separada. A seção informa dívida descoberta, mas não altera o veredito da
branch. Se nenhuma ocorrência passar esse gate, omitir a seção inteira.

Manter a busca limitada ao contexto necessário: não iniciar auditoria ampla, varredura de
módulos não tocados ou testes exploratórios sem relação causal com o diff. Problema apenas
plausível, cosmético ou de baixo impacto continua fora do relatório.

## Confiança

- **Confirmado:** teste, comando, log, consulta ou reprodução observou o comportamento.
- **Demonstrado:** o caminho é determinístico e a sequência causal está completa, mesmo
  sem reprodução executável.
- **Ponto de atenção:** há sinal plausível, mas falta evidência para afirmar o defeito.

Se uma reprodução for segura e proporcional ao risco, tentar antes de usar “demonstrado”.

## Evidência na fronteira

Confirmar o impacto na mesma interface em que ele foi alegado. Rastrear todo o caminho
entre o trecho suspeito e o efeito observável, incluindo middleware, handlers globais,
mapeadores de exceção, serializers, rollback transacional, retries, adapters e callers.

- Para afirmar status ou body HTTP, exercitar a request stack ou provar o mapeamento do
  handler configurado.
- Para afirmar retry, ack ou dead letter de job/evento, exercitar o worker e sua política.
- Para afirmar exit code ou output de CLI, executar a entrada pública do comando.
- Teste de controller não confirma status HTTP; exceção sem `catch` local não implica 500
  quando framework ou handler global pode convertê-la.

Uma reprodução em camada interna confirma somente aquela observação. Se não for viável
exercitar a fronteira, a sequência causal deve incluir explicitamente todos os
interceptadores aplicáveis; sem isso, manter como ponto de atenção ou omitir.

## Gate antes de publicar

Responder “sim” a todas:

1. Qual invariante ou contrato foi violado?
2. Qual entrada, estado ou interleaving chega ao trecho?
3. Qual estado ou resposta incorreta é observável?
4. A evidência atravessa a mesma fronteira em que o impacto foi alegado?
5. O problema pertence ao diff ou foi agravado por ele?
6. A severidade considera alcance, frequência, detecção e reversão?
7. A correção proposta preserva as fronteiras do projeto?

Se a resposta 1–5 for “não sei”, investigar ou omitir. Preferência de estilo não substitui
impacto.

## Segunda revisão

Não copiar o relatório anterior. Para cada achado antigo:

- localizar o código atual;
- repetir a reprodução ou prova;
- marcar como corrigido, ainda presente ou não aplicável;
- procurar regressões introduzidas pelo ajuste.
