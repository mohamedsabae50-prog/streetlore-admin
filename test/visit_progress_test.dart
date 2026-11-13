import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/services/visit_progress.dart';

void main() {
  test('visit progress applies XP deltas and unlocks each milestone once', () {
    final progress = calculateVisitProgress(
      currentPoints: 45,
      previousPlaceCount: 4,
      placeCount: 10,
      currentBadges: const [
        {'id': 'visit_milestone_1', 'name': 'First Visit'},
      ],
    );

    expect(progress.totalPoints, 45 + 6 * adminVisitXpPerPlace);
    expect(progress.badges.map((badge) => (badge as Map)['id']), [
      'visit_milestone_1',
      'visit_milestone_5',
      'visit_milestone_10',
    ]);
    expect(progress.newlyUnlocked.map((badge) => badge['id']), [
      'visit_milestone_5',
      'visit_milestone_10',
    ]);
  });

  test('removing visits reduces visit XP without revoking earned badges', () {
    final progress = calculateVisitProgress(
      currentPoints: 100,
      previousPlaceCount: 5,
      placeCount: 2,
      currentBadges: const [
        {'id': 'visit_milestone_1', 'name': 'First Visit'},
        {'id': 'visit_milestone_5', 'name': 'Place Explorer'},
      ],
    );

    expect(progress.totalPoints, 100 - 3 * adminVisitXpPerPlace);
    expect(progress.badges, hasLength(2));
    expect(progress.newlyUnlocked, isEmpty);
  });

  test('visit XP never becomes negative', () {
    final progress = calculateVisitProgress(
      currentPoints: 0,
      previousPlaceCount: 5,
      placeCount: 0,
      currentBadges: const [],
    );

    expect(progress.totalPoints, 0);
    expect(progress.badges, isEmpty);
  });

  test('fallback sync awards XP and the 50-visit badge for new places', () {
    final progress = calculateVisitProgress(
      currentPoints: 0,
      previousPlaceCount: 0,
      placeCount: 50,
      currentBadges: const [],
    );

    expect(progress.totalPoints, 50 * adminVisitXpPerPlace);
    expect(progress.newlyUnlocked.map((badge) => badge['id']), [
      'visit_milestone_1',
      'visit_milestone_5',
      'visit_milestone_10',
      'visit_milestone_25',
      'visit_milestone_50',
    ]);
  });
}
