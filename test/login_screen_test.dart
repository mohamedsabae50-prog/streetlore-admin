import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login exposes sign-in options with an empty email', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('EgyptLore Admin'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      find.text('Continue in Local Preview Mode (معاينة محلية)'),
      findsNothing,
    );
    expect(find.text('Explore Preview · تصفح المعاينة'), findsNothing);
    expect(
      find.byKey(const ValueKey('admin-local-preview-button')),
      findsNothing,
    );
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    final emailField = tester.widget<TextField>(find.byType(TextField).first);
    expect(emailField.controller?.text, isEmpty);
    expect(emailField.decoration?.hintText, 'name@example.com');
    expect(tester.takeException(), isNull);
  });
}
