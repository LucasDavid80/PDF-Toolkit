import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_toolkit/features/image_to_pdf/image_to_pdf_controller.dart';
import 'package:pdf_toolkit/shared/file_picker_wrapper.dart';
import 'package:pdf_toolkit/shared/pdf_combiner_wrapper.dart';

class MockFilePickerWrapper extends Mock implements FilePickerWrapper {}
class MockPdfCombinerWrapper extends Mock implements PdfCombinerWrapper {}

void main() {
  late MockFilePickerWrapper mockFilePicker;
  late MockPdfCombinerWrapper mockPdfCombiner;
  late ImageToPdfController controller;

  setUpAll(() {
    registerFallbackValue(FileType.any);
  });

  setUp(() {
    mockFilePicker = MockFilePickerWrapper();
    mockPdfCombiner = MockPdfCombinerWrapper();
    controller = ImageToPdfController(
      filePicker: mockFilePicker,
      pdfCombiner: mockPdfCombiner,
    );
  });

  group('ImageToPdfController - Testes Unitários Positivos', () {
    test('1. Adicionar imagens válidas (png/jpg/jpeg) -> lista atualizada corretamente', () async {
      final pickResult = FilePickerResult([
        PlatformFile(name: 'image1.png', path: 'C:\\path\\image1.png', size: 100),
        PlatformFile(name: 'image2.jpg', path: 'C:\\path\\image2.jpg', size: 200),
        PlatformFile(name: 'image3.jpeg', path: 'C:\\path\\image3.jpeg', size: 300),
      ]);

      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg'],
            allowMultiple: true,
          )).thenAnswer((_) async => pickResult);

      await controller.selectImages();

      expect(controller.images.value, [
        'C:\\path\\image1.png',
        'C:\\path\\image2.jpg',
        'C:\\path\\image3.jpeg',
      ]);
      expect(controller.errorMessage.value, isNull);
    });

    test('2. Reordenar itens na lista -> ordem refletida no estado', () {
      controller.images.value = ['img1.png', 'img2.png', 'img3.png'];

      // Mover o primeiro item (img1.png) para o final
      controller.reorderImages(0, 3);

      expect(controller.images.value, ['img2.png', 'img3.png', 'img1.png']);
    });

    test('3. Remover item da lista -> item removido, estado consistente', () {
      controller.images.value = ['img1.png', 'img2.png', 'img3.png'];

      controller.removeImage(1); // Remover img2.png

      expect(controller.images.value, ['img1.png', 'img3.png']);
    });

    test('4. Converter com lista válida + caminho de saída válido -> sucesso', () async {
      controller.images.value = ['C:\\path\\img1.png', 'C:\\path\\img2.png'];
      const outputPath = 'C:\\output\\result.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF como',
            fileName: 'imagens_convertidas.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenAnswer((_) async => outputPath);

      await controller.convert();

      expect(controller.successMessage.value, outputPath);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);

      verify(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).called(1);
    });
  });

  group('ImageToPdfController - Testes Unitários Negativos', () {
    test('1. Tentar adicionar arquivo com extensão não suportada (.gif) -> rejeitado, lista não muda, erro reportado', () async {
      controller.images.value = ['C:\\path\\img1.png'];
      final pickResult = FilePickerResult([
        PlatformFile(name: 'invalid.gif', path: 'C:\\path\\invalid.gif', size: 100),
        PlatformFile(name: 'valid.jpg', path: 'C:\\path\\valid.jpg', size: 200),
      ]);

      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg'],
            allowMultiple: true,
          )).thenAnswer((_) async => pickResult);

      await controller.selectImages();

      // O item .gif deve ter sido ignorado, apenas o .jpg adicionado
      expect(controller.images.value, [
        'C:\\path\\img1.png',
        'C:\\path\\valid.jpg',
      ]);
      expect(controller.errorMessage.value, contains('Alguns arquivos foram ignorados'));
    });

    test('2. Tentar converter com lista de imagens vazia -> ação bloqueada, sem chamar o pacote', () async {
      controller.images.value = [];

      await controller.convert();

      expect(controller.errorMessage.value, contains('Nenhuma imagem selecionada'));
      verifyNever(() => mockFilePicker.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            fileName: any(named: 'fileName'),
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
          ));
      verifyNever(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: any(named: 'outputPath'),
          ));
    });

    test('3. PdfCombiner lança exceção (imagem corrompida) -> captura e expõe mensagem amigável', () async {
      controller.images.value = ['C:\\path\\corrupted.png'];
      const outputPath = 'C:\\output\\result.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF como',
            fileName: 'imagens_convertidas.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenThrow(PdfCombinerException('invalid image format'));

      await controller.convert();

      expect(controller.errorMessage.value, contains('Uma ou mais imagens selecionadas parecem corrompidas ou inválidas.'));
      expect(controller.successMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
    });

    test('4. Falha de escrita simulada (permissão negada) -> expõe erro de I/O claro', () async {
      controller.images.value = ['C:\\path\\img1.png'];
      const outputPath = 'C:\\output\\result.pdf';

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF como',
            fileName: 'imagens_convertidas.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => outputPath);

      when(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: outputPath,
          )).thenThrow(FileSystemException('Write permission denied', 'C:\\output\\result.pdf'));

      await controller.convert();

      expect(controller.errorMessage.value, contains('Não foi possível salvar o arquivo em "C:\\output\\result.pdf". Verifique se possui permissões de escrita.'));
      expect(controller.successMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
    });

    test('5. Cancelar diálogo de salvar -> interrompe sem erro e sem processamento', () async {
      controller.images.value = ['C:\\path\\img1.png'];

      when(() => mockFilePicker.saveFile(
            dialogTitle: 'Salvar PDF como',
            fileName: 'imagens_convertidas.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          )).thenAnswer((_) async => null); // Cancelado

      await controller.convert();

      expect(controller.successMessage.value, isNull);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isProcessing.value, isFalse);
      verifyNever(() => mockPdfCombiner.createPDFFromMultipleImages(
            inputs: any(named: 'inputs'),
            outputPath: any(named: 'outputPath'),
          ));
    });
  });
}
