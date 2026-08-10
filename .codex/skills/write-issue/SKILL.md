---
name: write-issue
description: Investiga uma descrição livre de problema, lê a codebase e redige uma issue para Plane em português brasileiro. Use quando o usuário pedir para criar, escrever, montar, revisar ou salvar uma issue a partir de bug, gap de produto, dívida técnica, ajuste operacional, pedido amplo ou problema ainda mal definido; inclui escopo mínimo, perguntas de esclarecimento, definição em estilo Gherkin e Definition of done.
---

# Write Issue

Skill para investigar um problema antes de redigir uma issue no padrão do Plane. A saída deve ser uma issue em Markdown, ancorada no estado atual do código, nos termos do domínio e no menor slice útil.

Antes de escrever a versão final, ler [references/issue-pattern.md](references/issue-pattern.md). Se precisar de exemplo de tom e estrutura, ler [references/plane-test.md](references/plane-test.md).

## Fluxo

1. Ler a descrição livre do problema e separar o que está claro, o que é hipótese e o que muda o escopo.
2. Investigar a codebase antes de propor a issue. Procurar código, testes, docs, rotas, componentes, modelos, jobs, scripts e naming do domínio nos diretórios relevantes do projeto.
3. Fazer perguntas curtas somente quando a resposta mudar escopo, aceite ou trade-off. Limitar a no máximo 10 perguntas objetivas.
4. Quando não houver bloqueio real, explicitar premissas e seguir com o caminho mais simples e de menor risco.
5. Reduzir o problema ao menor slice útil. Se a demanda misturar fluxos, camadas, permissões, cadastros, modelos ou refactors diferentes, escrever uma issue principal e sugerir desdobramentos fora do corpo da issue.
6. Redigir em português brasileiro, com linguagem natural, direta e específica do domínio.
7. Revisar a issue para remover tom genérico, solução inflada, lista artificial, jargão vazio e detalhes de implementação frágeis.
8. Entregar no formato pedido pelo usuário. Se o usuário pedir para salvar, usar `/tmp/NNN-slug-da-issue.md` por padrão.

## Investigação

Não escrever issue só com base na descrição inicial. Confirmar no código:

- onde o comportamento atual vive;
- quais modelos, endpoints, páginas, jobs, serviços ou comandos são afetados;
- quais restrições e permissões já existem;
- se já há testes cobrindo parte do fluxo;
- se o problema já foi parcialmente resolvido em outro lugar.

Preferir `rg` para localizar classes, funções, models, rotas, componentes e testes. Ler os arquivos mais relevantes em vez de fazer varredura ampla sem direção.

O corpo final da issue deve descrever problema e comportamento esperado, não o caminho de implementação. Não listar arquivos, funções ou linhas de código no corpo da issue. Quando for útil orientar o implementador, usar entrypoints em linguagem de domínio, como "fluxo de aprovação", "módulo de pedidos" ou "rotina de sincronização".

## Perguntas E Escopo

Fazer perguntas quando a resposta alterar a fronteira da issue, por exemplo:

- qual parte do fluxo precisa entrar agora e qual pode virar desdobramento;
- se a prioridade é corrigir comportamento, destravar operação ou preparar base para mudança futura;
- se existe restrição de permissão, compatibilidade, auditoria ou rollout.

Assumir uma premissa quando a dúvida não muda o essencial. Evitar perguntas que podem ser respondidas pelo código ou que transferem uma decisão técnica pequena para o usuário.

Sugerir desdobramentos quando houver:

- backend e frontend grandes sem dependência imediata;
- correção funcional misturada com refactor;
- CRUD operacional misturado com histórico somente leitura;
- múltiplos bounded contexts na mesma demanda;
- regras de permissão ou auditoria que pedem validação separada.

## Estrutura Da Issue

Não incluir título no corpo da issue. O título pertence ao campo próprio do Plane. O corpo começa em `## Contexto`.

Usar este esqueleto:

```md
## Contexto
...

## Abordagem sugerida *(opcional)*
...

## Definição

**Cenário:** descrição do cenário em linguagem natural.

- **Dado** ...
- **Quando** ...
- **Então** ...

## Definition of done
- [ ] ...
- [ ] ...
```

Regras por seção:

- `Contexto`: explicar estado atual, problema ou gap, impacto e recorte. Não antecipar implementação.
- `Abordagem sugerida`: opcional, com 2 ou 3 frases em linguagem de arquitetura ou domínio. Mencionar entrypoints sem prescrever arquivos, funções ou passos de código.
- `Definição`: escrever cenários em estilo Gherkin usando bullets com `**Dado**`, `**Quando**`, `**Então**` e `**E**`. Usar vocabulário do usuário ou operador, não nomes internos de código.
- `Definition of done`: usar checklist com resultados verificáveis e observáveis. Não transformar em lista de tarefas técnicas.

## Formatação Para Plane

Preferir texto flat, conciso e fácil de colar no Plane:

- usar H2 apenas nas seções fixas e em `Abordagem sugerida`, quando existir;
- usar bullets para estados, impactos, restrições e passos Gherkin;
- usar checkboxes obrigatoriamente no `Definition of done`;
- usar negrito para palavras-chave Gherkin, rótulo `**Cenário:**` e termos centrais do domínio;
- usar inline code apenas para campos, status, endpoints, valores exatos e identificadores técnicos;
- usar blockquote ou tabela só quando melhorar claramente a leitura.

Não usar H1, bloco de código Gherkin, colunas múltiplas, decoração excessiva ou seções extras sem necessidade.

### Publicação Pela API Do Plane

Quando publicar a issue pela API usando `description_html`, converter cada checkbox da `Definition of done` para a estrutura de task list esperada pelo editor do Plane:

```html
<ul data-type="taskList">
  <li data-type="taskItem" data-checked="false">
    <label contenteditable="false"><input type="checkbox"><span></span></label>
    <div><p>Resultado verificável</p></div>
  </li>
</ul>
```

Repetir o elemento `li` completo para cada resultado da checklist. Depois de publicar ou atualizar, reler o work item pela API e confirmar que todos os itens persistiram com `data-type="taskItem"` e `data-checked="false"` antes de informar sucesso.

## Entrega

Sempre exibir o corpo completo da issue em Markdown antes de qualquer ação adicional. Se houver desdobramentos, listar depois da issue em poucas linhas.

Quando o usuário pedir para salvar:

- salvar em `/tmp/NNN-slug-da-issue.md`, salvo se ele indicar outro caminho;
- manter o arquivo sem H1, começando em `## Contexto`;
- confirmar o caminho gravado;
- resumir desdobramentos sugeridos fora do arquivo, se houver.

## Não Fazer

- Não escrever issue sem checar a codebase quando houver repositório disponível.
- Não incluir título no corpo da issue.
- Não incluir lista de arquivos, funções ou linhas no corpo final.
- Não escrever passos Gherkin com nomes de método, variável ou campo interno quando linguagem de domínio resolver.
- Não usar `Definition of done` como checklist de implementação.
- Não misturar descoberta, solução detalhada e plano de código no mesmo texto.
- Não aumentar escopo quando uma issue menor resolve o problema.
