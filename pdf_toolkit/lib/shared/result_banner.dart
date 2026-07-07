import 'package:flutter/material.dart';

class ResultBanner extends StatelessWidget {
  final String message;
  final bool success;

  const ResultBanner({super.key, required this.message, this.success = true});

  @override
  Widget build(BuildContext context) {
    final Color bg = success ? Colors.green.shade50 : Colors.red.shade50;
    final Color fg = success ? Colors.green.shade800 : Colors.red.shade800;

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: fg)),
          ),
        ],
      ),
    );
  }
}
