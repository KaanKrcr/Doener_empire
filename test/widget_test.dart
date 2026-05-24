import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/main.dart';

void main() {
  testWidgets('App startet korrekt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DoenerEmpireApp()),
    );
    expect(find.byType(DoenerEmpireApp), findsOneWidget);
  });
}
