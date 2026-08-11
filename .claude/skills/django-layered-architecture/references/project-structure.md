# Árvore canônica

Referência de estrutura para projeto novo e app novo. Crie apenas o que o projeto
já precisa — as pastas marcadas como opcionais nascem quando o primeiro caso real
aparece.

## Projeto novo

```
<repo>/
├── src/
│   ├── config/                 projeto Django — sem entidades
│   │   ├── settings/           settings modulares por área
│   │   │   ├── base.py
│   │   │   ├── database.py
│   │   │   ├── auth.py
│   │   │   ├── api.py
│   │   │   ├── celery.py       (se houver assíncrono)
│   │   │   └── observability.py
│   │   ├── celery.py           (se houver assíncrono)
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   │
│   ├── api/                    hub de roteamento — sem entidades
│   │   ├── v1/urls.py          agrega as urls de todos os apps
│   │   ├── pagination.py
│   │   ├── permissions.py
│   │   └── filters.py
│   │
│   ├── shared/                 transversal — sem domínio
│   │   ├── models/             bases abstratas (timestamps, soft delete)
│   │   ├── exceptions/         hierarquia de exceção do projeto
│   │   ├── api/                exception handler, autenticação, doc
│   │   ├── decorators/
│   │   ├── constants/
│   │   ├── observability/      (opcional) logging, métricas, tracing
│   │   └── externals/          (opcional) integrações genéricas
│   │
│   └── <app>/                  um por domínio — ver abaixo
│
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── invariants/
│   ├── system-overview/
│   └── glossary/
│
├── AGENTS.md                   contrato de camadas e convenções do projeto
├── Makefile                    ponto único de comando: bootstrap, up, fmt, lint, test, ci
└── pyproject.toml
```

`config/` e `api/` não têm entidades: são infraestrutura de projeto e de API.
Settings modulares por área evitam o arquivo único de 800 linhas e deixam claro
onde cada configuração mora.

## App novo — esqueleto mínimo

Comece exatamente com isto:

```
src/<app>/
├── models/
│   └── __init__.py
├── controllers/
│   └── __init__.py
├── views/
│   └── __init__.py
├── serializers/
│   └── __init__.py
├── tests/
│   ├── api_tests/
│   ├── controller_tests/
│   └── unit_tests/
├── migrations/
├── apps.py
├── urls.py
└── __init__.py
```

Registre a rota em `src/api/v1/urls.py`:

```python
path("<app>", include("<app>.urls")),
```

## App maduro — sub-camadas

Adicione conforme a necessidade real surgir:

```
src/<app>/
├── models/
│   └── <entidade>/
│       ├── models.py           o model
│       ├── managers.py         manager e queryset
│       ├── queries.py          queries complexas nomeadas
│       └── validators.py       validators de campo
├── controllers/
│   └── <fluxo>.py              um arquivo por fluxo de negócio
├── views/
│   └── <recurso>/              um pacote por recurso quando crescer
├── serializers/
├── constants/                  enums, slugs, mensagens de erro
├── tasks/                      Celery — finas, delegam ao controller
├── services/                   colaborador reutilizável por controllers
├── externals/                  integração externa deste domínio
├── signals/                    handlers de sinal do Django
├── exceptions/                 exceções específicas do domínio
├── management/commands/
└── admin/
```

### Quando cada sub-camada se justifica

| Sub-camada | Crie quando |
|---|---|
| `constants/` | um enum ou conjunto de slugs é usado em mais de um arquivo |
| `tasks/` | há trabalho assíncrono ou agendado |
| `services/` | um colaborador é usado por dois ou mais controllers |
| `externals/` | o app fala com uma API, storage ou canal externo |
| `signals/` | há efeito colateral acoplado ao ciclo de vida de um model |
| `exceptions/` | o domínio tem erro próprio que o chamador precisa distinguir |

`services/` é minoritário nesta arquitetura: o **controller é a camada de serviço**.
Só extraia um service quando o mesmo colaborador for reusado por controllers
diferentes.

## Divisão de arquivos

Quando um arquivo de camada passa de ~500 linhas, quebre por responsabilidade e
transforme-o em pacote:

```
views/alert_settings.py
```
vira
```
views/alert_settings/
├── __init__.py                 reexporta as views públicas
├── list_create_view.py
├── retrieve_put_delete_view.py
└── deactivate_view.py
```

O `__init__.py` mantém o ponto de import estável, então nenhum chamador quebra.
