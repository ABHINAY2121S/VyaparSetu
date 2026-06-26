import 'package:flutter_test/flutter_test.dart';
import 'package:vyaparsetu/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VyaparSetuApp());
    expect(find.byType(VyaparSetuApp), findsOneWidget);
  });
}
