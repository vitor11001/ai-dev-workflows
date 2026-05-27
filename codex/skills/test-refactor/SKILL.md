---
name: test-refactor
description: refatora, consolida e reorganiza testes python existentes para pytest, django e fastapi, usando os padrões de teste incorporados nesta skill. use quando o usuário pedir para limpar testes legados, converter unittest, consolidar arquivos, renomear testes ou alinhar a suíte ao padrão atual.
---

# Refatoração de Testes

## Objetivo

Melhorar testes existentes sem mudar o comportamento validado, alinhando a suíte ao padrão atual do repositório.

## Quando usar

Use esta skill quando o usuário pedir algo como:
- "refatore esses testes"
- "converta esses testes para pytest"
- "organize a suíte"
- "consolide os testes desse módulo"
- "limpe os testes legados"

## Saída esperada

Arquivos de teste reorganizados, renomeados ou consolidados, preservando cobertura útil e seguindo os padrões incorporados nesta skill.

## Procedimento

Quando esta skill for usada:
1. Leia os testes existentes, código de produção, fixtures e factories relacionadas.
2. Identifique duplicações, nomes genéricos, classes legadas e arquivos fora do espelhamento correto.
3. Preserve intenção e comportamento dos testes válidos.
4. Converta padrões legados para `pytest` funcional quando isso reduzir complexidade.
5. Consolide testes do mesmo módulo no arquivo que segue o espelhamento correto.
6. Remova sobras locais como `__pycache__`, arquivos temporários e diretórios vazios quando fizer parte do trabalho solicitado.
7. Pergunte antes de executar `pytest` ou validações demoradas, salvo pedido explícito do usuário.

## Princípios

- Comportamento > implementação: preserve testes que validam resultado observável.
- Menor escopo confiável: mantenha cada cenário no nível mais simples que prove o comportamento.
- Determinismo: remova dependência de horário real, rede externa e estado residual.
- Código, nomes, variáveis e arquivos devem estar em inglês.
- Docstrings e comentários devem estar em português brasileiro.
- Testes devem ter docstrings claras em português brasileiro.
- Uma responsabilidade por teste.

## Organização

Estruture os testes espelhando o diretório do app, como `src/`, `app/` ou a pasta raiz da aplicação:

- `tests/unit/`: funções puras, validações de domínio, serializers, utilitários e lógica sem I/O real.
- `tests/integration/`: persistência, requests HTTP locais, service + repository, cache, filas e integração entre módulos.
- `tests/e2e/`: fluxos completos do usuário atravessando múltiplas camadas.

Exemplo de espelhamento:

- Código: `app/billing/services/invoice_generator.py`
- Unit: `tests/unit/billing/services/test_invoice_generator.py`
- Integration: `tests/integration/billing/services/test_invoice_generator.py`

## Cobertura por alvo

Use esta lista como referência para preservar ou reorganizar cobertura existente. Não crie cenários artificiais sem relação com a refatoração, mas não remova cobertura útil desses comportamentos quando ela já existir.

### Views, controllers e endpoints

- Sucesso principal, status esperado, payload esperado e formato do contrato.
- Objeto inexistente, entrada inválida e mensagens de erro relevantes.
- Permissão, autenticação e autorização quando aplicáveis.
- Filtros, busca, paginação e ordenação quando fizerem parte do contrato.
- Criação, atualização, exclusão e idempotência quando forem comportamentos existentes.
- Efeitos colaterais observáveis, como eventos, services internos, jobs ou cache.
- Erros de domínio traduzidos para resposta correta.
- Serialização de campos calculados, datas, enums e relacionamentos.
- Escopo de usuário ou multi-tenant.
- Headers relevantes quando fizerem parte do contrato.

### Controllers ou services de aplicação

- Fluxo feliz e validação de entrada.
- Orquestração observável sem acoplamento a detalhe irrelevante.
- Transações, efeitos colaterais e erros recuperáveis quando existirem.
- Erros de domínio propagados ou convertidos conforme contrato.
- Não duplicidade e permissões/regras de acesso quando forem regras existentes.

### Models

- Criação válida, defaults e validações de campo.
- Validações de domínio, constraints, unicidade e relacionamentos.
- Métodos, properties, managers, querysets e scopes.
- Estados, transições, campos calculados e timestamps.
- Soft delete, flags, ordenação ou `Meta` quando impactarem comportamento.
- Signals, hooks, `__str__`, regras de data e timezone quando forem comportamento real e observável.

## Regras obrigatórias

- Não replique `unittest.TestCase` sem pedido explícito.
- Ao tocar em `unittest.TestCase`, converta para funções `pytest` quando a intenção puder ser preservada.
- Não mover arquivos arbitrariamente sem justificar pelo espelhamento.
- Não apagar testes úteis só porque estão feios; primeiro preserve a intenção.
- Prefira factories, fixtures pequenas e helpers locais.
- Use factories existentes para objetos complexos; imports devem ser explícitos, como `from tests.factories.factory_user import UserFactory`.
- Antes de criar uma factory, procure uma factory existente para aquele model específico.
- Crie uma factory nova apenas quando não existir factory para aquele model específico.
- Evite criar `conftest.py` global grande; prefira fixtures locais por módulo ou pasta.
- Use nomes semânticos, como `test_should_fail_when_age_is_under_18`; evite `test_success` e `test_error`.
- Organize testes em Given / When / Then quando isso melhorar leitura.
- Em Django, prefira a fixture `db` a `@pytest.mark.django_db`, salvo necessidade explícita.
- Em Django, use `transactional_db` apenas quando o caso precisar de transação real.
- Em Django, evite mockar o ORM quando a intenção for validar persistência, filtros, integridade ou consultas.
- Em FastAPI, preserve contrato HTTP completo: `status_code`, payload, headers e efeitos colaterais relevantes.
- Em FastAPI, preserve `TestClient` ou `AsyncClient` conforme o estilo da aplicação.
- Em FastAPI, use `dependency_overrides` para isolar autenticação, gateways e clients de terceiros.
- Não faça chamadas reais para serviços externos em testes unitários ou de integração locais.
- Prefira `monkeypatch`, fakes ou `dependency_overrides` a mocks excessivamente acoplados à implementação.
- Não duplique cenários idênticos em `unit` e `integration` sem motivo claro.
- Se a suíte estiver ambígua, baseie a decisão no comportamento real do código, não em convenções antigas.

## Refatoração segura

- Não misture refatoração de testes com mudança de comportamento do código de produção.
- Preserve a intenção antes de alterar forma, nome, fixture ou camada.
- Ao consolidar arquivos, mantenha cada cenário coberto em um local claro e rastreável.
- Remova duplicações apenas quando os cenários forem equivalentes de fato.
- Não apague teste instável sem substituir por cobertura confiável ou explicar o risco.
- Converta padrões legados em etapas pequenas quando a suíte for grande ou sensível.

## Testes frágeis

- Não preserve asserts acoplados a detalhes internos se houver assert comportamental melhor.
- Não dependa de ordenação quando a ordem não fizer parte do contrato.
- Não mantenha snapshots de payload completo sem necessidade clara.
- Prefira asserts explícitos, pequenos e ligados ao comportamento.
- Não mocke todas as dependências quando o objetivo for validar integração local real.

## Execução

- Pergunte ao usuário antes de rodar `pytest`, lint, typecheck ou validações demoradas.
- Se o usuário preferir executar os testes, informe os comandos relevantes em vez de rodá-los.
- Não afirme que algo foi testado se o comando não foi executado.

## Critérios de revisão

Antes de entregar, confirme:
1. A suíte ficou mais simples de manter?
2. O espelhamento com o código de produção ficou correto?
3. Houve preservação do comportamento já coberto?
4. Restaram padrões legados evitáveis?
5. A suíte ficou determinística e isolada de rede externa, horário real e estado compartilhado?
6. A refatoração não alterou comportamento de produção?
7. Duplicações foram removidas apenas quando os cenários eram equivalentes?
8. Não foi criada fixture global ou factory duplicada desnecessária?
9. O usuário foi consultado antes de executar testes ou validações demoradas?
