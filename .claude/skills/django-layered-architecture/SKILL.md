---
name: django-layered-architecture
description: estrutura projetos e apps Django/DRF em camadas (models, controllers, views, serializers) e decide em qual camada cada trecho de código deve morar. use quando o usuário pedir para criar projeto novo, adicionar app ou domínio, estruturar pastas, organizar código em camadas, separar responsabilidades, ou perguntar onde uma regra de negócio, query, validação, integração ou task deve ficar.
---

# Arquitetura em Camadas (Django/DRF)

## Objetivo

Garantir que todo projeto Django/DRF nasça e evolua com o mesmo corte arquitetural:
apps por domínio, camadas explícitas dentro de cada app e fronteiras que não se
dissolvem com o tempo.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "crie um projeto novo"
- "adicione um app de X"
- "estruture essas pastas"
- "onde eu coloco essa regra?"
- "isso deveria estar na view?"
- "separe as responsabilidades desse arquivo"

Use também, sem pedido explícito, ao criar arquivo novo em projeto que já segue
esta arquitetura.

## Princípio central

O corte primário é **por domínio**, não por camada. Não existe `models/` ou
`services/` na raiz do projeto: existe `src/<app>/` e as camadas vivem dentro dele.

```
src/<app>/
├── models/        dados: ORM, managers, querysets, validators de campo
├── controllers/   regra de negócio e orquestração — sem acesso a request
├── views/         interface DRF: ViewSet/APIView, HTTP, permissão
└── serializers/   validação e transformação de entrada e saída
```

Um app só ganha sub-camada (`services/`, `tasks/`, `signals/`, `constants/`,
`externals/`, `helpers/`, `utils/`, `admin/`) quando a complexidade justifica.
Não crie pasta vazia antecipando necessidade.

## Onde isso mora?

Consulte esta tabela antes de criar ou mover código.

| O que está sendo escrito | Mora em | Nunca em |
|---|---|---|
| Leitura de `request`, header, query param | `views/` | controller, service, task |
| Autenticação e permissão de endpoint | `views/` | controller |
| Validação de formato, tipo e obrigatoriedade | `serializers/` | view, controller |
| Regra de negócio e orquestração de passos | `controllers/` | view, serializer, model |
| Revalidação defensiva dos argumentos recebidos | `controllers/` | — |
| Query com join, agregação ou filtro reaproveitável | `models/managers.py`, `models/queries.py` | view, controller |
| Campo, constraint, índice, `Meta` | `models/` | — |
| Constante de domínio, enum, slug | `constants/` | solto no módulo |
| Chamada a API externa, e-mail, SMS, storage | `externals/` do app dono | controller, `shared/` |
| Agendamento, retry e backoff de job | `tasks/` | controller |
| Regra executada pelo job | `controllers/` — a task só chama | `tasks/` |
| Base abstrata, exceção genérica, decorator, observabilidade | `shared/` | app de domínio |
| Qualquer código que cite entidade de negócio | app de domínio | `shared/` |

## Fronteiras invioláveis

Três regras que sustentam o resto. Violar qualquer uma corrói a arquitetura inteira.

**1. Só a view toca `request`.**
Controller, service e task não recebem nem acessam `request`. Passe os dados já
extraídos como argumentos nomeados. O motivo é concreto: o mesmo controller é
chamado por task, signal, management command e teste — contextos onde `request`
não existe.

**2. O controller revalida.**
Não confie na validação do serializer. Nem todo caminho até o controller passa por
um: tasks, signals, commands e outros controllers chamam direto. Valide os
argumentos de que a regra depende, e levante exceção com o valor inválido e o
formato esperado.

**3. `shared/` não tem domínio.**
`shared/` guarda o transversal: bases de model, exceções, decorators,
observabilidade, contratos de integração. Se o código cita usuário, pedido,
alerta ou qualquer entidade de negócio, ele pertence ao app dono daquele domínio.

O teste prático da regra 3: um canal de notificação por e-mail genérico pode viver
em `shared/externals/email/`, mas o envio de *notificação de alerta* pertence ao
app `alerts`. A infraestrutura é compartilhada; a regra que a usa, não.

## Modos de uso

### Projeto novo
1. Crie a raiz com `src/`, `config/` (settings modulares por área) e `api/`
   (hub de roteamento versionado).
2. Crie `shared/` com as bases que o projeto realmente já precisa.
3. Crie um app por domínio identificado, cada um com o esqueleto mínimo.
4. Consulte `references/project-structure.md` para a árvore canônica.

### App ou domínio novo
1. Confirme que é domínio próprio, e não sub-conceito de app existente.
2. Crie apenas o esqueleto mínimo: `models/`, `controllers/`, `views/`,
   `serializers/`, `tests/`, `urls.py`, `apps.py`.
3. Registre a rota no hub de roteamento (`api/v1/urls.py`).
4. Adicione sub-camadas só quando o primeiro caso real aparecer.

### Código novo em projeto existente
1. Leia as instruções locais (`AGENTS.md`, `CLAUDE.md`, `docs/`) antes de decidir.
2. Se o projeto já segue outra arquitetura, **preserve a dele** e informe a
   divergência ao usuário. Não imponha esta estrutura sobre padrão local existente.
3. Se seguir esta arquitetura, use a tabela "Onde isso mora?" para posicionar.

## Testes

Os testes moram dentro do app, espelhando as camadas que exercitam. Como nas
sub-camadas de código, o núcleo existe sempre e o resto surge quando o app precisa:

```
src/<app>/tests/
├── factories/          sempre — factories dos models do app
├── unit_tests/         sempre — model, manager, queryset, validator, serializer
├── api_tests/          se o app expõe endpoint
│
├── controller_tests/   se há controller com regra de negócio
├── tasks_tests/        se há Celery
├── admin_tests/        se há customização de admin
├── integration_tests/  se há fluxo entre módulos
└── e2e_tests/          se há fluxo ponta a ponta
```

Um teste que faz request por `APIClient` é `api_tests`. Um teste que chama o
controller direto é `controller_tests`. Na dúvida entre dois níveis, prefira o
mais baixo: é mais rápido e menos frágil.

Para escrever os testes em si, use a skill `django-tests`.

## Documentação

Projetos que seguem esta arquitetura mantêm a documentação em camadas, cada uma
respondendo a uma pergunta diferente:

```
docs/
├── architecture/     como o sistema está estruturado hoje, e por quê
├── decisions/        a decisão datada que originou cada escolha
├── invariants/       o que precisa ser verdade sempre
├── system-overview/  fluxos ponta a ponta entre as partes
└── glossary/         vocabulário do domínio
```

`architecture/` descreve o estado atual e é documento vivo. `decisions/` é
append-only e registra o contexto e as alternativas de cada escolha — não reescreva
uma decisão passada, adicione a nova que a substitui.

Ao criar app novo ou mudar fronteira entre apps, atualize `architecture/`.

## Interface de comandos

O projeto expõe **um** ponto de entrada para as tarefas de desenvolvimento —
Makefile, justfile, tox ou scripts do `pyproject.toml` — e todo mundo usa ele em
vez de comandos soltos. O comando fica igual na máquina de cada pessoa, no CI e na
documentação; quando muda, muda num lugar só.

| Alvo | Faz |
|---|---|
| `bootstrap` | prepara o ambiente do zero: runtime, dependências, hooks |
| `up` / `down` | sobe e derruba a infra local (banco, fila, cache) |
| `fmt` / `lint` | qualidade rápida durante o desenvolvimento |
| `test` | roda a suíte, com escopo parametrizável |
| `ci` | tudo que o CI roda, na mesma ordem |

- **`ci` local espelha o pipeline remoto.** Verde local e vermelho no CI é defeito
  da interface, não do teste — e custa muito mais caro descobrir depois do push.
- `test` aceita escopo por parâmetro. Ninguém deve precisar decorar a invocação do
  `pytest` para rodar um arquivo.
- Ao adicionar etapa de qualidade nova, inclua no `ci` também: fora dele, ela não roda.
- Documente os alvos com um `help`.

## Regras obrigatórias

- Preserve a arquitetura existente do projeto acima desta referência.
- Não crie sub-camada, pasta ou abstração antes do primeiro caso real de uso.
- Não mova código entre camadas sem o usuário pedir; aponte a violação e pergunte.
- Mantenha o app dono do domínio como único lugar da regra daquele domínio.
- Registre em `docs/architecture/` toda mudança de fronteira entre apps.
- Ao criar app novo, crie também o pacote de testes espelhando as camadas.

## Critérios de revisão

Antes de entregar, confirme:
1. Nenhum controller, service ou task recebe ou acessa `request`.
2. O controller valida os argumentos de que sua regra depende.
3. Nenhum código em `shared/` cita entidade de negócio.
4. Queries reaproveitáveis estão em manager ou queryset, não na view.
5. As tasks apenas orquestram; a regra está no controller.
6. Nenhuma pasta vazia foi criada "para depois".
