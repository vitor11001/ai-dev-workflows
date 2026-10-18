# Cenários por alvo

Cardápio de cenários para escolher o que cobrir (modo criar) ou o que preservar (modo refatorar). Escolha os cenários que provam o comportamento alterado, as regras de domínio e os riscos relevantes; não crie cenários artificiais sem relação com a mudança, e não remova cobertura útil desses comportamentos quando ela já existir.

## Views, controllers e endpoints

- Sucesso principal: status esperado, payload esperado e formato do contrato.
- Objeto inexistente: `404` ou erro equivalente.
- Entrada inválida: `400`, `422` ou erro equivalente, com campo inválido e mensagem esperada.
- Permissão, autenticação e autorização: usuário anônimo, sem permissão e com permissão quando aplicável.
- Filtros e busca: retorna apenas dados compatíveis com query params.
- Paginação e ordenação: página, limite, ordenação e metadados quando fizerem parte do contrato.
- Criação: persiste objeto com campos corretos e retorna contrato correto.
- Atualização parcial ou total: altera apenas o esperado e preserva o restante.
- Exclusão: remove, desativa ou marca corretamente e responde com status esperado.
- Idempotência: repetir request não duplica efeito quando o contrato exigir.
- Efeitos colaterais: evento, service interno, job, cache ou outra integração observável.
- Erros de domínio: exceções esperadas são traduzidas para resposta correta.
- Serialização: campos calculados, datas, enums e relacionamentos no formato esperado.
- Escopo de usuário ou multi-tenant: usuário não acessa dados de outro dono ou tenant.
- Headers relevantes: `Location`, cache, content type ou autenticação quando fizerem parte do contrato.

## Controllers ou services de aplicação

- Fluxo feliz: retorna o resultado esperado.
- Validação de entrada: rejeita valores inválidos.
- Orquestração observável: integra repositórios, gateways ou services no nível certo sem testar detalhe irrelevante.
- Transações: commit, rollback ou atomicidade quando aplicável.
- Efeitos colaterais: eventos, jobs, logs relevantes, cache ou notificações.
- Erros recuperáveis: fallback, retry ou tradução de erro quando existir.
- Erros de domínio: propaga ou converte exceção conforme contrato.
- Não duplicidade: não cria registros duplicados em chamadas repetidas quando isso for regra.
- Permissões e regras de acesso quando o controller aplicar regra antes de chamar domínio.

## Models

- Criação válida com dados mínimos.
- Defaults aplicados corretamente.
- Validações de campo: obrigatório, tamanho, formato e escolhas/enums.
- Validações de domínio: combinações inválidas de campos são rejeitadas.
- Constraints e unicidade.
- Relacionamentos: `ForeignKey`, `OneToOne`, `ManyToMany`, cascade, protect ou set null quando relevante.
- Métodos e properties com valores calculados corretos.
- Managers, querysets e scopes retornando exatamente o conjunto esperado.
- Estados e transições permitidas ou proibidas.
- Persistência de campos calculados: totals, slugs, campos normalizados e timestamps.
- Soft delete e flags de ativo/inativo.
- Ordenação ou `Meta` quando impactar comportamento.
- Signals e hooks apenas quando forem comportamento real e observável.
- Representação textual como `__str__` quando usada por admin, logs ou UI.
- Regras de data e timezone quando houver vencimento, expiração ou janela temporal.
