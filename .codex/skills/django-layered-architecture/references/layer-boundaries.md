# Fronteiras entre camadas

Contrato detalhado de cada camada e os antipadrões que mais aparecem. Todo exemplo
segue a convenção de código em inglês e docstring em português.

## View

**Responsabilidade:** receber a requisição HTTP, autenticar e autorizar, delegar,
serializar a resposta.

Pode: acessar `request`, declarar permissões, montar `queryset` base, chamar
serializer e controller, registrar auditoria.

Não pode: conter regra de negócio, montar query complexa inline, chamar API
externa, decidir transição de estado.

O formato de uma view que respeita a fronteira:

```python
class AlertSettingListCreateView(ListCreateAPIView):
    queryset = AlertsSettings.objects.select_related("template", "tag_link")
    serializer_class = AlertSettingsModelSerializer
    required_permissions_slugs = {"POST": [Perms.ALERT.CREATE_ALERT_SETTINGS__SLUG]}

    def post(self, request: Request) -> Response:
        serializer = CreateAlertsSettingsSerializer(
            data=request.data,
            context={"organization": request.organization, "user": request.user},
        )
        serializer.is_valid(raise_exception=True)

        created = AlertSettingsController.create_alert_settings(**serializer.validated_data)

        return Response(
            AlertSettingsModelSerializer(created, many=True).data,
            status=status.HTTP_201_CREATED,
        )
```

Quatro passos: valida, delega, audita se for o caso, serializa. Nenhuma decisão de
negócio no meio.

## Serializer

**Responsabilidade:** validar formato, tipo e obrigatoriedade; transformar entrada
e saída.

Pode: validar campo, validar coerência entre campos do próprio payload, aplicar
`to_representation`.

Não pode: aplicar regra de negócio, orquestrar passos, escrever no banco além do
`create`/`update` triviais, decidir permissão.

A pergunta que separa: *"essa validação continuaria valendo se o dado viesse de um
CSV importado por um command?"* Se sim, ela é regra de negócio e pertence ao
controller — ou aos dois, já que o controller revalida.

## Controller

**Responsabilidade:** a regra de negócio e a orquestração. É a camada de serviço
desta arquitetura.

Pode: validar argumentos, coordenar models, chamar services e externals, abrir
transação, disparar task, levantar exceção de domínio.

Não pode: receber ou acessar `request`, montar resposta HTTP, saber status code.

### Assinatura

Receba dados já extraídos, com argumentos nomeados e tipados:

```python
# Correto
@classmethod
def create_alert_settings(
    cls,
    *,
    template: AlertTemplates,
    tag_links: list[TagLinks],
    recipients: list[User],
) -> list[AlertsSettings]:
    """Cria as configurações de alerta de um template para cada vínculo informado."""
```

```python
# Errado — acopla o controller ao HTTP
@classmethod
def create_alert_settings(cls, request: Request) -> list[AlertsSettings]:
    template = request.data["template"]
```

O segundo formato inviabiliza chamar o controller de uma task, de um command ou de
um teste sem fabricar uma request falsa.

### Revalidação

```python
@classmethod
def suspend(cls, *, alert: Alerts, hours: int) -> AlertSuspensions:
    """Suspende as notificações de um alerta pela janela informada."""
    if hours <= 0:
        raise DomainValidationError(f"Janela de suspensão inválida: {hours}. Esperado inteiro positivo.")
```

O serializer já garantiu isso no caminho HTTP. O controller garante nos outros —
task, signal, command, outro controller — e a mensagem cita o valor recebido e o
formato esperado.

## Model, manager e queryset

**Responsabilidade:** o dado e o acesso a ele.

Toda query com join, agregação, filtro composto ou que se repita em mais de um
lugar vira método de manager ou queryset:

```python
# Errado — query de domínio vazando para a view
def get_queryset(self):
    links_with_alerts = AlertsSettings.objects.filter(
        tag_link__monitored_proxy__organization=self.request.organization
    ).values_list("tag_link__id", flat=True)
    return TagLinks.objects.filter(
        monitored_proxy__organization=self.request.organization
    ).exclude(id__in=links_with_alerts)
```

```python
# Correto — a regra de "disponível para alerta" tem nome e mora no manager
def get_queryset(self):
    return TagLinks.objects.available_for_alerts(organization=self.request.organization)
```

A segunda forma é testável sem HTTP, reutilizável por task e legível no ponto de uso.

## Task

**Responsabilidade:** agendar, repetir e tolerar falha. Nada mais.

```python
@shared_task(bind=True, max_retries=3)
def process_pending_alerts(self, *, organization_id: int) -> None:
    """Dispara o processamento de alertas pendentes de uma organização."""
    try:
        AlertGenerationController.process_pending(organization_id=organization_id)
    except ExternalServiceExc as exc:
        raise self.retry(exc=exc, countdown=backoff(self.request.retries))
```

A task tem retry, backoff e log. A regra está no controller. Se a task passou de
~20 linhas, provavelmente absorveu regra que não é dela.

Prefira tasks idempotentes: elas serão reexecutadas.

## shared/

**Responsabilidade:** o que serve a todos os apps e não pertence a nenhum.

Entra: base abstrata de model, hierarquia de exceção, decorator, paginação,
exception handler, observabilidade, primitivas de lock, contrato de integração.

Não entra: qualquer coisa que cite entidade de negócio.

### O teste da regra

Um projeto tem notificação por e-mail, SMS e WhatsApp. A tentação é criar
`shared/notifications/` com os três canais. Errado:

- `shared/externals/email/sender.py` — transporte genérico, sem domínio. **Fica.**
- `shared/externals/delivery_result.py` — contrato de resultado de entrega,
  reusado pelos três canais. **Fica.**
- O envio de *notificação de alerta*, com template, destinatários e política de
  retry do domínio — **vai para o app `alerts`**, que é dono da notificação.

A infraestrutura é compartilhada; a regra que a consome, não. Se um arquivo em
`shared/` importa de um app de domínio, a fronteira já foi violada.

## Antipadrões

| Sintoma | Por que dói | Correção |
|---|---|---|
| Controller recebendo `request` | Impede chamar de task, command e teste | Passe argumentos nomeados |
| Regra de negócio no serializer | Só roda no caminho HTTP | Mova para o controller |
| Query complexa na view | Não reusa, não testa sem HTTP | Manager ou queryset nomeado |
| Task com regra dentro | Regra não testável sem Celery | Task chama controller |
| Model de domínio em `shared/` | Acopla todos os apps entre si | Mova para o app dono |
| `utils.py` genérico crescendo | Vira depósito sem dono | Divida por responsabilidade |
| Controller chamando outro app direto pelo model | Acoplamento silencioso | Chame o controller do outro app |
| Pasta vazia criada "para depois" | Sugere estrutura que não existe | Crie no primeiro uso real |

## Dependência entre apps

Um app pode depender de outro, mas pela camada certa:

- **Pode:** app A chama `BController` do app B.
- **Pode:** app A importa model do app B para relacionamento (`ForeignKey`).
- **Evite:** app A montando query complexa sobre os models do app B — essa query
  pertence ao manager do app B.
- **Nunca:** dependência circular entre controllers. Se aparecer, o conceito
  compartilhado provavelmente é um terceiro domínio, ou pertence a `shared/`
  se não tiver domínio algum.
