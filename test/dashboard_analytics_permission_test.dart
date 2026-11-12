import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('recognizes analytics admin permission failures', () {
    expect(
      isAdminAnalyticsPermissionDenied(
        const PostgrestException(message: 'permission denied', code: '42501'),
      ),
      isTrue,
    );
    expect(
      isAdminAnalyticsPermissionDenied(
        const PostgrestException(message: 'Admin access required'),
      ),
      isTrue,
    );
    expect(
      isAdminAnalyticsPermissionDenied(
        const PostgrestException(
          message: 'relation does not exist',
          code: '42P01',
        ),
      ),
      isFalse,
    );
  });
}
