# Contrato de API e rollout

Revisar o contrato como cadeia, não como arquivo isolado:

`implementação → schema versionado → artefato gerado → adapter/caller → cliente implantado`

## Verificações

- Método, path, autenticação, autorização, tenant e content type.
- Campos obrigatórios, nullable, formato, limites, aliases e unknown fields.
- Status de sucesso e erro, headers, paginação e response body.
- OpenAPI ou schema gerado a partir da implementação, sem edição manual indevida.
- Cliente/SDK gerado sincronizado e callers compatíveis.
- Compatibilidade de payloads, eventos e nomes já publicados.
- Estratégia para consumidor externo ou versão antiga ainda implantada.

Buscar consumidores com `rg` e consultar docs, planos e histórico. Ausência de caller no
repositório não prova ausência de consumidor externo.

## Stacked PR e artefato gerado

Classificar separadamente:

1. O schema representa o runtime desta branch?
2. O artefato gerado está divergente?
3. A divergência é explicitamente atribuída a uma branch posterior?
4. A branch intermediária pode ser mergeada ou implantada sozinha?
5. Existe gate operacional que garante integração ordenada?

Se a geração pertence a outro PR, não pedir que ela seja movida automaticamente para o
PR atual. Registrar condição de merge/rollout quando o estado intermediário quebrar gates
ou consumidores. Tratar como bug do diff apenas quando a divisão não protege integração e
deploy reais.

Mudança breaking deve declarar consumidores afetados ou estratégia de compatibilidade.
Commit com `!` documenta intenção, mas não torna o rollout seguro por si só.
