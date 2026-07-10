# Tarefas de Correção — Trocar `pdf_combiner` por stack estável

> Substituir `pdf_combiner` por: `pdf`+`image` (Dart puro) para Imagens → PDF, e
> `pdf_manipulator` (motor Rust, binário auto-baixado no build) para Unir PDFs.
> Justificativa: `pdf_combiner` apresenta falha silenciosa no Windows — a documentação
> oficial do pacote confirma que só "Android, iOS, Linux, macOS e web funcionam sem
> configuração adicional", excluindo Windows dessa lista; isso bate com o erro de CMake
> observado. O pacote `pdf` sozinho **não é suficiente para o merge** (ele só cria PDFs
> do zero, não lê PDFs existentes) — por isso o merge usa `pdf_manipulator`, não `pdf`.
> Execute uma fase por vez e aguarde confirmação antes de avançar. Siga o padrão de commits.

## Fase 0 — Planejamento e Documentação (docs)

- [x] 0.1 Atualizar o [spec.md](file:///C:/dev/projects/PDF_Toolkit/docs/spec.md) para documentar que Imagens → PDF usa o pacote `pdf` (Dart puro) e Unir PDFs usa `pdf_manipulator`.
- [x] 0.2 Atualizar o [plan.md](file:///C:/dev/projects/PDF_Toolkit/docs/plan.md) com a inclusão de `pdf`+`image` (conversão) e `pdf_manipulator` (merge), com justificativa técnica de cada escolha.
- [x] 0.3 Adicionar notas em [plan.md](file:///C:/dev/projects/PDF_Toolkit/docs/plan.md) sobre as correções de infraestrutura no CI/CD (FUSE no Linux, ícone PNG, auditoria de vulnerabilidades) a serem tratadas em fases posteriores.

## Fase 1 — Configuração e Dependências (chore)

- [x] 1.1 Remover a dependência `pdf_combiner` do [pubspec.yaml](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/pubspec.yaml).
- [x] 1.2 Adicionar `pdf: ^3.11.1` (conversão de imagens) e `pdf_manipulator: ^<versão mais recente>` (merge) no [pubspec.yaml](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/pubspec.yaml).
- [x] 1.3 Verificar se a dependência `image` já está presente (necessária para decodificar imagens); caso contrário, adicioná-la.
- [x] 1.4 Executar `flutter pub get` na pasta `pdf_toolkit` para instalar as novas dependências.
- [x] 1.5 Executar `flutter pub remove pdf_combiner` para remover o pacote do pubspec.lock.
- [x] 1.6 Confirmar que o build hook do `pdf_manipulator` baixou o binário nativo para Windows automaticamente na primeira compilação (`flutter run -d windows`) — não deveria exigir nenhum setup manual em plataformas desktop, diferente do `pdf_combiner`.

## Fase 2 — Criar Nova Camada de Serviço PDF (feat)

- [x] 2.1 Criar novo arquivo [lib/shared/pdf_service.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/lib/shared/pdf_service.dart) com as funções:
  - `convertImagesToPDF(List<String> imagePaths, String outputPath)`: usa `pw.Document` + `pw.Image(pw.MemoryImage(...))` do pacote `pdf` para gerar uma página por imagem, mantendo proporções.
  - `mergePDFs(List<String> pdfPaths, String outputPath)`: usa `PdfManipulator().mergePDFs(params: PDFMergerParams(pdfsPaths: pdfPaths))` do pacote `pdf_manipulator` e move o arquivo resultante para `outputPath`. **Não usar o pacote `pdf` aqui — ele não lê PDFs existentes.**
- [x] 2.2 Implementar validação de entrada, logging detalhado e tratamento de erros em ambas as funções — em `mergePDFs`, capturar especificamente `PdfCorrupted`, `PdfPasswordRequired` e `PdfWrongPassword` do `pdf_manipulator` e traduzir para mensagens amigáveis (ver seção 5 do plan.md).

## Fase 3 — Refatoração dos Controllers (feat/fix)

- [x] 3.1 Atualizar [image_to_pdf_controller.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/lib/features/image_to_pdf/image_to_pdf_controller.dart):
  - Remover import de `pdf_combiner_wrapper`.
  - Adicionar import de `pdf_service.dart`.
  - Substituir chamada `_pdfCombiner.createPDFFromMultipleImages()` por `PdfService.convertImagesToPDF()`.
- [x] 3.2 Atualizar [merge_pdf_controller.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/lib/features/merge_pdf/merge_pdf_controller.dart):
  - Remover import de `pdf_combiner_wrapper`.
  - Adicionar import de `pdf_service.dart`.
  - Substituir chamada `_pdfCombiner.mergeMultiplePDFs()` por `PdfService.mergePDFs()`.
- [x] 3.3 Atualizar o arquivo [app_errors.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/lib/shared/app_errors.dart) se necessário para cobrir novas exceções do `pdf_service`.

## Fase 4 — Remoção de Código Legado (chore)

- [x] 4.1 Remover ou manter como backup o arquivo [lib/shared/pdf_combiner_wrapper.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/lib/shared/pdf_combiner_wrapper.dart) (recomendação: remover após validação).

## Fase 5 — Testes e Validação Local (test)

- [x] 5.1 Executar `flutter clean && flutter pub get` para garantir ambiente limpo.
- [x] 5.2 Ajustar/criar testes unitários em [image_to_pdf_controller_test.dart](file:///C:/dev/projects/PDF_Toolkit/pdf_toolkit/test/image_to_pdf_controller_test.dart) (mockando `PdfService`).
- [x] 5.3 Rodar testes unitários com `flutter test` e garantir 100% de sucesso.
- [x] 5.4 Rodar testes de integração com `flutter test integration_test/app_test.dart` e garantir 100% de sucesso.
- [x] 5.5 Testar manualmente a conversão de imagens PNG/JPG → PDF no Windows e verificar que o PDF abre corretamente.
- [x] 5.6 Testar manualmente a mesclagem de múltiplos PDFs no Windows e verificar que todas as páginas estão presentes.

## Fase 6 — Build e Distribuição (build)

- [x] 6.1 Executar `flutter build windows` para garantir que o executável compila sem erros.
- [x] 6.2 Testar o executável compilado no Windows.
- [x] 6.3 Executar build para macOS e Linux (se aplicável) e validar.

## Fase 7 — CI/CD e Automação (ci)

- [ ] 7.1 Validar que o workflow de CI/CD ([.github/workflows/ci.yml](file:///C:/dev/projects/PDF_Toolkit/.github/workflows/ci.yml)) passa sem erros.
- [x] 7.2 Corrigir job `dependency_check` para rodar `dart pub audit` (removendo silenciamento).
- [ ] 7.3 Adicionar variável `APPIMAGE_EXTRACT_AND_RUN: 1` para Linux no CI/CD.

## Fase 8 — Documentação Final (docs)

- [ ] 8.1 Atualizar README.md com referência à Solução 3 e justificativa técnica.
- [ ] 8.2 Documentar qualquer mudança de API ou comportamento no docs/ se aplicável.
