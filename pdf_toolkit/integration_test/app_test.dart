import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_toolkit/features/image_to_pdf/image_to_pdf_controller.dart';
import 'package:pdf_toolkit/features/image_to_pdf/image_to_pdf_screen.dart';
import 'package:pdf_toolkit/features/merge_pdf/merge_pdf_controller.dart';
import 'package:pdf_toolkit/features/merge_pdf/merge_pdf_screen.dart';
import 'package:pdf_toolkit/shared/file_picker_wrapper.dart';
import 'package:pdf_toolkit/shared/pdf_combiner_wrapper.dart';
import 'package:pdf_toolkit/shared/result_banner.dart';
import 'package:pdf_toolkit/shared/file_list_tile.dart';

class FixtureFilePicker extends FilePickerWrapper {
  final List<String> selectedPaths;
  final String? savePath;

  FixtureFilePicker({required this.selectedPaths, this.savePath});

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final files = selectedPaths
        .map<PlatformFile>((p) => PlatformFile(
              name: p.split(Platform.pathSeparator).last,
              path: p,
              size: 0,
            ))
        .toList();
    return FilePickerResult(files);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    return savePath;
  }
}

class FakePdfCombiner extends PdfCombinerWrapper {
  final bool shouldThrowCorrupt;
  final bool shouldThrowPermission;

  FakePdfCombiner({
    this.shouldThrowCorrupt = false,
    this.shouldThrowPermission = false,
  });

  @override
  Future<String> createPDFFromMultipleImages({
    required List inputs,
    required String outputPath,
  }) async {
    if (shouldThrowCorrupt) {
      throw PdfCombinerException('invalid image format');
    }
    if (shouldThrowPermission) {
      throw PathAccessException(
        outputPath,
        const OSError('Permission denied', 13),
        'Write permission denied',
      );
    }
    final out = File(outputPath);
    await out.create(recursive: true);
    await out.writeAsString('FAKE_PDF_FROM_IMAGES');
    return outputPath;
  }

  @override
  Future<String> mergeMultiplePDFs({
    required List inputs,
    required String outputPath,
  }) async {
    if (shouldThrowCorrupt) {
      throw PdfCombinerException('invalid pdf format or protected');
    }
    if (shouldThrowPermission) {
      throw PathAccessException(
        outputPath,
        const OSError('Permission denied', 13),
        'Write permission denied',
      );
    }
    final out = File(outputPath);
    await out.create(recursive: true);
    await out.writeAsString('FAKE_MERGED_PDF');
    return outputPath;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final sep = Platform.pathSeparator;
  final fixturesDir = 'integration_test${sep}fixtures';
  final imgFixture = '$fixturesDir${sep}image1.png';
  final docFixture = '$fixturesDir${sep}doc1.pdf';
  final corruptedFixture = '$fixturesDir${sep}corrupted.pdf';

  group('Testes de Integração da Interface do Usuário (UI)', () {

    // --- TESTES POSITIVOS ---

    testWidgets('Positivo 1: Selecionar 3 imagens -> reordenar na UI -> converter com sucesso', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_pos1.pdf';
      final picker = FixtureFilePicker(
        selectedPaths: ['img_a.png', 'img_b.jpg', 'img_c.jpeg'],
        savePath: outPath,
      );
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(
        home: ImageToPdfScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Selecionar imagens programaticamente no controller
      await controller.selectImages();
      await tester.pumpAndSettle();

      // Verificar se as 3 imagens aparecem na lista da UI
      expect(find.byType(FileListTile), findsNWidgets(3));
      expect(find.text('img_a.png'), findsOneWidget);
      expect(find.text('img_b.jpg'), findsOneWidget);
      expect(find.text('img_c.jpeg'), findsOneWidget);

      // Simular a reordenação (mover img_a para depois de img_b)
      controller.reorderImages(0, 2);
      await tester.pumpAndSettle();

      // Verificar nova ordem de visualização na UI (img_b deve ser o primeiro item da lista agora)
      final firstTile = tester.widget<FileListTile>(find.byType(FileListTile).first);
      expect(firstTile.filename, 'img_b.jpg');

      // Chamar conversão programaticamente
      await controller.convert();
      await tester.pumpAndSettle();

      // Validar que o PDF foi salvo e banner de sucesso foi exibido na UI
      expect(File(outPath).existsSync(), true);
      expect(find.byType(ResultBanner), findsOneWidget);
      expect(find.textContaining('PDF gerado com sucesso'), findsOneWidget);
    });

    testWidgets('Positivo 2: Selecionar 1 única imagem -> converter -> sucesso', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_pos2.pdf';
      final picker = FixtureFilePicker(selectedPaths: [imgFixture], savePath: outPath);
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectImages();
      await tester.pumpAndSettle();

      expect(find.byType(FileListTile), findsOneWidget);

      await controller.convert();
      await tester.pumpAndSettle();

      expect(File(outPath).existsSync(), true);
      expect(find.byType(ResultBanner), findsOneWidget);
    });

    testWidgets('Positivo 3: Selecionar 2 PDFs -> unir -> sucesso', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_pos3.pdf';
      final picker = FixtureFilePicker(selectedPaths: ['C:\\path\\doc_a.pdf', 'C:\\path\\doc_b.pdf'], savePath: outPath);
      final controller = MergePdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: MergePdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectPdfs();
      await tester.pumpAndSettle();

      expect(find.byType(FileListTile), findsNWidgets(2));

      await controller.merge();
      await tester.pumpAndSettle();

      expect(File(outPath).existsSync(), true);
      expect(find.byType(ResultBanner), findsOneWidget);
      expect(find.textContaining('PDF unido salvo em'), findsOneWidget);
    });

    testWidgets('Positivo 4: Remover um item da lista antes de confirmar -> PDF gerado apenas com restante', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_pos4.pdf';
      final picker = FixtureFilePicker(
        selectedPaths: ['img_a.png', 'img_b.jpg'],
        savePath: outPath,
      );
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectImages();
      await tester.pumpAndSettle();

      expect(find.byType(FileListTile), findsNWidgets(2));

      // Clicar no botão remover na UI do primeiro item
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Apenas img_b.jpg deve restar na UI
      expect(find.byType(FileListTile), findsOneWidget);
      expect(find.text('img_b.jpg'), findsOneWidget);
      expect(find.text('img_a.png'), findsNothing);

      await controller.convert();
      await tester.pumpAndSettle();

      expect(File(outPath).existsSync(), true);
    });

    testWidgets('Positivo 5: Após sucesso, banner de confirmação com visual correto é exibido', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_pos5.pdf';
      final picker = FixtureFilePicker(selectedPaths: [imgFixture], savePath: outPath);
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectImages();
      await tester.pumpAndSettle();

      await controller.convert();
      await tester.pumpAndSettle();

      final bannerFinder = find.byType(ResultBanner);
      expect(bannerFinder, findsOneWidget);
      
      final banner = tester.widget<ResultBanner>(bannerFinder);
      expect(banner.success, true);
    });

    // --- TESTES NEGATIVOS ---

    testWidgets('Negativo 1: Tentar unir com apenas 1 PDF selecionado -> botão Unir permanece desabilitado', (WidgetTester tester) async {
      final picker = FixtureFilePicker(selectedPaths: [docFixture]);
      final controller = MergePdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: MergePdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectPdfs();
      await tester.pumpAndSettle();

      expect(find.byType(FileListTile), findsOneWidget);

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Unir PDFs');
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull); // desabilitado na UI
    });

    testWidgets('Negativo 2: Incluir um PDF corrompido na lista -> banner de erro identifica o problema', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_neg2.pdf';
      final picker = FixtureFilePicker(selectedPaths: [docFixture, corruptedFixture], savePath: outPath);
      final combiner = FakePdfCombiner(shouldThrowCorrupt: true);
      final controller = MergePdfController(filePicker: picker, pdfCombiner: combiner);

      await tester.pumpWidget(MaterialApp(home: MergePdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectPdfs();
      await tester.pumpAndSettle();

      await controller.merge();
      await tester.pumpAndSettle();

      expect(find.byType(ResultBanner), findsOneWidget);
      final banner = tester.widget<ResultBanner>(find.byType(ResultBanner));
      expect(banner.success, false);
      expect(find.textContaining('Um ou mais arquivos PDF parecem corrompidos'), findsOneWidget);
    });

    testWidgets('Negativo 3: Tentar converter com lista de imagens vazia -> botão desabilitado', (WidgetTester tester) async {
      final controller = ImageToPdfController();
      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Converter para PDF');
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull); // desabilitado na UI
    });

    testWidgets('Negativo 4: Definir caminho de saída em diretório sem permissão de escrita -> banner de erro e app não trava', (WidgetTester tester) async {
      final outPath = '${Directory.systemTemp.path}${sep}out_neg4.pdf';
      final picker = FixtureFilePicker(selectedPaths: [imgFixture], savePath: outPath);
      final combiner = FakePdfCombiner(shouldThrowPermission: true);
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: combiner);

      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectImages();
      await tester.pumpAndSettle();

      await controller.convert();
      await tester.pumpAndSettle();

      expect(find.byType(ResultBanner), findsOneWidget);
      final banner = tester.widget<ResultBanner>(find.byType(ResultBanner));
      expect(banner.success, false);
      expect(find.textContaining('Não foi possível salvar o arquivo'), findsOneWidget);
    });

    testWidgets('Negativo 5: Tentar adicionar um tipo de arquivo não suportado (.txt) -> rejeitado, não entra na lista', (WidgetTester tester) async {
      final picker = FixtureFilePicker(selectedPaths: ['C:\\path\\doc.txt']);
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: FakePdfCombiner());

      await tester.pumpWidget(MaterialApp(home: ImageToPdfScreen(controller: controller)));
      await tester.pumpAndSettle();

      await controller.selectImages();
      await tester.pumpAndSettle();

      // Não deve ter entrado na lista na UI
      expect(find.byType(FileListTile), findsNothing);
      expect(find.byType(ResultBanner), findsOneWidget);
      final banner = tester.widget<ResultBanner>(find.byType(ResultBanner));
      expect(banner.success, false);
      expect(find.textContaining('Alguns arquivos foram ignorados'), findsOneWidget);
    });
  });
}
