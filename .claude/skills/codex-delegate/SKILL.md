---
name: codex-delegate
description: delega trabalho pesado para o Codex CLI (codex exec) e revisa o resultado, para economizar tokens do Claude. use quando o usuário pedir para delegar, mandar para o codex, usar o codex, economizar tokens, ou quando houver implementação com escopo claro, testes a escrever, refatoração mecânica, varredura grande de código ou correção de testes falhando. o Claude planeja e revisa; o Codex executa.
---

# Delegar para o Codex

## Princípio

O Claude é o tech lead: entende a demanda, decide o desenho, escreve o briefing e revisa.
O Codex é o executor: lê muito código, implementa, roda testes, itera.
O ganho só existe se o Claude **não reler** o que o Codex leu nem acompanhar a execução.
Todo o fluxo abaixo existe para manter o contexto do Claude pequeno.

## Quando delegar

Delegar:
- implementação com escopo e critério de aceite claros (ex.: plano da `implementation-plan`);
- escrever ou ampliar testes; fazer a suíte passar;
- refatoração mecânica, renomeações, migrações repetitivas, boilerplate;
- varredura ampla em modo leitura ("onde X é usado", "mapeie o fluxo de Y") — pedir resposta resumida.

Não delegar (fazer direto):
- edição pequena (poucas linhas) — o briefing custa mais que a mudança;
- decisão de desenho ainda aberta ou requisito ambíguo — resolver com o usuário primeiro;
- mudança sensível (auth, permissões, dados de produção, segredos) sem revisão linha a linha.

## Fluxo

### 1. Preparar

- Confirmar que é repositório git e anotar o estado: `git status --short` e `git rev-parse HEAD`.
  Se houver alterações não commitadas do usuário, avisar antes — o diff do Codex vai se misturar.
- Criar a pasta de trabalho: `tmp/tasks/<ID>/codex/` quando houver ID de task; senão
  `tmp/codex/<AAAAMMDD-HHMM>-<slug>/`. Garantir que `tmp/` está ignorado pelo git.

### 2. Escrever o briefing (`brief.md`)

O Codex não vê esta conversa. O briefing precisa ser autocontido e curto:

```markdown
# Objetivo
<o que deve existir ao final, em 1-3 frases>

# Contexto
- Arquivos/pontos de entrada relevantes: <caminhos>
- Padrões a seguir: <ex.: "siga o service X em path/y.py">
- Decisões já tomadas: <o que não deve ser rediscutido>

# Restrições
- Não alterar: <arquivos/áreas fora do escopo>
- Não criar dependências novas, não commitar, não fazer push.

# Critérios de aceite
- <comportamento verificável 1>
- Testes: <comando exato> passando.

# Relatório final (obrigatório, máx. 25 linhas)
- Arquivos alterados e o porquê de cada um (1 linha cada)
- Decisões tomadas fora do briefing
- Comando de teste executado e resultado
- Pendências ou dúvidas
```

Se já existe plano em `tmp/tasks/<ID>/`, referenciar o arquivo no briefing em vez de copiá-lo.

### 3. Executar em background

Rodar com `run_in_background: true`, sempre redirecionando a saída para arquivo:

```bash
D=<pasta de trabalho>
codex exec -C "$PWD" -s workspace-write --json \
  -o "$D/report.md" - < "$D/brief.md" > "$D/events.jsonl" 2>&1
```

- Varredura/análise sem edição: `-s read-only`.
- Tarefas paralelas que tocam os mesmos arquivos: usar `--worktree` em cada uma.
- **Não** fazer polling nem ler `events.jsonl` enquanto roda; esperar a notificação de término.

### 4. Revisar (barato primeiro, profundo só se precisar)

1. Ler `report.md`.
2. `git status --short` e `git diff --stat` — conferir se o escopo bate com o briefing.
3. Ler o diff apenas dos arquivos relevantes (`git diff -- <arquivo>`), não o repositório inteiro.
4. Rodar os testes indicados no critério de aceite (com saída resumida, ex.: `pytest -q`).
5. Mudança grande ou sensível: aplicar a skill `code-review` sobre o diff.

Só abrir `events.jsonl` se o relatório estiver vazio ou o Codex tiver falhado — e mesmo
assim com `tail`/`grep`, nunca inteiro.

### 5. Devolver ajustes (no máximo 2 rodadas)

Recuperar o id da sessão e continuar a mesma conversa do Codex:

```bash
TID=$(grep -o '"thread_id":"[^"]*"' "$D/events.jsonl" | head -1 | cut -d'"' -f4)
codex exec resume "$TID" -o "$D/report-2.md" - < "$D/feedback-1.md" > "$D/events-2.jsonl" 2>&1
```

(Se o id não for encontrado e não houver outra sessão em paralelo: `codex exec resume --last`.)

O `feedback-N.md` lista problemas objetivos: arquivo, linha, o que está errado, o que é esperado.
Após 2 rodadas sem convergir, ou se o ajuste restante for pequeno, o Claude corrige direto.

### 6. Fechar

Reportar ao usuário em poucas linhas: o que foi delegado, o que o Codex fez, o que o Claude
revisou/corrigiu, resultado dos testes e pendências. Não commitar sem pedido explícito.

## Segunda opinião

Para revisão independente de uma branch, além da `code-review`:
`codex exec review` (ou `codex review`) com saída para arquivo, e o Claude
confronta os achados em vez de reler tudo.
