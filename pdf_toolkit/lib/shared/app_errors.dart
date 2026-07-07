import 'dart:io';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';

class AppErrors {
  static String getFriendlyMessage(Object error, {String? outputPath}) {
    if (error is PdfCombinerException) {
      final message = error.message;
      if (message.contains('invalid image') || message.contains('image format')) {
        return 'Uma ou mais imagens selecionadas parecem corrompidas ou inválidas.';
      }
      if (message.contains('invalid pdf') || message.contains('corrupt') || message.contains('password protected')) {
        return 'Um ou mais arquivos PDF parecem corrompidos ou protegidos por senha.';
      }
      return 'Erro ao processar PDF: $message';
    }

    if (error is FileSystemException) {
      if (outputPath != null) {
        return 'Não foi possível salvar o arquivo em "$outputPath". Verifique se possui permissões de escrita.';
      }
      return 'Erro de acesso ao disco: sem permissão para ler ou salvar o arquivo.';
    }

    return 'Ocorreu um erro inesperado: ${error.toString()}';
  }
}
