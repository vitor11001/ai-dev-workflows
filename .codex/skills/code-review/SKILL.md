---
name: code-review
description: Revisao tecnica senior de Pull Requests, branches, diffs ou arquivos alterados. Use quando o usuario pedir review/revisao tecnica/analise de PR, validacao antes de merge, segunda revisao apos ajustes, ou quiser encontrar bugs, regressões, problemas de dominio, seguranca, autorizacao, OpenAPI, testes, performance, paginacao, N+1 e boas praticas de codigo com foco em risco real.
---

# Technical PR Review

## Objetivo

Executar uma revisao tecnica senior, em PT-BR, priorizando riscos reais de producao, regressões, contrato, seguranca, dominio, testes e qualidade de codigo. Nao fazer revisao superficial nem focar em preferencias cosmeticas quando nao houver risco.

## Fluxo

1. Identificar o escopo real da revisao: branch atual, diff staged, diff unstaged, arquivos citados ou PR informado.
2. Ler primeiro o diff e depois o menor contexto necessario: models, serializers, views, controllers, rotas, schema, testes e docs relacionados.
3. Verificar se ha mudancas nao staged ou base de comparacao incomum; deixar isso claro quando impactar a revisao.
4. Validar comportamento contra o contexto informado pelo usuario e contra as regras ja existentes no codigo.
5. Rodar testes focados quando viavel. Se nao conseguir, explicar o motivo e nao inventar resultado.
6. Reportar apenas achados acionaveis, com evidencia concreta. Se algo for suspeito mas nao comprovado, marcar como ponto de atencao.
7. Ao finalizar a revisao, criar sempre um arquivo Markdown em `tmp/` na raiz do projeto revisado, com timestamp no inicio do nome no formato `YYYYMMDD-HHMMSS-code-review-<slug>.md`. O conteudo deve reproduzir a revisao entregue ao usuario, incluindo achados, testes faltantes, contrato, seguranca, performance e veredito. Se `tmp/` nao existir, cria-la antes de salvar.

## Prioridades De Revisao

Investigar, nesta ordem:

- Bugs funcionais e regressões de comportamento.
- Quebras de regra de dominio, especialmente confusao entre item unico e grupo.
- Autenticacao, autorizacao, escopo por usuario, grupo, organizacao ou tenant.
- Validacoes ausentes ou insuficientes em input externo.
- Contrato de API e OpenAPI divergente do codigo, incluindo status codes, schemas, permissoes, paginacao, exemplos e response body.
- Testes faltantes, frageis, falsos positivos ou que nao cobrem caminho critico.
- Transacoes, atomicidade, rollback parcial e efeitos colaterais em escritas.
- Queries ineficientes, N+1, filtros no Python que deveriam estar no banco, paginacao incorreta e consultas sem escopo seguro.
- Regressões em endpoints, modelos, serializers, tarefas, sinais, comandos e fluxos existentes.
- Classes e metodos com nomes em idioma diferente do ingles.
- Boas praticas de codigo quando afetarem manutencao, risco, clareza ou arquitetura.

## Boas Praticas De Codigo

Avaliar boas praticas com peso tecnico, nao cosmetico. Apontar quando houver impacto real ou violacao explicita de convencao do projeto:

- Classes e metodos devem sempre usar nomes em ingles. Ao encontrar classe ou metodo com nome em portugues, espanhol ou qualquer outro idioma diferente do ingles, reportar como erro de revisao mesmo que o comportamento esteja correto. Incluir o nome atual, o local e uma sugestao objetiva de renomeacao em ingles.
- Nomes pouco especificos que dificultam manutencao ou busca.
- Funcoes grandes, responsabilidades misturadas, acoplamento excessivo ou duplicacao relevante.
- Tipagem ausente, imprecisa ou incoerente com o contrato.
- Dependencias globais quando o projeto espera injecao por construtor ou parametro.
- Comentarios/docstrings divergentes do comportamento.
- Reexports/facades temporarios sem consumidor real ou sem prazo de remocao.
- Serializers, views ou controllers assumindo detalhes de outro dominio sem fronteira clara.
- Arquivos que misturam classes com funcoes/metodos soltos, exceto arquivos de testes. Quando encontrar isso, apontar como achado se a regra do projeto existir ou se a mistura prejudicar arquitetura/manutencao; sugerir mover para metodo privado da classe, service/controller dedicado ou modulo utilitario focado.

## Severidade

Classificar achados assim:

- Critica: seguranca, vazamento de dados, perda/corrupcao de dados, indisponibilidade provavel ou regressao grave em fluxo central.
- Alta: bug funcional importante, quebra de tenant/autorizacao, contrato de API que quebra cliente, escrita inconsistente ou risco serio de producao.
- Media: comportamento incorreto em cenario comum, teste critico ausente, performance ruim plausivel, OpenAPI incompleto que prejudica integracao.
- Baixa: convencao importante, lacuna de teste menor, manutencao ou clareza com baixo risco imediato.

Nao elevar severidade por gosto pessoal. Explicar o cenario que reproduz ou evidencia o risco.

## Formato Da Resposta

Responder em portugues com esta estrutura quando o usuario pedir uma revisao completa:

### Resumo executivo

Poucas frases dizendo se o PR parece seguro e quais riscos relevantes existem.

### Achados críticos

Listar apenas problemas reais. Para cada achado:

#### [Severidade: Crítica/Alta/Média/Baixa] Título

- **Arquivo/trecho:** caminho e funcao/metodo/linha quando possivel.
- **Problema:** o que esta errado.
- **Impacto:** consequencia pratica.
- **Cenario de risco:** exemplo que reproduz ou evidencia.
- **Sugestao de correcao:** acao objetiva.

Se nao houver achados relevantes, dizer explicitamente.

### Testes faltantes

Listar cenario, comportamento esperado e tipo sugerido: unitario, integracao, contrato/API, performance ou regressao.

### OpenAPI e contrato de API

Avaliar completude, divergencias, status codes, schemas, validacoes, permissoes, paginacao e exemplos.

### Segurança e autorização

Avaliar autenticacao, permissao, escopo por tenant/organizacao, acesso cruzado e exposicao indevida.

### Banco, transações e performance

Avaliar atomicidade, rollback, N+1, paginacao, filtros, consultas caras e updates/deletes sem escopo.

### Regressões possíveis

Listar comportamentos existentes que podem ter sido alterados sem intencao.

### Itens sem problema encontrado

Listar brevemente topicos revisados sem problemas relevantes.

### Veredito

Escolher exatamente um:

- **Aprovável:** sem problemas relevantes.
- **Aprovável com ajustes menores:** melhorias de baixo risco.
- **Requer ajustes antes de aprovar:** riscos medios/altos.
- **Bloquear aprovação:** risco critico, seguranca, perda de dados ou regressao seria.

## Regras De Qualidade

- Comecar pelos achados quando o usuario pedir "review" e nao exigir outro formato.
- Nao inventar problema. Se nao houver evidencia, marcar como ponto de atencao.
- Preferir referencias de arquivo clicaveis e linhas exatas.
- Distinguir bug real de melhoria.
- Nao omitir teste ou contrato quando o PR altera API.
- Ao revisar novamente apos ajustes, revalidar o estado atual e nao assumir que achados anteriores ainda existem.
