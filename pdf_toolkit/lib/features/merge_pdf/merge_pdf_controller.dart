import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_combiner/models/merge_input.dart';

import '../../shared/app_errors.dart';
import '../../shared/file_picker_wrapper.dart';
import '../../shared/pdf_service.dart';

class MergePdfController {
  final FilePickerWrapper _filePicker;
  final PdfService _pdfService;

  MergePdfController({
    FilePickerWrapper filePicker = const FilePickerWrapper(),
    PdfService pdfService = const PdfService(),
  })  : _filePicker = filePicker,
        _pdfService = pdfService;

  final ValueNotifier<List<String>> pdfs = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> successMessage = ValueNotifier<String?>(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  void clearMessages() {
    successMessage.value = null;
    errorMessage.value = null;
  }

  Future<void> selectPdfs() async {
    clearMessages();
    try {
      final result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        final List<String> newPaths = result.paths.whereType<String>().toList();

        // Filter to .pdf to be defensive
        final validPaths = newPaths.where((path) => path.toLowerCase().endsWith('.pdf')).toList();

        if (validPaths.length < newPaths.length) {
          errorMessage.value = 'Alguns arquivos foram ignorados por não serem PDFs válidos.';
        }

        pdfs.value = [...pdfs.value, ...validPaths];
      }
    } catch (e) {
      errorMessage.value = AppErrors.getFriendlyMessage(e);
    }
  }

  void removePdf(int index) {
    clearMessages();
    if (index >= 0 && index < pdfs.value.length) {
      final list = List<String>.from(pdfs.value);
      list.removeAt(index);
      pdfs.value = list;
    }
  }

  void reorderPdfs(int oldIndex, int newIndex) {
    clearMessages();
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (oldIndex != targetIndex &&
        oldIndex >= 0 && oldIndex < pdfs.value.length &&
        targetIndex >= 0 && targetIndex < pdfs.value.length) {
      final list = List<String>.from(pdfs.value);
      final item = list.removeAt(oldIndex);
      list.insert(targetIndex, item);
      pdfs.value = list;
    }
  }

  Future<void> merge() async {
    clearMessages();
    if (pdfs.value.length < 2) {
      errorMessage.value = 'Selecione ao menos 2 arquivos PDF para unir.';
      return;
    }

    String? outputPath;
    try {
      outputPath = await _filePicker.saveFile(
        dialogTitle: 'Salvar PDF unido como',
        fileName: 'merged.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) return; // user cancelled

      isProcessing.value = true;

      await _pdfService.mergePDFs(
        pdfs.value,
        outputPath,
      );

      successMessage.value = outputPath;
    } catch (e) {
      errorMessage.value = AppErrors.getFriendlyMessage(e, outputPath: outputPath);
    } finally {
      isProcessing.value = false;
    }
  }
}
