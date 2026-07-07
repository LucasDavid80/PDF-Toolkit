import 'package:flutter/material.dart';
import 'dart:io';

import 'merge_pdf_controller.dart';
import '../../shared/file_list_tile.dart';
import '../../shared/result_banner.dart';

class MergePdfScreen extends StatefulWidget {
  final MergePdfController? controller;
  const MergePdfScreen({super.key, this.controller});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  late final MergePdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MergePdfController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isProcessing,
        builder: (context, isProcessing, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banners
              ValueListenableBuilder<String?>(
                valueListenable: _controller.successMessage,
                builder: (context, successPath, _) {
                  if (successPath == null) return const SizedBox.shrink();
                  return ResultBanner(
                    message: 'PDF unido salvo em: $successPath',
                    success: true,
                  );
                },
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _controller.errorMessage,
                builder: (context, err, _) {
                  if (err == null) return const SizedBox.shrink();
                  return ResultBanner(message: err, success: false);
                },
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _controller.selectPdfs,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Selecionar PDFs'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.pdfs,
                  builder: (context, files, _) {
                    if (files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum PDF selecionado.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      onReorder: _controller.reorderPdfs,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final path = files[index];
                        final filename = path
                            .split(Platform.pathSeparator)
                            .last;
                        return FileListTile(
                          key: ValueKey(path),
                          filename: filename,
                          onRemove: isProcessing
                              ? null
                              : () => _controller.removePdf(index),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.pdfs,
                  builder: (context, files, _) {
                    final canMerge = files.length >= 2 && !isProcessing;
                    return ElevatedButton(
                      onPressed: canMerge ? _controller.merge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Unir PDFs'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
