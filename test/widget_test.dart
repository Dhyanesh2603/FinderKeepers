import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finders_keepers/main.dart';

void main() {
  testWidgets('App smoke test: loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FindersKeepersApp(),
      ),
    );

    expect(find.textContaining('Finders'), findsOneWidget);
    expect(find.text('Enter Campus Hub'), findsOneWidget);
  });
}
