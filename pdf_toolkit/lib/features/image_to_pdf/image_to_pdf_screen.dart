import 'package:flutter/material.dart';
import '../../shared/file_list_tile.dart';
import '../../shared/result_banner.dart';
import 'image_to_pdf_controller.dart';
import 'dart:io';

class ImageToPdfScreen extends StatefulWidget {
  final ImageToPdfController? controller;
  const ImageToPdfScreen({super.key, this.controller});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  late final ImageToPdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ImageToPdfController();
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
              // Result Banners (Success / Error)
              ValueListenableBuilder<String?>(
                valueListenable: _controller.successMessage,
                builder: (context, successPath, _) {
                  if (successPath == null) return const SizedBox.shrink();
                  return ResultBanner(
                    success: true,
                    message: 'PDF gerado com sucesso em: $successPath',
                  );
                },
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _controller.errorMessage,
                builder: (context, errorMsg, _) {
                  if (errorMsg == null) return const SizedBox.shrink();
                  return ResultBanner(
                    success: false,
                    message: errorMsg,
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _controller.selectImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Selecionar imagens (PNG, JPG, JPEG)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              // Image list
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.images,
                  builder: (context, filePaths, _) {
                    if (filePaths.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma imagem selecionada ainda.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      onReorder: _controller.reorderImages,
                      itemCount: filePaths.length,
                      itemBuilder: (context, index) {
                        final path = filePaths[index];
                        final filename = path.split(Platform.pathSeparator).last;
                        return FileListTile(
                          key: ValueKey(path),
                          filename: filename,
                          onRemove: isProcessing ? null : () => _controller.removeImage(index),
                        );
                      },
                    );
                  },
                ),
              ),

              // Action button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.images,
                  builder: (context, filePaths, _) {
                    final hasImages = filePaths.isNotEmpty;
                    return ElevatedButton(
                      onPressed: (hasImages && !isProcessing) ? _controller.convert : null,
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
                          : const Text('Converter para PDF'),
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
