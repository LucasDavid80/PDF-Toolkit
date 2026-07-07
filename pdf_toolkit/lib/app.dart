import 'package:flutter/material.dart';
import 'features/image_to_pdf/image_to_pdf_screen.dart';
import 'features/merge_pdf/merge_pdf_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Toolkit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScaffold(),
    );
  }
}

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Toolkit'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Imagens → PDF', icon: Icon(Icons.image)),
              Tab(text: 'Unir PDFs', icon: Icon(Icons.picture_as_pdf)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ImageToPdfScreen(), MergePdfScreen()],
        ),
      ),
    );
  }
}
