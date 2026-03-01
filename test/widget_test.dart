import 'package:fluttag/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App should launch', (tester) async {
    await tester.pumpWidget(const FluttagApp(isDesktopMode: false));
    expect(find.text('fluttag'), findsOneWidget);
  });
}
