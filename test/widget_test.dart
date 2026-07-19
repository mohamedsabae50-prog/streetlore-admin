import 'package:flutter_test/flutter_test.dart';

import 'package:streetlore_admin/main.dart';

void main() {
  testWidgets('Streetlore admin app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const StreetloreAdminApp());
    expect(find.byType(StreetloreAdminApp), findsOneWidget);
  });
}
