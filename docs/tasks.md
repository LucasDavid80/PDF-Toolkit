# Tasks: Conversor e Combinador de PDF

> Deriva de spec.md + plan.md. Cada tarefa é pequena o bastante para implementar e
> verificar isoladamente antes de seguir para a próxima. Marque `[x]` conforme concluir.

## Fase 0 — Fundação do projeto

- [X] 0.1 `flutter create --platforms windows,macos,linux pdf_toolkit`
- [X] 0.2 Criar estrutura de pastas definida no Plan (`features/`, `shared/`)
- [X] 0.3 Adicionar dependências no `pubspec.yaml`: `file_picker`, `pdf_combiner`, `path`
- [X] 0.4 Rodar `flutter pub get` e validar `flutter run -d <cada-plataforma>` com o
      app padrão (contador do Flutter) só pra confirmar que o ambiente desktop está OK
      nas 3 plataformas antes de escrever qualquer lógica

## Fase 1 — UI esqueleto (sem lógica)

- [X] 1.1 Criar `app.dart` com `Scaffold` + `TabBar`/`TabBarView` com 2 abas
      ("Imagens → PDF" e "Unir PDFs"), cada uma apontando pra uma tela vazia
- [X] 1.2 Criar `image_to_pdf_screen.dart` com layout estático: botão "Selecionar
      imagens", `ReorderableListView` vazio, botão "Converter" desabilitado
- [X] 1.3 Criar `merge_pdf_screen.dart` com layout estático equivalente (botão
      "Selecionar PDFs", lista, botão "Unir" desabilitado)
- [X] 1.4 Criar `shared/file_list_tile.dart` (linha: ícone + nome do arquivo + botão remover)
- [X] 1.5 Criar `shared/result_banner.dart` (banner de sucesso/erro reutilizável)

## Fase 2 — Funcionalidade 1: Imagens → PDF

- [x] 2.1 Criar `image_to_pdf_controller.dart` com estado da lista de imagens
      selecionadas (`ValueNotifier<List<String>>` ou equivalente)
- [x] 2.2 Conectar `file_picker.pickFiles` com filtro `png/jpg/jpeg` e `allowMultiple: true`
- [x] 2.3 Implementar reordenação (`onReorder` do `ReorderableListView` atualizando o
      controller) e remoção de item da lista
- [x] 2.4 Habilitar/desabilitar botão "Converter" com base na lista estar vazia ou não
- [x] 2.5 Conectar `file_picker.saveFile` para escolher caminho de saída do PDF
- [x] 2.6 Chamar `PdfCombiner.createPDFFromMultipleImages` com a lista ordenada e o
      caminho escolhido
- [x] 2.7 Tratar exceções (`PdfCombinerException`, erro de I/O) e exibir no `ResultBanner`
      com mensagem amigável (mapeamento em `shared/app_errors.dart`)
- [x] 2.8 Testar manualmente o fluxo completo nas 3 plataformas

## Fase 3 — Funcionalidade 2: Unir PDFs

- [ ] 3.1 Criar `merge_pdf_controller.dart` (mesma estrutura da Fase 2, adaptada)
- [ ] 3.2 Conectar `file_picker.pickFiles` com filtro `.pdf` e `allowMultiple: true`
- [ ] 3.3 Implementar reordenação e remoção de item (reaproveitar `file_list_tile.dart`)
- [ ] 3.4 Habilitar botão "Unir" somente com 2+ PDFs selecionados
- [ ] 3.5 Conectar `file_picker.saveFile` para o caminho de saída
- [ ] 3.6 Chamar `PdfCombiner.mergeMultiplePDFs` com a lista ordenada
- [ ] 3.7 Tratar exceções (PDF corrompido/protegido) reaproveitando `app_errors.dart`
- [ ] 3.8 Testar manualmente o fluxo completo nas 3 plataformas

## Fase 4 — Testes unitários

- [ ] 4.1 Adicionar `mocktail` como dev dependency
- [ ] 4.2 Criar mocks de `FilePicker` e `PdfCombiner` para isolar os controllers
- [ ] 4.3 Escrever os 5 testes unitários positivos da seção 8.1 do plan.md
- [ ] 4.4 Escrever os 5 testes unitários negativos da seção 8.1 do plan.md
- [ ] 4.5 Rodar `flutter test --coverage` e revisar relatório de cobertura

## Fase 5 — Testes de integração

- [ ] 5.1 Adicionar pacote `integration_test` (SDK do Flutter)
- [ ] 5.2 Criar imagens/PDFs de fixture em `integration_test/fixtures/` (incluindo pelo
      menos 1 PDF corrompido de propósito, para os casos negativos)
- [ ] 5.3 Criar fake/mock de `file_picker` via method channel para os testes de integração
      poderem "selecionar" arquivos sem diálogo nativo
- [ ] 5.4 Escrever os 5 testes de integração positivos da seção 8.2 do plan.md
- [ ] 5.5 Escrever os 5 testes de integração negativos da seção 8.2 do plan.md
- [ ] 5.6 Rodar localmente em pelo menos 1 plataforma antes de subir pro CI

## Fase 6 — Empacotamento e assinatura

- [ ] 6.1 Configurar ícone e metadata do app nas pastas `windows/`, `macos/`, `linux/`
- [ ] 6.2 Windows: escrever script Inno Setup (`.iss`) e validar `iscc` gerando o `.exe`
- [ ] 6.3 Windows: obter certificado de Code Signing e validar `signtool sign` localmente
- [ ] 6.4 macOS: validar `flutter build macos --release` + empacotamento em `.dmg`
- [ ] 6.5 macOS: configurar conta Apple Developer Program, `codesign` com Developer ID
- [ ] 6.6 macOS: validar `notarytool submit` + `stapler staple` localmente
- [ ] 6.7 Linux: validar `flutter build linux --release` + geração de `.AppImage`
- [ ] 6.8 Documentar em `README.md` onde ficam os secrets/certificados esperados (sem
      commitar nenhum segredo no repositório)

## Fase 7 — Pipeline de CI/CD

- [ ] 7.1 Criar `.github/workflows/ci.yml` com o job `lint_and_analyze`
- [ ] 7.2 Adicionar job `test` (unitários da Fase 4)
- [ ] 7.3 Adicionar job `integration_test` em matrix (windows/macos/ubuntu+xvfb)
- [ ] 7.4 Adicionar job `dependency_check` (`flutter pub outdated`)
- [ ] 7.5 Adicionar job `build` em matrix, reaproveitando os scripts da Fase 6
      (build + empacotamento + assinatura condicional aos secrets existirem)
- [ ] 7.6 Adicionar job `release` (trigger em tag `v*`), anexando os instaladores assinados
- [ ] 7.7 Adicionar job `notify` com a condição `if` descrita na seção 9 do plan.md
      (depende de `dependency_check`, `build`, `release`, tratando `release` skipped
      como OK)
- [ ] 7.8 Cadastrar secrets no repositório: certificado Windows, certificado/Developer ID
      macOS, `NOTIFY_EMAIL_TO`, `SMTP_SERVER`, `SMTP_USERNAME`, `SMTP_PASSWORD`
- [ ] 7.9 Validar o pipeline completo com um commit de teste e, depois, com uma tag `v0.1.0`

## Fase 8 — Revisão final

- [ ] 8.1 Revisar spec.md e plan.md contra o que foi de fato implementado (ajustar se
      algo mudou no caminho)
- [ ] 8.2 Rodar checklist manual dos casos de erro da spec (arquivo corrompido, sem
      permissão de escrita, extensão inválida) nas 3 plataformas
- [ ] 8.3 Gerar release `v1.0.0`
