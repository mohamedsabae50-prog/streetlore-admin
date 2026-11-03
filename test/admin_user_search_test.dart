import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  const user = AdminUser(
    id: 'user-id',
    email: 'mosaba123456@gmail.com',
    name: 'Mohamed Sabae',
    displayName: 'MOhamed Hamdy Sabae',
    username: 'mosaba123456',
  );

  test(
    'matches name, display name, username, and email case-insensitively',
    () {
      expect(user.matchesSearch('mohamed'), isTrue);
      expect(user.matchesSearch('MOHAMED HAMDY'), isTrue);
      expect(user.matchesSearch('MOSABA123456'), isTrue);
      expect(user.matchesSearch('MOSABA123456@GMAIL.COM'), isTrue);
      expect(user.matchesSearch('unrelated'), isFalse);
      expect(user.matchesSearch('  '), isTrue);
    },
  );
}
