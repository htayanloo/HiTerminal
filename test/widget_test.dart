import 'package:flutter_test/flutter_test.dart';

import 'package:hi_terminal/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const HiTerminalApp());
    expect(find.byType(HiTerminalApp), findsOneWidget);
  });
}
