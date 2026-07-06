import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import '../../shared/app_errors.dart';

class ImageToPdfController {
  final FilePicker? _filePicker;

  ImageToPdfController({FilePicker? filePicker}) : _filePicker = filePicker;

  FilePicker get filePicker => _filePicker ?? FilePicker.platform;

  final ValueNotifier<List<String>> images = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> successMessage = ValueNotifier<String?>(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  void clearMessages() {
    successMessage.value = null;
    errorMessage.value = null;
  }

  Future<void> selectImages() async {
    clearMessages();
    try {
      final result = await filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        final List<String> newPaths = result.paths.whereType<String>().toList();
        
        // Validação extra: garantir que apenas arquivos com extensões válidas entram na lista
        final validPaths = newPaths.where((path) {
          final lower = path.toLowerCase();
          return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');
        }).toList();

        if (validPaths.length < newPaths.length) {
          errorMessage.value = 'Alguns arquivos foram ignorados por não serem imagens (PNG/JPG/JPEG).';
        }

        images.value = [...images.value, ...validPaths];
      }
    } catch (e) {
      errorMessage.value = AppErrors.getFriendlyMessage(e);
    }
  }

  void removeImage(int index) {
    clearMessages();
    if (index >= 0 && index < images.value.length) {
      final list = List<String>.from(images.value);
      list.removeAt(index);
      images.value = list;
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    clearMessages();
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (oldIndex != targetIndex && 
        oldIndex >= 0 && oldIndex < images.value.length && 
        targetIndex >= 0 && targetIndex < images.value.length) {
      final list = List<String>.from(images.value);
      final item = list.removeAt(oldIndex);
      list.insert(targetIndex, item);
      images.value = list;
    }
  }

  Future<void> convert() async {
    clearMessages();
    if (images.value.isEmpty) {
      errorMessage.value = 'Nenhuma imagem selecionada.';
      return;
    }

    try {
      final String? outputPath = await filePicker.saveFile(
        dialogTitle: 'Salvar PDF como',
        fileName: 'imagens_convertidas.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) {
        // Cancelado pelo usuário
        return;
      }

      isProcessing.value = true;
      
      final inputs = images.value.map((path) => MergeInput.path(path)).toList();
      
      await PdfCombiner.createPDFFromMultipleImages(
        inputs: inputs,
        outputPath: outputPath,
      );

      successMessage.value = outputPath; // Usado para mostrar o local salvo
    } catch (e) {
      errorMessage.value = AppErrors.getFriendlyMessage(e);
    } finally {
      isProcessing.value = false;
    }
  }
}
