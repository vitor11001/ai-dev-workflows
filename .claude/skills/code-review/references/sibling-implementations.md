# Implementações irmãs e fallback tolerante

Ler quando o diff criar ou alterar um helper, tradutor, formatador, validador ou regra
reaproveitável, ou quando tratar exceção devolvendo um valor tolerante em vez de propagar.

## Implementações irmãs

Um helper novo raramente é a primeira resposta para o problema dele. Antes de aceitá-lo,
procurar as respostas anteriores:

1. Identificar a chamada central do helper (a API consultada, o registro lido, a exceção
   tratada) e buscá-la no repositório com `rg`, fora dos testes.
2. Para cada ocorrência que resolva a mesma pergunta, anotar o que ela faz na entrada
   válida, na ausente e na desconhecida.
3. Montar a tabela `local -> entrada ausente -> entrada desconhecida -> quem consome`.
4. Executar as irmãs com a mesma entrada ruim. Divergência lida é hipótese; divergência
   executada é evidência. A execução também expõe defeito que a leitura esconde, como lista
   vazia indexada depois de todos os itens serem descartados.

Classificar:

- **Achado da branch:** a issue pede um caminho único ou proíbe texto montado à mão, e o
  diff soma mais uma implementação em vez de convergir as existentes; ou a regra de
  duplicação do repositório (ex.: DRY na terceira ocorrência) é explícita.
- **Risco preexistente observado:** a irmã tem defeito próprio, comprovado na execução,
  que o diff não tocou.
- **Não reportar:** a irmã resolve pergunta mais ampla e só compartilha parte da chamada.
  Nesse caso, dizer qual trecho dela pode usar o helper e qual não pode, em vez de pedir
  a troca inteira.

Duplicação de regra não é estilo: a mesma decisão implementada em lugares diferentes com
resultados diferentes produz saídas divergentes para a mesma entrada.

## Fallback tolerante

Todo `except` ou ramo de "não encontrado" que devolve um valor em vez de falhar responde
a três perguntas:

1. **O valor devolvido reintroduz o problema que a mudança elimina?** Testar com o
   exemplo de valor ruim citado na própria issue. Se a issue fala de vazamento de slug e
   o fallback devolve o slug, o fallback é o vazamento.
2. **Quem fica sabendo quando o ramo executa?** Sem log, métrica ou erro, o dado
   inconsistente some dentro de uma saída bem-formada. Exigir aviso estruturado com o
   valor que caiu no fallback.
3. **Com que frequência o ramo executa?** Em caminho quente (geração de evento, loop
   por registro), um aviso por ocorrência vira ruído. Sugerir deduplicação por valor ou
   agregação, e não a remoção do aviso.

Manter a tolerância quando falhar quebraria uma gravação legítima; o que se cobra é a
observabilidade, não a exceção.
