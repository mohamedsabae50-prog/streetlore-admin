import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlore_admin/screens/local_preview_screen.dart';
import 'package:streetlore_admin/screens/login_screen.dart';
import 'package:streetlore_admin/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdminService.localDraftMode.value = false;
  });

  testWidgets('login exposes local preview and Google sign-in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/local-preview': (_) => const LocalPreviewScreen()},
        home: const LoginScreen(),
      ),
    );

    expect(find.text('EgyptLore Admin'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(
      find.text('Open Local Preview · معاينة محلية (الإسكندرية والقاهرة)'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('admin-local-preview-button')));
    await tester.pumpAndSettle();

    expect(find.text('Governorate Local Preview'), findsOneWidget);
    expect(AdminService.instance.isLocalDraftMode, isTrue);
    expect(tester.takeException(), isNull);
  });
}
