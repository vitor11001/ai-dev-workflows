## Contexto

O fluxo de aprovação de solicitações de reembolso não notifica o solicitante quando o gestor rejeita o pedido. O usuário só descobre a rejeição ao acessar manualmente a listagem, o que gera retrabalho e atraso no reenvio com as correções necessárias.

> Restrição: o serviço de notificações já existe e é usado no fluxo de aprovação, mas ainda não está conectado ao evento de rejeição.

O recorte desta issue é tratar apenas o caminho de rejeição. O fluxo de aprovação permanece fora do escopo, exceto para garantir que não seja impactado.

## Abordagem sugerida *(opcional)*

Reaproveitar o mecanismo de notificações já usado no fluxo de aprovação e conectá-lo ao evento de rejeição. O fluxo de aprovação e a tela de detalhes da solicitação são os principais entrypoints para validar o comportamento esperado.

## Definição

**Cenário:** gestor rejeita uma solicitação com motivo preenchido.

- **Dado** que existe uma solicitação aguardando aprovação
- **E** o gestor está autenticado com permissão de aprovação
- **Quando** o gestor informa o motivo e confirma a rejeição
- **Então** a solicitação passa a constar como rejeitada
- **E** o solicitante recebe uma notificação com o motivo no corpo da mensagem
- **E** o motivo fica visível na tela de detalhes da solicitação

**Cenário:** gestor tenta rejeitar sem preencher o motivo.

- **Dado** que o gestor está na tela de rejeição de uma solicitação
- **Quando** ele tenta confirmar sem preencher o motivo
- **Então** a ação é bloqueada
- **E** uma mensagem de validação indica que o motivo é obrigatório

## Definition of done

- [ ] O motivo é obrigatório ao confirmar uma rejeição
- [ ] O solicitante recebe notificação quando a solicitação é rejeitada
- [ ] A notificação inclui o motivo da rejeição
- [ ] O motivo fica visível na tela de detalhes da solicitação
- [ ] O fluxo de aprovação continua funcionando como antes
