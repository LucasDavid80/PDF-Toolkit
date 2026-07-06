import 'package:flutter/material.dart';

class ImageToPdfScreen extends StatelessWidget {
  const ImageToPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.folder_open),
            label: const Text('Selecionar imagens'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {},
              children: const <Widget>[],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: null, // disabled in the UI skeleton
            child: const Text('Converter'),
          ),
        ],
      ),
    );
  }
}

