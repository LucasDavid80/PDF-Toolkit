import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

class PdfCombinerWrapper {
  const PdfCombinerWrapper();

  Future<String> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    return PdfCombiner.createPDFFromMultipleImages(
      inputs: inputs,
      outputPath: outputPath,
    );
  }

  Future<String> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    return PdfCombiner.mergeMultiplePDFs(
      inputs: inputs,
      outputPath: outputPath,
    );
  }
}
