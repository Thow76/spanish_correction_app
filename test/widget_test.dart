import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/spanish_correction_app.dart';

void main() {
  testWidgets('shows the write screen', (tester) async {
    await tester.pumpWidget(const SpanishCorrectionApp());

    expect(find.text('Corregir'), findsWidgets);
    expect(
      find.text("Write or record - we'll handle the rest."),
      findsOneWidget,
    );
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });
}
