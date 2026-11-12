import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlore_admin/screens/login_screen.dart';
import 'package:streetlore_admin/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdminService.localDraftMode.value = false;
  });

  testWidgets('login exposes sign-in options with an empty email', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('EgyptLore Admin'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.textContaining('Local Draft'), findsNothing);
    final emailField = tester.widget<TextField>(find.byType(TextField).first);
    expect(emailField.controller?.text, isEmpty);
    expect(emailField.decoration?.hintText, 'name@example.com');
    expect(tester.takeException(), isNull);
  });
}
