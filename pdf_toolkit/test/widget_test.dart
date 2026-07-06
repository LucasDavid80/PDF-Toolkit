import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_toolkit/app.dart';

void main() {
  testWidgets('Smoke test - should render tabs', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that our tabs are present.
    expect(find.text('Imagens → PDF'), findsOneWidget);
    expect(find.text('Unir PDFs'), findsOneWidget);
  });
}
