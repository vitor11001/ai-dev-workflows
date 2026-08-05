# Qualidade e atribuição de achados

## Atribuição obrigatória

Comparar a suspeita com o merge-base antes de comentar:

| Classificação | Quando usar | Tratamento |
|---|---|---|
| Introduzido neste diff | O comportamento inseguro não existia na base | Reportar normalmente |
| Preexistente agravado | O padrão já existia, mas o diff amplia alcance, permissão, frequência ou impacto | Reportar nas linhas novas e declarar a raiz preexistente |
| Preexistente fora do escopo | O diff não muda probabilidade nem impacto | Não bloquear o PR; mencionar apenas se indispensável ao contexto |
| Dívida deliberada da cadeia | Plano atribui a correção/geração a PR posterior | Avaliar se merge ou deploy intermediário é possível; registrar condição de integração |

Não usar “preexistente” para absolver uma expansão real do risco. Não usar “stacked PR”
para aceitar um estado intermediário que pode ser liberado sozinho.

## Confiança

- **Confirmado:** teste, comando, log, consulta ou reprodução observou o comportamento.
- **Demonstrado:** o caminho é determinístico e a sequência causal está completa, mesmo
  sem reprodução executável.
- **Ponto de atenção:** há sinal plausível, mas falta evidência para afirmar o defeito.

Se uma reprodução for segura e proporcional ao risco, tentar antes de usar “demonstrado”.

## Gate antes de publicar

Responder “sim” a todas:

1. Qual invariante ou contrato foi violado?
2. Qual entrada, estado ou interleaving chega ao trecho?
3. Qual estado ou resposta incorreta é observável?
4. O problema pertence ao diff ou foi agravado por ele?
5. A severidade considera alcance, frequência, detecção e reversão?
6. A correção proposta preserva as fronteiras do projeto?

Se a resposta 1–4 for “não sei”, investigar ou omitir. Preferência de estilo não substitui
impacto.

## Segunda revisão

Não copiar o relatório anterior. Para cada achado antigo:

- localizar o código atual;
- repetir a reprodução ou prova;
- marcar como corrigido, ainda presente ou não aplicável;
- procurar regressões introduzidas pelo ajuste.
