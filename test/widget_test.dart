import 'package:flutter_test/flutter_test.dart';

import 'package:fluttag/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const FluttagApp());
    expect(find.text('Fluttag'), findsOneWidget);
  });
}
