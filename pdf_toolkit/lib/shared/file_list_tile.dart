import 'package:flutter/material.dart';

class FileListTile extends StatelessWidget {
  final String filename;
  final VoidCallback? onRemove;

  const FileListTile({super.key, required this.filename, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(filename, overflow: TextOverflow.ellipsis),
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onRemove),
    );
  }
}
