---
name: plane-issue
description: redige a issue de uma demanda para o Plane (o quê e por quê), em português brasileiro, a partir da investigação da task, e publica ou atualiza no Plane quando o usuário confirmar. use quando o usuário pedir para criar, escrever, montar, revisar, publicar ou atualizar uma issue a partir de bug, hotfix, feature, melhoria ou débito técnico. se a task ainda não foi investigada, roda a investigate antes. não investiga por conta própria nem planeja a implementação; para planejar, use implementation-plan.
---

# Issue para o Plane

## Objetivo

Transformar a investigação de uma task em uma issue clara para quem prioriza e valida: problema, impacto, recorte e critério de pronto, em linguagem de domínio, sem caminho de implementação. Publicar no Plane só quando o usuário confirmar.

Antes de escrever a versão final, ler [references/issue-pattern.md](references/issue-pattern.md). Para exemplo de tom e estrutura, ler [references/plane-test.md](references/plane-test.md).

## Fluxo

1. Localizar a pasta da task (ver "Pasta da task"). Se não houver `*-investigacao.md`, rodar a skill `investigate` antes. Se houver, conferir a defasagem conforme "Investigação desatualizada" da `investigate`.
2. Ler a investigação e separar o que está confirmado, o que é hipótese e o que muda o escopo.
3. Fazer perguntas curtas só quando a resposta mudar escopo, aceite ou trade-off; no máximo 10. Não perguntar o que a investigação já responde. Exemplos:
   - qual parte do fluxo entra agora e qual vira desdobramento;
   - se a prioridade é corrigir comportamento, destravar operação ou preparar base para mudança futura;
   - se há restrição de permissão, compatibilidade, auditoria ou rollout.
   Sem bloqueio real, explicitar a premissa e seguir pelo caminho mais simples e de menor risco.
4. Reduzir ao menor slice útil e escrever uma issue principal, sugerindo desdobramentos fora do corpo (cada um vira uma task própria) quando houver:
   - backend e frontend grandes sem dependência imediata;
   - correção funcional misturada com refactor;
   - CRUD operacional misturado com histórico somente leitura;
   - múltiplos bounded contexts na mesma demanda;
   - regras de permissão ou auditoria que pedem validação separada.
5. Redigir título e corpo (ver "Estrutura da issue") em português brasileiro, com linguagem natural, direta e específica do domínio. Revisar para remover tom genérico, solução inflada, lista artificial, jargão vazio e detalhe de implementação frágil, e conferir contra "Não fazer".
6. Gravar o corpo em `N-issue-original.md` e mostrar título e corpo completos ao usuário.
7. Perguntar: **"Publico no Plane?"**. Seguir "Publicação" conforme a resposta.
8. Registrar no sumário o que foi feito e atualizar o cabeçalho (Status `issue redigida` ou `publicada`; Plane `não publicado` ou `publicado (<link>)`).

## Pasta da task

- A task mora em `tmp/tasks/<ID>/`; as regras completas (identificador, `LOCAL-<slug>`, arquivos, pasta antiga) estão na skill `investigate`.
- Encontre os arquivos pelo nome (`*-investigacao.md`, `*-issue-original.md`, `*-plano-implementacao.md`), nunca pelo número; ao criar arquivo, continue a numeração.
- Ao rodar, registre uma linha no `0-sumario.md` com a data de `date '+%Y-%m-%d %H:%M %Z'`: `| <data> | <skill> | <o que fez> | <arquivo> |`. Atualize o cabeçalho quando Status ou Plane mudarem.
- Pasta antiga em `tmp/plans/<ID>/`: siga "Pasta antiga em `tmp/plans/`" da skill `investigate`.

## Estrutura da issue

O título vai no campo próprio do Plane: até ~80 caracteres, começando pelo resultado esperado ou pelo problema, em linguagem de domínio. O corpo não tem título e começa em `## Contexto`:

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

Por seção:

- `Contexto`: estado atual, problema ou gap, impacto e recorte, sem antecipar implementação.
  - `bug` e `hotfix`: comportamento atual, comportamento esperado e como reproduzir, em linguagem de uso. `hotfix` também diz a urgência e a mitigação, se houver.
  - `feature` e `melhoria`: o problema do usuário ou da operação que a mudança resolve, e o que fica fora do recorte.
  - `débito`: o risco concreto de manter como está e o que a mudança destrava.
- `Abordagem sugerida`: opcional, 2 ou 3 frases em linguagem de arquitetura ou domínio, com entrypoints como "fluxo de aprovação" ou "rotina de sincronização". Sem arquivos, funções ou passos de código.
- `Definição`: 1 a 4 cenários em estilo Gherkin, com bullets `**Dado**`, `**Quando**`, `**Então**` e `**E**`, no vocabulário do usuário ou operador.
- `Definition of done`: 4 a 6 checkboxes com resultados verificáveis por uso do sistema, teste ou inspeção funcional. Não é lista de tarefas técnicas.

A investigação tem `arquivo:linha`; a issue não. Traduza cada achado para o comportamento que ele produz.

### Formatação

- H2 apenas nas seções fixas; sem H1, sem bloco de código Gherkin, sem seções extras sem necessidade.
- Bullets para estados, impactos, restrições e passos Gherkin; checkboxes obrigatórios no `Definition of done`.
- Negrito para palavras-chave Gherkin, o rótulo `**Cenário:**` e termos centrais do domínio.
- Inline code só para campos, status, endpoints, valores exatos e identificadores técnicos.
- Blockquote ou tabela só quando melhorar claramente a leitura.

## Publicação

Sempre perguntar antes de publicar: muita correção não vai para o Plane.

**Não publicar:** manter o texto em `N-issue-original.md`, registrar `issue redigida, não publicada` no sumário e deixar Plane como `não publicado`. A task continua `LOCAL-<slug>`.

**Publicar:** usar o script desta skill, resolvendo o caminho a partir do diretório deste `SKILL.md`:

```bash
python3 -I scripts/plane.py check                      # valida a configuração e lista os projetos
python3 -I scripts/plane.py publish <pasta>/N-issue-original.md --project <IDENT> --name "<título>"
python3 -I scripts/plane.py update <ID> <pasta>/N-issue-original.md [--name "<título>"]
python3 -I scripts/plane.py get <ID>
```

1. Perguntar o projeto (identificador, ex.: `PROJ`) quando não for conhecido pelo sumário ou pelo usuário; `check` lista os disponíveis.
2. Rodar `publish`. O script converte o Markdown para o HTML do editor do Plane (checklist vira `taskList`), cria a issue, relê o que foi gravado e confere os checkboxes.
3. Com a saída `Publicada: PROJ-123`, renomear a pasta de `LOCAL-<slug>` para `PROJ-123`, registrar `Identificador anterior` no cabeçalho e a linha `publicada como PROJ-123 (<link>)` no sumário.
4. Se a saída disser `Checklist: não conferido`, informar ao usuário que a issue foi criada, mas os checkboxes não puderam ser conferidos pela API. Nunca afirmar sucesso que o script não confirmou.
5. Em erro (configuração ausente, HTTP 401, limite de 60 requisições/minuto), mostrar a mensagem do script e manter a issue só na pasta.

Para alterar uma issue já publicada, editar `N-issue-original.md` e rodar `update`; registrar `issue atualizada no Plane` no sumário.

### Configuração do Plane

O script lê `~/.config/ai-dev-workflows/plane.env`, criado pelo usuário uma única vez:

```bash
PLANE_WORKSPACE=<slug-do-workspace>
PLANE_API_TOKEN_FILE=<caminho do arquivo com o token>
```

Se a configuração não existir, mostrar este modelo e pedir ao usuário para criar o arquivo com `chmod 600`. Nunca pedir o token no chat, nunca ler ou imprimir o conteúdo do arquivo do token e nunca passar o token em argumento de comando.

## Entrega

| Item | Detalhe |
|---|---|
| Título | `<título>` |
| Arquivo | `tmp/tasks/<ID>/N-issue-original.md` |
| Plane | `publicado como PROJ-123 (<link>)`, `não publicado` ou o erro do script |
| Checklist | conferido pelo script, ou o motivo de não ter sido |
| Desdobramentos | tasks sugeridas fora do recorte, uma por linha |

Antes da tabela, mostrar título e corpo completos da issue. Depois, recomendar o próximo passo (normalmente `implementation-plan`).

## Não fazer

- Não investigar por conta própria: sem investigação, rode a `investigate`.
- Não publicar sem confirmação do usuário.
- Não incluir título no corpo, nem arquivos, funções ou linhas de código.
- Não escrever Gherkin com nomes de método, variável ou campo interno quando linguagem de domínio resolver.
- Não usar o `Definition of done` como checklist de implementação.
- Não misturar descoberta, solução detalhada e plano de código no mesmo texto.
- Não aumentar escopo quando uma issue menor resolve o problema.
