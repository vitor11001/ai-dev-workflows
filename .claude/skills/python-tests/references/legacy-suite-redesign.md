# Redesenho de suíte legada

Fluxo para redesenhar os testes de um app ou módulo inteiro e retirar o legado sem perder cobertura útil. Vale quando o pedido é reorganizar a suíte (nova árvore de modalidades, conversão em massa, troca de mocks por comportamento real), não para ajustar um arquivo isolado.

## Visão geral

```
roteiro por blocos ─► matriz do bloco ─► baseline ─► redesenho ─► mutantes ─► remoção do legado ─► contagem
                       (perguntas)        (verde)     (subetapas)   (reancorar)  (com destino)
```

Cada bloco passa por: pendente → matriz definida → implementação → validação → concluído. Blocos grandes têm subetapas (A, B, C…), mas o bloco só fecha quando todas fecham. Não renumere a lista a cada descoberta; registre lacunas e correções no bloco responsável.

## 1. Roteiro por blocos

Antes da primeira matriz, divida o legado por responsabilidade de domínio (não por arquivo nem por pasta antiga):

| ID | Responsabilidade | Escopo e fronteira | Situação |
|---|---|---|---|
| B01 | Links de senha | Model do token, emissão, consumo, validade, concorrência | pendente |
| F01 | Encerramento | Auditoria do inventário, exclusão do legado, validação global | pendente |

- Cada responsabilidade transversal tem **um dono**. Os outros blocos só a testam quando acrescentam uma garantia distinta (ex.: o algoritmo do link é de B01; o efeito da troca de senha nas sessões é do bloco de sessões).
- Registre o inventário inicial (arquivos com testes e funções `test_*`, pela AST ou `pytest --collect-only`). Ele descreve o ponto de partida, não um percentual de conclusão.
- A divisão é estimativa: não implica um PR ou um turno por bloco.

## 2. Matriz do bloco

Use [test-matrix-template.md](test-matrix-template.md). A matriz:

- parte da responsabilidade do código e das regras documentadas, não só do que o legado já testa;
- avalia cada arquivo legado do recorte (útil, fraco, mal preparado, duplicado, sem sentido no contrato atual);
- registra modalidade, fronteira exercitada e atalhos de cada cenário (ver "Modalidade" no `SKILL.md`);
- dá destino a **todo** cenário legado do recorte;
- lista achados de produção sem corrigi-los e perguntas com recomendação;
- termina com a ordem em subetapas.

Pare depois da matriz e espere as decisões. A aprovação vale para o bloco, não para os seguintes.

## 3. Destino de cada cenário legado

| Código | Situação encontrada | Tratamento |
|---|---|---|
| **R** | Cenário útil para o contrato atual | Redesenhar na árvore nova, com asserções confiáveis, e apontar o ID novo. |
| **C** | Equivalente a outro já comprovado | Consolidar, registrando qual teste passa a guardar o comportamento. |
| **X** | Sem sentido no contrato atual, ou acoplado ao mecanismo com a mesma garantia já comportamental | Remover com justificativa concreta. Não preserve um fluxo inexistente só porque há teste antigo. |
| **outro bloco** | Pertence a outra responsabilidade | Fica ativo no legado até aquele bloco fechar. |

- Teste de rota removida (só confere 404/405) é **X**, sem substituto.
- Teste que caracteriza um defeito como esperado (um 400 que deveria ser 200) não é redesenhado como está: vira achado de produção.
- Teste "de cobertura" que mocka a própria lógica é **R** com o comportamento real, ou **X** se a garantia já existe sem o mock.

## 4. Baseline e redesenho

1. Rode os testes legados do recorte e registre quantos passaram. Legado vermelho antes de começar é achado, não algo a apagar.
2. Escreva os testes da subetapa no destino. Comportamento existente costuma passar de primeira; isso é esperado. Não altere produção para fabricar RED.
3. Se um teste novo passa mas não mede a regra (mutante sobrevive), corrija o **preparo ou a asserção**: confira o lado que o defeito não satisfaz, passe pelo caminho de produção (trava ligada, contador real, autenticação de produção), fixe a relação sorteada pela factory.
4. Defeito de produção encontrado: reproduza com RED pela regra, registre e pare para decisão (ver `SKILL.md`, "Defeito de produção encontrado em etapa de testes"). Com autorização, RED → correção mínima → GREEN, e registro na matriz.
5. Novos fakes, cenários e sondas vão em módulos `_*.py` no menor contexto compartilhado; fixtures, no `conftest.py`.

## 5. Mutantes

Se o projeto tiver catálogo de mutação (ou ao medir força das asserções numa cópia temporária):

- **Reancore** todo mutante cujo alvo era um teste legado removido, movido ou dividido. Alvo desatualizado depois de dividir um arquivo de teste faz o mutante sobreviver sem que nada tenha mudado na regra.
- Mutante que encolheu de alvo pode ter perdido o único teste que o matava; rode os mutantes de todos os alvos que mudaram, não só os novos.
- Mutante morto por erro de import, coleta ou construção do cenário não conta como medido; reformule-o para quebrar só a regra.
- Mutante que sobrevive por código redundante é equivalente, com a razão; o que sobrevive por defeito ou caminho inalcançável é lacuna conhecida, registrada, nunca "morto" por um teste que finge medi-lo.
- Regra crítica nova sem guarda ganha mutante só se o projeto curar o catálogo por regra decidida, nunca em lote.

## 6. Remoção do legado

- Remova apenas os cenários com destino R, C ou X conferido; os de outro bloco continuam ativos.
- Retire as dependências do caminho antigo: imports, fixtures e helpers sem consumidor, alvos de mutação, configuração de coleta e de classificação de testes.
- Não desative a coleta do legado nem use `skip`/`xfail` para adiantar a remoção.
- Reexport ou helper temporário só fica com consumidor real confirmado por busca (`rg`).
- No encerramento: inventário do legado em zero, toda função com destino rastreável (tabela da matriz ou andamento), nenhuma referência ao caminho antigo, nenhuma fixture em `test_*.py`, nenhuma classe `Test*`, nenhum auxiliar sem `_`, nenhuma pasta vazia.

## 7. Contagem antes e depois

Registre os casos coletados (`pytest --collect-only -q`, parametrizações expandidas, todos os markers) em cada marco:

| Momento | Total | Legado | Árvore nova (unit / integration / e2e) |
|---|---|---|---|
| Antes do redesenho (`<sha>`) | 615 | 615 | — |
| Fim do bloco B01 | 620 | 590 | 12 / 18 / 0 |
| Encerramento | 806 | 0 | 210 / 592 / 4 |

A contagem confere que nada se perdeu por engano; não é medida de qualidade. Contagem bruta de arquivos apagados também não é. Casos que foram para a suíte de outro módulo entram numa nota abaixo da tabela.

## Resposta final do redesenho

Além da tabela do modo refatorar, entregue o destino do recorte:

| Legado | Destino | Teste novo ou justificativa |
|---|---|---|
| `test_old_invite.py::test_resend` | R | `test_resend_invite_replaces_link_and_audits_requester` |
| `test_old_invite.py::test_mocked_check_password` | X | acoplado ao mecanismo; a garantia é comportamental em `test_change_refuses_unusable_link_identically` |
| `test_old_login.py::test_lockout` | outro bloco | B03 |

E, na verificação: baseline e depois, mutantes reancorados e o resultado, achados de produção e decisões pendentes.
