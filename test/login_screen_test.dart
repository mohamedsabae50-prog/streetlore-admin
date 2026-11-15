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
    expect(
      find.text('Continue in Local Preview Mode (معاينة محلية)'),
      findsOneWidget,
    );
    final emailField = tester.widget<TextField>(find.byType(TextField).first);
    expect(emailField.controller?.text, isEmpty);
    expect(emailField.decoration?.hintText, 'name@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'local preview enables draft mode and opens the dashboard route',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/dashboard': (_) =>
                const Scaffold(body: Text('Local dashboard route')),
          },
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('admin-local-preview-button')),
      );
      await tester.pumpAndSettle();

      expect(AdminService.instance.isLocalDraftMode, isTrue);
      expect(find.text('Local dashboard route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
