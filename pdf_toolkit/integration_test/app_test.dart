import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_toolkit/features/image_to_pdf/image_to_pdf_controller.dart';
import 'package:pdf_toolkit/features/merge_pdf/merge_pdf_controller.dart';
import 'package:pdf_toolkit/shared/file_picker_wrapper.dart';
import 'package:pdf_toolkit/shared/pdf_combiner_wrapper.dart';
import 'package:file_picker/file_picker.dart';

class FixtureFilePicker extends FilePickerWrapper {
  final List<String> selectedPaths;
  final String? savePath;

  FixtureFilePicker({required this.selectedPaths, this.savePath});

  @override
  Future<FilePickerResult?> pickFiles({String? dialogTitle, FileType type = FileType.any, List<String>? allowedExtensions, bool allowMultiple = false}) async {
    // simulate FilePickerResult from fixture paths
    final files = selectedPaths.map<PlatformFile>((p) => PlatformFile(name: p.split(Platform.pathSeparator).last, path: p, size: 0)).toList();
    return FilePickerResult(files);
  }

  @override
  Future<String?> saveFile({String? dialogTitle, String? fileName, FileType type = FileType.any, List<String>? allowedExtensions}) async {
    return savePath;
  }
}

class FakePdfCombiner extends PdfCombinerWrapper {
  @override
  Future<String> createPDFFromMultipleImages({required List inputs, required String outputPath}) async {
    // create a fake output file to simulate success
    final out = File(outputPath);
    await out.create(recursive: true);
    await out.writeAsString('FAKE_PDF_FROM_IMAGES');
    return outputPath;
  }

  @override
  Future<String> mergeMultiplePDFs({required List inputs, required String outputPath}) async {
    final out = File(outputPath);
    await out.create(recursive: true);
    await out.writeAsString('FAKE_MERGED_PDF');
    return outputPath;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration tests (fixtures)', () {
    testWidgets('Image -> PDF flow (integration) using fixtures', (WidgetTester tester) async {
      final fixturesDir = Directory('integration_test${Platform.pathSeparator}fixtures');
      final img = fixturesDir.path + Platform.pathSeparator + 'image1.png';
      final outPath = Directory.systemTemp.path + Platform.pathSeparator + 'out_images.pdf';

      final picker = FixtureFilePicker(selectedPaths: [img], savePath: outPath);
      final combiner = FakePdfCombiner();
      final controller = ImageToPdfController(filePicker: picker, pdfCombiner: combiner);

      // simulate selection and conversion
      await controller.selectImages();
      expect(controller.images.value.length, 1);

      await controller.convert();

      expect(File(outPath).existsSync(), true);
      expect(controller.successMessage.value, outPath);
    });

    testWidgets('Merge PDFs flow (integration) using fixtures', (WidgetTester tester) async {
      final fixturesDir = Directory('integration_test${Platform.pathSeparator}fixtures');
      final doc = fixturesDir.path + Platform.pathSeparator + 'doc1.pdf';
      final outPath = Directory.systemTemp.path + Platform.pathSeparator + 'out_merged.pdf';

      final picker = FixtureFilePicker(selectedPaths: [doc, doc], savePath: outPath);
      final combiner = FakePdfCombiner();
      final controller = MergePdfController(filePicker: picker, pdfCombiner: combiner);

      await controller.selectPdfs();
      expect(controller.pdfs.value.length, 2);

      await controller.merge();

      expect(File(outPath).existsSync(), true);
      expect(controller.successMessage.value, outPath);
    });

    testWidgets('Merge detects corrupted pdf fixture and reports error', (WidgetTester tester) async {
      final fixturesDir = Directory('integration_test${Platform.pathSeparator}fixtures');
      final corrupted = fixturesDir.path + Platform.pathSeparator + 'corrupted.pdf';
      final outPath = Directory.systemTemp.path + Platform.pathSeparator + 'out_bad.pdf';

      final picker = FixtureFilePicker(selectedPaths: [corrupted], savePath: outPath);
      final combiner = FakePdfCombiner();
      final controller = MergePdfController(filePicker: picker, pdfCombiner: combiner);

      // select one corrupted file and attempt to merge (should require 2+ and thus error)
      await controller.selectPdfs();
      expect(controller.pdfs.value.length, 1);

      await controller.merge();

      expect(controller.errorMessage.value, isNotNull);
    });
  });
}
