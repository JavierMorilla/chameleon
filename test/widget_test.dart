import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_v2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ImpostorApp());
    expect(find.byType(ImpostorApp), findsOneWidget);
  });
}
