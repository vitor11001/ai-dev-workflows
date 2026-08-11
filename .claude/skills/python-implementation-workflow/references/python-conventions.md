# Convenções Python

Detalhe das regras resumidas na Fase 3 do `SKILL.md`. Consulte quando a task tocar
um destes assuntos; o essencial já está inline na skill.

## Imports

- Todos no topo do arquivo, após o docstring de módulo quando houver.
- Nunca dentro de função, método ou classe, salvo ciclo de importação real e
  confirmado. Antes de usar import inline, mova o import para o topo e verifique se
  o ciclo existe de fato; se existir, deixe um comentário curto explicando qual é.
- Ao importar de biblioteca cujo nome colide com um conceito do framework, use
  alias que deixe a origem óbvia — `from pydantic import BaseModel as PydanticBaseModel`,
  `from pydantic import ValidationError as PydanticValidationError`.

## Estrutura de arquivos e classes

- Em arquivo que contém classe, não crie variável global: constante usada por uma
  única classe vira atributo privado de classe (`_FORBIDDEN = frozenset(...)`).
  Variável de módulo só em arquivo puramente funcional, ou para constante pública
  consumida por vários módulos.
- No máximo uma classe por arquivo, salvo arquivos que definem apenas tipos
  (`TypedDict`, `dataclass` de dados, `Enum`, modelos Pydantic de entrada/saída).
- Em arquivo que contém classe, não deixe função solta fora dela; mova para método,
  método privado ou módulo utilitário.

## Docstrings e comentários

- Docstring em classes, funções e métodos públicos, complexos ou de domínio que
  você criar ou alterar.
- A docstring explica intenção, contrato, entradas, saídas, efeitos colaterais e
  exceções relevantes — não repete linha a linha o que o código faz.
- Em métodos simples, privados ou autoexplicativos, siga o padrão local e evite
  documentação redundante.
- Escreva o porquê, não o óbvio. Referencie issue ou SHA quando uma linha existir
  por causa de bug ou restrição externa.
- Mantenha os comentários existentes; não os remova em refactor.
- Se o projeto tiver padrão de documentação diferente de docstring, siga o local.

## Idiomas modernos

Prefira a forma da esquerda quando a versão do projeto permitir:

| Prefira | Em vez de |
|---|---|
| `pathlib.Path` | `os.path` |
| f-string | `%` ou `.format()` |
| `dataclass` (com `slots=True` quando couber) ou `TypedDict` | dicionário solto com chaves mágicas |
| `Enum` / `StrEnum` | string literal repetida pelo código |
| `match` para despacho por forma | cadeia longa de `elif` |
| compreensão para transformar | laço que só monta lista |
| laço explícito para efeito colateral | compreensão usada pelo efeito |

Não troque código existente por essas formas sem necessidade da task: são
preferências para código novo, não licença para refatoração ampla.

## Dependências

- Antes de adicionar biblioteca, verifique se o projeto já tem algo equivalente.
- Adicione pelo gerenciador do projeto (poetry, uv, pip-tools). **Nunca edite o
  lockfile à mão.**
- Não atualize lockfile sem necessidade real da task — a atualização infla o diff
  e mistura risco de terceiros com o risco da sua mudança.
- Injete dependência por construtor ou parâmetro, não por global ou import direto,
  quando isso facilitar o teste.
- Encapsule biblioteca de terceiro atrás de uma interface fina do projeto quando
  ela atravessar muitas camadas.
- Em refactor de migração, remova facade e reexport temporário quando todos os
  imports já apontarem para o destino final. Antes de manter um reexport, confirme
  com `rg` que há consumidor real, ou documente o prazo de remoção.
