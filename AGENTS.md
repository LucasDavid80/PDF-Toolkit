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

## Fluxo de Git

- **Nunca** rode `git push` sem confirmação explícita minha na mensagem atual.
  Commits locais são permitidos pelas regras abaixo, mas subir pro remoto (push)
  exige minha autorização a cada vez.
- **Nunca** commite diretamente na branch `main`/`master`. Toda mudança deve ir em
  uma branch dedicada.
- Ao começar uma fase do `tasks.md`, crie (ou reutilize) uma branch nomeada
  `feature/fase-<numero>-<slug-curto>` (ex.: `feature/fase-2-imagens-pdf`) a partir
  da `main` atualizada.
- A cada item de `tasks.md` marcado como concluído (`[x]`), crie um commit local
  específico para aquele item — não acumule várias tarefas em um commit só.
  Siga o padrão **Conventional Commits**: `<tipo>(<escopo>): <descrição curta>`.

  Tipos a usar conforme a natureza do item:
  - `feat` — nova funcionalidade (Fases 1, 2, 3)
  - `test` — testes unitários ou de integração (Fases 4, 5)
  - `build` — empacotamento, instalador, assinatura de código (Fase 6)
  - `ci` — pipeline de CI/CD (Fase 7)
  - `chore` — setup de projeto, estrutura de pastas, dependências (Fase 0)
  - `docs` — documentação (README, spec/plan/tasks, seção 8.1 revisões)
  - `fix` — correção de bug encontrado durante revisão

  Escopo = nome da feature/área afetada (ex.: `image-to-pdf`, `merge-pdf`, `shared`,
  `ci`, `packaging`). Exemplos:
  - `chore(setup): criar estrutura de pastas do projeto`
  - `feat(image-to-pdf): conectar file_picker para seleção de imagens`
  - `test(image-to-pdf): testes unitários positivos do controller`
  - `build(windows): configurar assinatura de código com signtool`
  - `ci(pipeline): adicionar job de dependency_check`

  Se um item corrigir algo quebrado por um commit anterior (ex.: durante revisão de
  outro agente), use `fix` mesmo que a mudança esteja dentro da mesma fase.
- Não abra Pull Request nem faça merge para `main` sem eu pedir explicitamente.
- Se em algum momento não estiver claro se uma ação conta como "push" (ex.: criar
  tag, criar release, sincronizar branch remota), trate como push e peça
  confirmação antes.
