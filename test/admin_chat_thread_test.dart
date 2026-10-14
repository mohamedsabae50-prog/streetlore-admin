import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  group('groupAdminChatLogs', () {
    test('groups session messages in chronological order', () {
      final threads = groupAdminChatLogs([
        _log('second', 'session-a', '2026-10-14T10:01:00Z'),
        _log('first', 'session-a', '2026-10-14T10:00:00Z'),
      ]);

      expect(threads, hasLength(1));
      expect(threads.single.messages.map((message) => message.id), [
        'first',
        'second',
      ]);
      expect(threads.single.messages.length, 2);
    });

    test('groups consecutive legacy messages within thirty minutes', () {
      final threads = groupAdminChatLogs([
        _log('one', null, '2026-10-14T10:00:00Z'),
        _log('two', null, '2026-10-14T10:29:59Z'),
      ]);

      expect(threads, hasLength(1));
      expect(threads.single.messages, hasLength(2));
    });

    test('splits legacy messages after thirty minutes', () {
      final threads = groupAdminChatLogs([
        _log('one', null, '2026-10-14T10:00:00Z'),
        _log('two', null, '2026-10-14T10:30:01Z'),
      ]);

      expect(threads, hasLength(2));
    });
  });
}

AdminChatLog _log(String id, String? sessionId, String createdAt) =>
    AdminChatLog(
      id: id,
      userId: 'user-1',
      sessionId: sessionId,
      prompt: 'Question $id',
      response: 'Answer $id',
      createdAt: DateTime.parse(createdAt),
    );
