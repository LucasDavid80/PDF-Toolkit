# AGENTS.md

Este projeto segue o fluxo de **Spec-Driven Development (SDD)**.

## Documentos de referência (sempre consultar antes de codar)

- `docs/spec.md` — especificação funcional (o quê construir)
- `docs/plan.md` — plano técnico (stack, arquitetura, pacotes)
- `docs/tasks.md` — lista de tarefas sequenciais (o que implementar e em que ordem)

## Regras

- Nunca pule fases do `tasks.md`. Implemente uma fase por vez e aguarde confirmação
  antes de avançar para a próxima.
- Antes de editar qualquer arquivo, confirme que a mudança está alinhada com
  `spec.md` e `plan.md`. Se um requisito mudar no meio do caminho, atualize esses
  dois documentos antes de tocar em código.
- Ao final de cada fase implementada, marque os itens correspondentes como `[x]`
  em `tasks.md`.
- Não use `/goal` ou prompts abertos que disparem múltiplos subagentes em paralelo
  para tarefas deste projeto — o consumo de cota sobe rápido e sem aviso. Prefira
  uma tarefa por vez, em modo de agente único.
