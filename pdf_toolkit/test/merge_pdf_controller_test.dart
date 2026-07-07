import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_toolkit/features/merge_pdf/merge_pdf_controller.dart';
import 'package:pdf_toolkit/shared/file_picker_wrapper.dart';
import 'package:pdf_toolkit/shared/pdf_combiner_wrapper.dart';

class MockFilePickerWrapper extends Mock implements FilePickerWrapper {}
class MockPdfCombinerWrapper extends Mock implements PdfCombinerWrapper {}

void main() {
  late MockFilePickerWrapper mockFilePicker;
  late MockPdfCombinerWrapper mockPdfCombiner;
  late MergePdfController controller;

  setUpAll(() {
    registerFallbackValue(FileType.any);
  });

  setUp(() {
    mockFilePicker = MockFilePickerWrapper();
    mockPdfCombiner = MockPdfCombinerWrapper();
    controller = MergePdfController(
      filePicker: mockFilePicker,
      pdfCombiner: mockPdfCombiner,
    );
  });

  group('MergePdfController - Testes Unitários Positivos', () {
    test('1. Adicionar PDFs válidos -> lista atualizada corretamente', () async {
      final pickResult = FilePickerResult([
        PlatformFile(name: 'doc1.pdf', path: 'C:\\path\\doc1.pdf', size: 100),
        PlatformFile(name: 'doc2.pdf', path: 'C:\\path\\doc2.pdf', size: 200),
      ]);

      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: true,
          )).thenAnswer((_) async => pickResult);

      await controller.selectPdfs();

      expect(controller.pdfs.value, [
        'C:\\path\\doc1.pdf',
        'C:\\path\\doc2.pdf',
      ]);
      expect(controller.errorMessage.value, isNull);
    });

    test('2. Reordenar itens na lista -> ordem refletida no estado', () {
      controller.pdfs.value = ['doc1.pdf', 'doc2.pdf', 'doc3.pdf'];

      controller.reorderPdfs(0, 2); // mover doc1 para depois do doc2

      expect(controller.pdfs.value, ['doc2.pdf', 'doc1.pdf', 'doc3.pdf']);
    });

    test('3. Remover item da lista -> item removido, estado consistente', () {
      controller.pdfs.value = ['doc1.pdf', 'doc2.pdf', 'doc3.pdf'];

      controller.removePdf(1); // remover doc2

      expect(controller.pdfs.value, ['doc1.pdf', 'doc3.pdf']);
    });

    test('4. Unir com 2+ PDFs válidos -> PdfCombiner.mergeMultiplePDFs chamado corretamente, retorno de sucesso', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf', 'C:\\path\\doc2.pdf'];
      const outputPath = 'C:\\output\\merged.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF unido como',
            fileName: 'merged.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenAnswer((_) async => outputPath);

      await controller.merge();

      expect(controller.successMessage.value, outputPath);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);

      verify(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).called(1);
    });
  });

  group('MergePdfController - Testes Unitários Negativos', () {
    test('1. Tentar adicionar arquivo com extensão não suportada -> rejeitado, lista não muda, erro reportado', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf'];
      final pickResult = FilePickerResult([
        PlatformFile(name: 'invalid.txt', path: 'C:\\path\\invalid.txt', size: 50),
        PlatformFile(name: 'valid.pdf', path: 'C:\\path\\valid.pdf', size: 150),
      ]);

      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: true,
          )).thenAnswer((_) async => pickResult);

      await controller.selectPdfs();

      expect(controller.pdfs.value, [
        'C:\\path\\doc1.pdf',
        'C:\\path\\valid.pdf',
      ]);
      expect(controller.errorMessage.value, contains('Alguns arquivos foram ignorados'));
    });

    test('2. Tentar unir com apenas 1 PDF selecionado -> ação bloqueada, erro exposto', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf'];

      await controller.merge();

      expect(controller.errorMessage.value, contains('Selecione ao menos 2 arquivos PDF para unir.'));
      verifyNever(() => mockFilePicker.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            fileName: any(named: 'fileName'),
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
          ));
      verifyNever(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: any(named: 'outputPath'),
          ));
    });

    test('3. PdfCombiner lança exceção (PDF corrompido/protegido) -> captura e expõe mensagem amigável', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf', 'C:\\path\\corrupted.pdf'];
      const outputPath = 'C:\\output\\merged.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF unido como',
            fileName: 'merged.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenThrow(PdfCombinerException('invalid pdf format or protected'));

      await controller.merge();

      expect(controller.errorMessage.value, contains('Um ou mais arquivos PDF parecem corrompidos ou protegidos por senha.'));
      expect(controller.successMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
    });

    test('4. Falha de escrita simulada (permissão negada) -> expõe erro de I/O claro', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf', 'C:\\path\\doc2.pdf'];
      const outputPath = 'C:\\output\\merged.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF unido como',
            fileName: 'merged.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenThrow(PathAccessException('C:\\output\\merged.pdf', const OSError('Permission denied', 13), 'Write permission denied'));

      await controller.merge();

      expect(controller.errorMessage.value, contains('Não foi possível salvar o arquivo em "C:\\output\\merged.pdf". Verifique se possui permissões de escrita.'));
      expect(controller.successMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
    });

    test('5. Cancelar diálogo de salvar -> interrompe sem erro e sem processamento', () async {
      controller.pdfs.value = ['C:\\path\\doc1.pdf', 'C:\\path\\doc2.pdf'];

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF unido como',
            fileName: 'merged.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => null); // cancelado

      await controller.merge();

      expect(controller.successMessage.value, isNull);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
      verifyNever(() => mockPdfCombiner.mergeMultiplePDFs(
            inputs: any(named: 'inputs'),
            outputPath: any(named: 'outputPath'),
          ));
    });
  });
}
