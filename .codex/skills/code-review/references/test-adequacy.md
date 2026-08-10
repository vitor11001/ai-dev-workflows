# Adequação semântica dos testes

Use este roteiro para verificar se os testes provam o comportamento anunciado, e não
apenas se executam linhas ou permanecem verdes.

## Matriz obrigatória

Para cada invariante relevante alterada, registre:

| Campo | Pergunta |
|---|---|
| Promessa | Qual regra o código, PR, comentário ou nome do teste afirma garantir? |
| Caminho produtivo | Qual chamada real decide essa regra? |
| Precondição discriminante | Que estado faria a implementação correta e uma mutante produzirem resultados diferentes? |
| Fronteira observável | Onde o consumidor percebe o resultado: HTTP, banco, log, fila, UI ou contagem de queries? |
| Teste | Qual teste monta a precondição e observa essa fronteira? |
| Evidência | O teste falha quando a causa específica é neutralizada ou invertida? |

Classifique a cobertura como:

- **Ausente:** nenhum teste atravessa o caminho e a fronteira relevantes.
- **Parcial:** o teste cobre só parte do domínio prometido, como quatro de seis posições.
- **Tautológica:** a fixture torna a asserção verdadeira independentemente da regra.
- **Mutante sobrevivente:** a alteração causal mantém o teste verde.
- **Mutante morto:** a alteração causal produz a falha funcional esperada.

## Sinais de falsa segurança

- O teste promete ordem ou prioridade, mas não cria alternativas concorrentes.
- A fixture usa somente estados válidos quando a regra decide entre dois estados inválidos.
- Uma enumeração tem N casos, mas o teste instancia apenas um subconjunto.
- Um prefetch é defendido sem medir queries pela rota, paginação e serializer reais.
- Um serviço é testado, mas o endpoint pode deixar de chamá-lo sem falha.
- A asserção continua verdadeira se a guarda, chamada, filtro, ordenação ou prefetch for
  removido.
- O nome do teste, a cobertura de linhas ou o total verde é usado como substituto da
  precondição discriminante.

## Sonda de mutação causal

Use mutação manual somente quando houver hipótese causal específica e um teste-alvo. Ela
complementa, mas não substitui, uma reprodução na fronteira.

1. Registre o status e o diff originais.
2. Crie um worktree temporário e isolado, preferencialmente com `mktemp -d` e HEAD
   destacado.
3. Confirme que o teste-alvo passa sem mutação.
4. Faça uma única alteração mínima que neutralize ou inverta a regra: remover uma chamada,
   inverter duas posições, trocar a ordem de guardas ou retirar um prefetch.
5. Rode somente o teste-alvo ou o menor conjunto capaz de observar a fronteira.
6. Considere o mutante morto apenas se houver a falha funcional esperada. Erro de sintaxe,
   importação, coleta ou setup é sonda inválida.
7. Remova o worktree temporário e confirme que status e diff originais não mudaram.

Não mutar migrations, arquivos gerados, lockfiles, infraestrutura, deploy ou integrações
externas. Não executar uma sonda sem teste-alvo e diferença observável previstas. Se a
mutação for arriscada, cara ou pouco isolável, descreva a prova discriminante esperada e
rebaixe a confiança em vez de simular certeza.

## Como relatar

Uma lacuna relevante deve citar a promessa, o trecho produtivo, o estado que o teste atual
deixa de montar, a fronteira sem prova e o impacto. Quando houver mutação, informe a
alteração aplicada e se o teste sobreviveu ou falhou pelo motivo esperado.
