import 'package:flutter_test/flutter_test.dart';

import 'package:family_circle/app.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyCircleApp.mock());
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsWidgets);
    expect(find.text('Log in'), findsOneWidget);
  });
}
