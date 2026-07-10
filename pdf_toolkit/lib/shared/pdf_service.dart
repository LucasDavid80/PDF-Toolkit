import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';

/// Exception thrown by the [PdfService] operations.
class PdfServiceException implements Exception {
  final String message;
  final String? filePath;
  final Object? originalError;

  PdfServiceException(this.message, {this.filePath, this.originalError});

  @override
  String toString() {
    if (filePath != null) {
      return '$message (Arquivo: $filePath)';
    }
    return message;
  }
}

/// Service class to handle PDF conversions and merges.
class PdfService {
  const PdfService();

  /// Converts a list of image file paths into a single PDF document.
  ///
  /// Each page's dimensions are adjusted to the corresponding image's size to prevent distortion.
  Future<void> convertImagesToPDF(List<String> imagePaths, String outputPath) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('A lista de imagens não pode estar vazia.');
    }

    print('PdfService: Iniciando conversão de ${imagePaths.length} imagens para PDF.');
    final pdfDoc = pw.Document();

    try {
      for (final imagePath in imagePaths) {
        print('PdfService: Lendo imagem: $imagePath');
        final file = File(imagePath);
        if (!await file.exists()) {
          throw PdfServiceException(
            'Arquivo de imagem não encontrado.',
            filePath: imagePath,
          );
        }

        Uint8List imageBytes;
        try {
          imageBytes = await file.readAsBytes();
        } catch (e) {
          throw PdfServiceException(
            'Falha de leitura no arquivo de imagem. Verifique as permissões.',
            filePath: imagePath,
            originalError: e,
          );
        }

        print('PdfService: Validando integridade da imagem...');
        final decoded = img.decodeImage(imageBytes);
        if (decoded == null) {
          throw PdfServiceException(
            'A imagem selecionada parece corrompida ou possui um formato inválido.',
            filePath: imagePath,
          );
        }

        print('PdfService: Adicionando página de imagem ao PDF. Dimensões: ${decoded.width}x${decoded.height}');
        final pdfImage = pw.MemoryImage(imageBytes);
        pdfDoc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              decoded.width.toDouble(),
              decoded.height.toDouble(),
              marginAll: 0.0,
            ),
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pdfImage, fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      }

      print('PdfService: Gravando PDF final em: $outputPath');
      try {
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(await pdfDoc.save());
      } catch (e) {
        throw PdfServiceException(
          'Falha de gravação ao salvar o arquivo PDF. Verifique se possui permissões de escrita.',
          filePath: outputPath,
          originalError: e,
        );
      }

      print('PdfService: Conversão de imagens concluída com sucesso.');
    } catch (e) {
      if (e is PdfServiceException) {
        rethrow;
      }
      throw PdfServiceException(
        'Erro inesperado na conversão de imagens: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Merges multiple PDF files into a single PDF document.
  ///
  /// Utilizes the [pdf_manipulator] package which wraps a Rust engine to execute native merge.
  Future<void> mergePDFs(List<String> pdfPaths, String outputPath) async {
    if (pdfPaths.length < 2) {
      throw ArgumentError('Selecione ao menos 2 arquivos PDF para unir.');
    }

    print('PdfService: Iniciando mesclagem de ${pdfPaths.length} PDFs para: $outputPath');
    final pdf = Pdf();
    try {
      print('PdfService: Abrindo o primeiro PDF: ${pdfPaths.first}');
      late PdfEditor editor;
      try {
        editor = await pdf.edit(FileSource(File(pdfPaths.first)));
      } catch (e) {
        print('PdfService: Erro ao carregar o primeiro PDF (${pdfPaths.first}): $e');
        throw _wrapError(e, pdfPaths.first);
      }

      try {
        for (var i = 1; i < pdfPaths.length; i++) {
          final path = pdfPaths[i];
          print('PdfService: Mesclando PDF ($i/${pdfPaths.length - 1}): $path');
          try {
            await editor.mergeFrom(FileSource(File(path)));
          } catch (e) {
            print('PdfService: Erro ao mesclar o PDF ($path): $e');
            throw _wrapError(e, path);
          }
        }

        print('PdfService: Gravando PDF unido em: $outputPath');
        try {
          final outputSink = await FileSink.create(File(outputPath));
          await editor.save(outputSink);
        } catch (e) {
          print('PdfService: Erro ao salvar o arquivo resultante em ($outputPath): $e');
          throw _wrapError(e, outputPath);
        }
      } finally {
        print('PdfService: Liberando recursos do editor de PDF.');
        await editor.dispose();
      }
    } finally {
      print('PdfService: Liberando recursos do motor de PDF.');
      await pdf.dispose();
    }

    print('PdfService: Mesclagem de PDFs concluída com sucesso.');
  }

  /// Helper method to translate engine specific errors into [PdfServiceException].
  static Object _wrapError(Object error, String filePath) {
    if (error is PdfCorrupted) {
      return PdfServiceException(
        'O arquivo PDF está corrompido ou é inválido.',
        filePath: filePath,
        originalError: error,
      );
    }
    if (error is PdfPasswordRequired || error is PdfWrongPassword) {
      return PdfServiceException(
        'O arquivo PDF está protegido por senha ou requer permissão.',
        filePath: filePath,
        originalError: error,
      );
    }
    if (error is FileSystemException) {
      return PdfServiceException(
        'Erro de acesso ao disco: verifique as permissões de acesso.',
        filePath: filePath,
        originalError: error,
      );
    }
    if (error is PdfError) {
      return PdfServiceException(
        'Erro no motor de PDF: ${error.message}',
        filePath: filePath,
        originalError: error,
      );
    }
    return PdfServiceException(
      'Erro inesperado ao processar o arquivo.',
      filePath: filePath,
      originalError: error,
    );
  }
}
