---
name: task-planner
description: Planejamento técnico de tasks, issues, PRs e branches em Markdown. Use quando o usuário quiser transformar uma task/revisão/conversa em plano de implementação, dividir trabalho em PRs, atualizar escopo após review, criar checklist para outra LLM implementar, registrar decisões e perguntas pendentes, ou salvar/atualizar arquivos .md de planejamento.
---

# Task Planner

## Objetivo

Planejar tasks técnicas de forma implementável, mantendo escopo, decisões, perguntas, arquivos prováveis, testes e critérios de pronto em Markdown. Priorizar clareza para humanos e para outra LLM executar depois.

## Fluxo principal

1. Entender a fonte da demanda: task, issue, review, branch atual, PR futuro, conversa ou arquivo existente.
2. Investigar o repositório quando o plano depender do código atual. Usar `rg`, `git diff`, `git status`, `sed` e testes existentes para ancorar decisões.
3. Separar claramente:
   - ajustes da branch/PR atual;
   - próximos PRs/branches;
   - fora de escopo.
4. Criar ou atualizar um `.md` em `tmp/` por padrão, salvo se o usuário indicar outro caminho.
5. Registrar decisões tomadas e perguntas pendentes. Quando o usuário responder, atualizar o arquivo e reduzir a lista de pendências.
6. Quando houver dúvida, propor uma recomendação técnica antes de perguntar. Explicar o motivo em linguagem humana.
7. Encerrar quando o documento tiver decisões suficientes para implementação sem adivinhação perigosa.

## Estilo do documento

Usar seções úteis e diretas. Preferir esta estrutura, adaptando ao caso:

```md
## Objetivo
## Base / Premissas
## Fora de escopo
## Decisões já fechadas
## Contrato final
## Fluxos esperados
## Desenho de implementação recomendado
## Arquivos prováveis a alterar
## Testes necessários
## Ordem de implementação sugerida
## Cuidados importantes
## Comandos de verificação
## Critérios de pronto
## Perguntas pendentes
```

Para documentos de branch atual, detalhar mais:

- o que deve ser removido;
- o que deve ser reaproveitado;
- quais endpoints/contratos ficam intactos;
- quais nomes/vocabulários devem mudar;
- quais testes apagar, renomear, criar ou adaptar.

Para documentos de PR futuro, detalhar mais:

- dependência/rebase sobre PR anterior;
- contrato final esperado;
- payloads de entrada;
- respostas esperadas;
- camada de view, serializer, controller/serviço;
- validações e transações;
- rollback;
- auditoria;
- testes por camada.

## Perguntas progressivas

Não despejar todas as perguntas se o usuário quiser responder aos poucos. Trabalhar por blocos:

1. Escopo e fora de escopo.
2. Endpoints/contratos.
3. Payload e resposta.
4. Validações de domínio.
5. Transação, persistência e rollback.
6. Auditoria/observabilidade.
7. Testes e rollout.
8. OpenAPI/docs/schema.

Para cada bloco:

- fazer perguntas numeradas;
- incluir uma recomendação quando for possível inferir;
- depois de cada resposta, atualizar o `.md` e marcar a decisão como fechada;
- manter perguntas pendentes somente quando a decisão ainda afeta implementação.

Exemplo de pergunta boa:

```md
12. O campo `deactivated` deve existir no payload de criação?

Recomendação: não aceitar `deactivated`; configurações nascem ativas e desativar é uma ação separada já existente.
```

## Registro de decisões

Quando uma decisão for tomada, atualizar o documento em linguagem afirmativa:

```md
12. Decidido: não aceitar `deactivated`; configurações nascem ativas.
```

Evitar deixar texto antigo contradizendo a decisão. Remover ou reescrever recomendações que viraram decisões.

Quando houver uma decisão que o usuário levará a supervisor, registrar como ponto de validação:

```md
## Ponto para validação com supervisor

- Contexto da dúvida.
- Interpretação recomendada.
- Impacto se a decisão mudar.
- Pergunta objetiva de produto/arquitetura.
```

## Investigação no código

Quando existir repo disponível, investigar antes de planejar detalhes implementáveis:

- `git status --short --branch` para entender branch e sujeira local;
- `git diff --stat` e `git diff --name-status` para PR em andamento;
- `rg` por nomes de models, serializers, views, rotas e testes;
- ler arquivos relevantes com `sed`;
- evitar editar código quando o pedido é apenas planejamento.

Não assumir que endpoint, serializer ou teste existe sem procurar. Se a pergunta for conceitual, pode responder sem varredura ampla, mas planos de implementação devem ser ancorados no código.

## Regras de escopo

- Se o usuário pede documento só da branch atual, não misturar próximos PRs no mesmo arquivo.
- Se o usuário pede próximos PRs, criar documento próprio para cada PR quando o escopo for grande.
- Se uma review pede remover algo, registrar explicitamente arquivos/rotas/testes a remover.
- Se o schema/OpenAPI for gerado automaticamente no projeto, documentar que não deve ser editado manualmente.
- Se endpoints existentes são usados pelo frontend, priorizar compatibilidade; se quebrar contrato for necessário, explicar o motivo em linguagem humana.

## Saída padrão

Ao criar ou atualizar arquivo:

- informar o caminho do `.md`;
- resumir decisões adicionadas;
- listar perguntas pendentes seguintes;
- não colar o documento inteiro salvo, a menos que o usuário peça.

## Nomes de arquivo

Usar nomes explícitos em `tmp/`, por exemplo:

- `tmp/implementacao-ajustes-branch-central-alertas.md`;
- `tmp/implementacao-pr2-criacao-transacional-alertas.md`;
- `tmp/plano-implementacao-central-alertas.md`.

Preferir prefixos como `implementacao-`, `plano-`, `checklist-` conforme a finalidade.
