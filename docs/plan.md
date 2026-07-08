# Plano Técnico: Conversor e Combinador de PDF

> Deriva da spec.md. Define arquitetura, pacotes e estrutura de pastas.

## 1. Stack

- **Framework**: Flutter (build desktop nativo — Windows, macOS, Linux)
- **Linguagem**: Dart
- **Gerenciamento de estado**: `setState` / `ValueNotifier` (app pequeno, não precisa de
  Provider/Riverpod/Bloc — evitar complexidade desnecessária)
- **Repositório**: ver `README.md` na raiz do projeto

## 2. Pacotes principais

| Pacote | Função | Motivo da escolha |
|---|---|---|
| `file_picker` | Diálogos nativos para selecionar imagens/PDFs e "Salvar como" | Padrão da comunidade, suporte desktop maduro (Windows/macOS/Linux), mantido ativamente |
| `pdf` | Geração de PDF a partir de imagens (Funcionalidade 1) | Pacote Dart puro, sem código nativo — mas **só cria PDFs do zero**, não lê/mescla PDFs existentes. Por isso não serve para a Funcionalidade 2 |
| `pdf_manipulator` | Merge de PDFs existentes (Funcionalidade 2) | Motor Rust; baixa o binário certo automaticamente no build para Windows/macOS/Linux (sem exigir CMake instalado localmente — era exatamente essa a causa raiz da falha silenciosa do `pdf_combiner` no Windows); expõe merge real de página (`PdfManipulator().mergePDFs(...)`) e exceções estruturadas (`PdfCorrupted`, `PdfPasswordRequired`, `PdfWrongPassword`) que mapeiam direto nos casos de erro da spec |
| `image` | Decodificar e processar formatos de imagem (PNG/JPG/JPEG) | Pacote Dart puro para conversão confiável e de alta portabilidade de bytes de imagem |
| `path` | Manipulação de caminhos (extrair extensão, nome de arquivo) | Pacote oficial do Dart, sem overhead |

Não usaremos `reorderable_listview` como pacote externo — o Flutter já tem
`ReorderableListView` nativo no Material, suficiente para o requisito de reordenar
imagens/PDFs antes de gerar o arquivo final.

## 3. Arquitetura / Estrutura de pastas

```
lib/
  main.dart                  # entry point, MaterialApp, tema
  app.dart                   # Scaffold raiz com as duas abas (TabBar)
  features/
    image_to_pdf/
      image_to_pdf_screen.dart   # UI: lista reordenável + botões
      image_to_pdf_controller.dart # lógica: seleção, ordenação, chamada ao PdfService
    merge_pdf/
      merge_pdf_screen.dart
      merge_pdf_controller.dart  # lógica: seleção, ordenação, chamada ao PdfService
  shared/
    file_list_tile.dart       # widget reutilizável (linha da lista com nome + remover)
    result_banner.dart        # feedback de sucesso/erro reutilizável nas duas telas
    app_errors.dart           # tipos de erro tratados (arquivo corrompido, sem permissão, etc.)
    pdf_service.dart          # fachada única: convertImagesToPDF() usa `pdf`+`image`;
                               # mergePDFs() usa `pdf_manipulator` internamente
```

Separação **screen (UI)** vs **controller (lógica)** em cada feature: mantém a lógica de
seleção/ordenação/chamada de pacote testável sem precisar montar widgets.

## 4. Fluxo de dados (por funcionalidade)

**Imagens → PDF**
1. `file_picker.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','jpeg'], allowMultiple: true)`
2. Lista exibida em `ReorderableListView`; usuário reordena/remove.
3. Ao confirmar: `file_picker.saveFile(...)` para escolher destino.
4. `PdfService.convertImagesToPDF(imagePaths: [...], outputPath: ...)`
5. Exibir `ResultBanner` de sucesso/erro.

**Unir PDFs**
1. `file_picker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true)`
2. Mesma lista reordenável, mínimo de 2 itens para habilitar o botão.
3. `file_picker.saveFile(...)`
4. `PdfService.mergePDFs(pdfPaths: [...], outputPath: ...)` — internamente chama
   `PdfManipulator().mergePDFs(params: PDFMergerParams(pdfsPaths: [...]))` e move/renomeia
   o resultado para o `outputPath` escolhido pelo usuário.
5. `ResultBanner` de sucesso/erro.

## 5. Tratamento de erros (mapeando a spec)

- **Imagens → PDF**: exceções do pacote `image` (imagem corrompida/formato inválido)
  são capturadas e traduzidas em mensagens amigáveis via `app_errors.dart`.
- **Unir PDFs**: `pdf_manipulator` lança exceções tipadas que mapeiam direto nos
  casos de erro da spec — `PdfCorrupted` → "arquivo corrompido", `PdfPasswordRequired`/
  `PdfWrongPassword` → "PDF protegido por senha", `PdfError` genérico → erro de I/O ou
  outro problema. `app_errors.dart` faz esse `switch` e devolve a mensagem certa por tipo.
- Falha de escrita (permissão negada) tratada como erro genérico de I/O, com mensagem
  "Não foi possível salvar o arquivo em [caminho]".
- Em ambos os casos: identificar qual arquivo causou a falha antes de abortar, oferecendo
  feedback claro na tela (o usuário pode remover o arquivo problemático e tentar de novo).

## 6. Decisões técnicas em aberto (assumidas por padrão, revisáveis)

- **Tamanho de página do PDF gerado a partir de imagem**: ajustado ao tamanho de cada
  imagem (não fixo em A4/Letter) — evita distorcer/cortar fotos. Pode ser mudado depois
  se preferir padronização.
- **Nome do app**: "PDF Toolkit" como placeholder até definirem um nome.

## 7. Empacotamento / Instalador

Build de release por plataforma via `flutter build <platform> --release`, empacotado
assim:

| Plataforma | Ferramenta | Saída |
|---|---|---|
| Windows | Inno Setup (script `.iss` compilado via `iscc`) | `.exe` instalador |
| macOS | `flutter build macos` + `hdiutil` (ou `create-dmg`) | `.dmg` |
| Linux | `flutter build linux` + AppImage (`appimagetool`) | `.AppImage` |

### 7.1 Assinatura de código / Notarização

- **Windows**: assinar o instalador `.exe` com `signtool sign /f <certificado.pfx> /p <senha> /fd sha256 /tr <timestamp-server> /td sha256 saida.exe`, usando um certificado de assinatura de código (Code Signing Certificate) de uma CA reconhecida. Sem isso o SmartScreen ainda avisa "editor desconhecido".
- **macOS**: `codesign --deep --force --sign "Developer ID Application: <nome>" MyApp.app`, seguido de `xcrun notarytool submit` (envia pra Apple validar) e `xcrun stapler staple` (anexa o carimbo de aprovação ao `.app`/`.dmg`). Exige conta paga no Apple Developer Program.
- **Linux**: não existe um mecanismo de assinatura padrão equivalente (AppImage tem suporte experimental a GPG, mas não é um requisito de mercado como nos outros dois); manter assinatura GPG do AppImage como item opcional, não bloqueante.

**Pré-requisito prático**: certificado de Code Signing (Windows) e conta Apple Developer
Program (macOS) precisam existir antes da CI poder assinar de fato. Enquanto isso não
estiver disponível, o pipeline pode rodar com uma etapa de assinatura "condicional"
(só executa se os secrets do certificado estiverem configurados), para não travar o
restante do fluxo por falta de credencial. Isso deve ser resolvido antes de distribuir
a primeira versão publicamente.

Para o pipeline de CI, o job de build roda em runners `windows-latest`, `macos-latest`
e `ubuntu-latest` (matrix), cada um gerando e assinando o pacote da sua própria
plataforma.

## 8. Estratégia de Testes

### 8.1 Testes unitários (`flutter_test` + `mocktail` para simular `file_picker` e `PdfService`)
Focados na lógica dos controllers (`image_to_pdf_controller`, `merge_pdf_controller`),
sem UI nem I/O real.

**Positivos (mínimo 5):**
1. Adicionar imagens válidas (png/jpg/jpeg) → lista atualizada corretamente.
2. Reordenar itens na lista → ordem refletida no estado.
3. Remover item da lista → item removido, estado consistente.
4. Converter com lista válida + caminho de saída válido → `PdfService.convertImagesToPDF`
   chamado com os parâmetros corretos, retorno de sucesso.
5. Unir com 2+ PDFs válidos → `PdfService.mergePDFs` chamado corretamente,
   retorno de sucesso.

**Negativos (mínimo 5):**
1. Tentar adicionar arquivo com extensão não suportada (ex. `.gif`) → rejeitado, lista
   não muda, erro reportado.
2. Tentar converter com lista de imagens vazia → ação bloqueada, sem chamar o serviço.
3. Tentar unir com apenas 1 PDF selecionado → ação bloqueada, erro "selecione ao menos 2".
4. `PdfService` lança exceção (arquivo corrompido) → controller captura e expõe
   mensagem amigável, sem crashar.
5. Falha de escrita simulada (permissão negada) → controller expõe erro de I/O claro.

### 8.2 Testes de integração (`integration_test`, pacote oficial do Flutter)
Sobem a árvore de widgets real; `file_picker` é substituído por um fake/mock via
method channel (não dá pra automatizar o diálogo nativo do SO), usando arquivos de
fixture reais em disco.

**Positivos (mínimo 5):**
1. Fluxo completo: selecionar 3 imagens de fixture → reordenar na UI → converter →
   PDF gerado tem exatamente 3 páginas na ordem esperada.
2. Selecionar 1 única imagem → converter → PDF gerado com 1 página.
3. Selecionar 2 PDFs de fixture → unir → PDF final com a soma exata de páginas dos dois.
4. Remover um item da lista antes de confirmar → PDF final reflete só os itens restantes.
5. Após sucesso, banner de confirmação aparece na tela.

**Negativos (mínimo 5):**
1. Tentar unir com apenas 1 PDF selecionado → botão permanece desabilitado, nenhum
   arquivo é gerado.
2. Incluir um PDF de fixture corrompido (bytes inválidos) no meio da lista → banner de
   erro identifica o problema, nenhum output é gerado.
3. Tentar converter com lista de imagens vazia → botão desabilitado, sem crash.
4. Definir caminho de saída em diretório sem permissão de escrita → banner de erro,
   app não trava.
5. Tentar adicionar um tipo de arquivo não suportado (ex. `.txt`) forçado via fake do
   picker → arquivo rejeitado, não entra na lista.

## 9. Pipeline de CI/CD

Sugestão: **GitHub Actions** (`.github/workflows/ci.yml`), com os jobs pedidos mais
alguns complementares que valem a pena num projeto assim:

1. **lint_and_analyze** — `dart format --set-exit-if-changed .` + `flutter analyze`.
   Falha rápido antes de gastar tempo com build/teste. *(job extra sugerido)*
2. **test** — `flutter test --coverage` (os testes unitários da seção 8.1). Roda em
   `ubuntu-latest`, é o mais rápido e não precisa de matrix por plataforma.
3. **integration_test** — roda os testes da seção 8.2 em matrix
   (`windows-latest`, `macos-latest`, `ubuntu-latest` com `xvfb` para o display virtual
   no Linux), já que comportamento de arquivo/diálogo pode variar por SO.
4. **build** — matrix nas 3 plataformas, roda `flutter build <platform> --release` +
   empacotamento (seção 7), sobe os artefatos (`actions/upload-artifact`). Só roda se
   `test` e `integration_test` passarem.
5. **notify** — roda por último, depois de **todos** os outros jobs terem sucesso:
   depende de `dependency_check`, `release` e `build`. Baixa os artefatos gerados
   (já assinados) e envia por e-mail usando uma action de SMTP (ex.
   `dawidd6/action-send-mail`), lendo o destinatário de uma variável de
   ambiente/secret (ex. `NOTIFY_EMAIL_TO`) e as credenciais SMTP de secrets do
   repositório (`SMTP_SERVER`, `SMTP_USERNAME`, `SMTP_PASSWORD`) — nunca hardcoded
   no workflow.

   ⚠️ **Detalhe importante**: `release` só roda em push de tag (`v*`); em commits
   normais ele é *skipped*, não *failed*. Se `notify` simplesmente depender de
   `release`, o GitHub Actions vai pular `notify` também em commits normais (skip
   propaga por padrão). Para `notify` rodar sempre que `dependency_check` e `build`
   passarem — tratando `release` puramente como "se rodou, tem que ter dado certo,
   mas não é obrigatório ter rodado" — a condição do job precisa ser explícita:

   ```yaml
   notify:
     needs: [dependency_check, release, build]
     if: |
       always() &&
       needs.dependency_check.result == 'success' &&
       needs.build.result == 'success' &&
       (needs.release.result == 'success' || needs.release.result == 'skipped')
   ```

6. **release** — ao dar push de uma tag (`v*`), cria uma GitHub Release
   automaticamente anexando os instaladores assinados das 3 plataformas. Dá um
   histórico de versões sem esforço manual. Roda antes de `notify`.
7. **dependency_check** — roda `flutter pub outdated` e falha se houver dependência
   com vulnerabilidade conhecida; complementa o `test` cuidando da saúde das
   dependências, não do código em si. Roda antes de `notify`.

Fluxo de dependência entre jobs:
```
lint_and_analyze ─┐
                   │
test ──────────────┼─► build ─┐
                   │           ├─► release (só em tag) ─┐
integration_test ──┘           │                         ├─► notify
                               └─────────────────────────┘
dependency_check ───────────────────────────────────────────┘
```

## 10. Próximo passo do fluxo SDD

Depois de você validar este plano atualizado, seguimos para **Tasks**: quebrar tudo
isso (app + testes + empacotamento + pipeline) em uma lista de tarefas pequenas e
sequenciais, cada uma pequena o bastante para implementar e verificar isoladamente.
