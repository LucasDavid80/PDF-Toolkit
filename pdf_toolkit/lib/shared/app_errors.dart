import 'dart:io';
import 'pdf_service.dart';

class AppErrors {
  static String getFriendlyMessage(Object error, {String? outputPath}) {
    if (error is PdfServiceException) {
      return error.toString();
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
