import 'package:flutter_test/flutter_test.dart';
import 'package:intera_edu/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const InteraEduApp());
    // Verifica que o app renderiza sem erros
    expect(find.byType(InteraEduApp), findsOneWidget);
  });
}
