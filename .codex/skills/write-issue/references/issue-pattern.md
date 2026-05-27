# Padrão Base Da Issue

Use este arquivo como guia portátil para redigir issues no Plane.

## Estrutura

O corpo da issue não deve conter título H1. Comece diretamente em:

- `## Contexto`
- `## Abordagem sugerida *(opcional)*`
- `## Definição`
- `## Definition of done`

## Contexto

Explique em linguagem de domínio:

- estado atual;
- problema ou gap;
- impacto operacional, de produto ou técnico;
- recorte escolhido para a issue atual;
- restrições relevantes de permissão, auditoria, compatibilidade ou rollout.

Evite antecipar implementação. O leitor deve entender o problema mesmo que a organização interna do código mude.

## Abordagem Sugerida

Se ajudar, inclua 2 ou 3 frases com a direção da solução. Use termos de arquitetura ou domínio e, quando necessário, entrypoints como "fluxo de checkout", "módulo de notificações" ou "rotina de conciliação".

Não indicar arquivo, função, assinatura ou passo de código específico no corpo final.

## Definição

Use cenários em estilo Gherkin com bullets, não bloco de código:

```md
**Cenário:** operador conclui a aprovação com dados válidos.

- **Dado** que existe uma solicitação aguardando aprovação
- **Quando** o operador confirma a aprovação
- **Então** a solicitação passa a constar como aprovada
- **E** o histórico registra a ação realizada
```

Escreva de 1 a 4 cenários na maior parte dos casos. Use vocabulário de usuário, operação e domínio. Evite nomes de função, classe, variável ou campo interno.

## Definition Of Done

Use checkboxes com comportamentos verificáveis:

```md
- [ ] Usuário vê a mensagem de erro esperada quando tenta concluir sem dados obrigatórios
- [ ] A ação autorizada é registrada no histórico
- [ ] Usuários sem permissão não conseguem executar a operação
```

Mantenha entre 4 e 6 itens quando possível. Cada item deve poder ser validado por uso do sistema, teste, inspeção funcional ou critério observável.

## Tom

- Português brasileiro.
- Direto, humano e operacional.
- Específico do domínio.
- Sem linguagem promocional.
- Sem abstrações vagas.
- Sem aparência de template genérico.

## Sinais De Escopo Grande Demais

Sugira desdobramentos quando encontrar:

- mudança comportamental e refactor estrutural no mesmo pacote;
- vários modelos sem ligação operacional direta;
- backend, frontend e migração de dados grandes demais para um único slice;
- múltiplas regras de permissão que podem ser validadas separadamente.

Quando isso acontecer, escreva a menor issue útil agora e liste as próximas fora do corpo final.
