
import 'package:flutter_test/flutter_test.dart';

import 'package:lending_app/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LendingApp());

    // Verify that our Dashboard Overview text is present.
    expect(find.text('Dashboard Overview'), findsOneWidget);
  });
}
