import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/models.dart';
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

  test('Luxor visit and badge counts exclude all six ATMs', () {
    final luxorPlaces = [
      for (var index = 0; index < 54; index++)
        Place(
          id: 'luxor_place_$index',
          name: 'Luxor place $index',
          description: '',
          imageUrl: '',
          rating: 0,
          category: 'Historical',
          lat: 25.7050,
          lng: 32.6391,
          governorate: 'luxor',
        ),
      for (var index = 0; index < 6; index++)
        Place(
          id: 'atm_luxor_$index',
          name: 'Luxor ATM $index',
          description: '',
          imageUrl: '',
          rating: 0,
          category: 'ATMs',
          lat: 25.7050,
          lng: 32.6391,
          governorate: 'luxor',
        ),
    ];
    final eligible = visitEligiblePlaces(luxorPlaces);
    final progress = calculateVisitProgress(
      currentPoints: 0,
      previousPlaceCount: 0,
      placeCount: eligible.length,
      currentBadges: const [],
    );

    expect(eligible, hasLength(54));
    expect(eligible.any((place) => place.isAtm), isFalse);
    expect(progress.totalPoints, 54 * adminVisitXpPerPlace);
    expect(
      progress.badges.map((badge) => (badge as Map)['id']),
      contains('visit_milestone_50'),
    );
    expect(
      progress.badges.map((badge) => (badge as Map)['id']),
      isNot(contains('visit_milestone_100')),
    );
  });

  test('Aswan visit and badge counts exclude all six ATMs', () {
    final aswanPlaces = [
      for (var index = 0; index < 54; index++)
        Place(
          id: 'aswan_place_$index',
          name: 'Aswan place $index',
          description: '',
          imageUrl: '',
          rating: 0,
          category: 'Historical',
          lat: 24.0889,
          lng: 32.8998,
          governorate: 'aswan',
        ),
      for (var index = 0; index < 6; index++)
        Place(
          id: 'atm_aswan_$index',
          name: 'Aswan ATM $index',
          description: '',
          imageUrl: '',
          rating: 0,
          category: 'ATMs',
          lat: 24.0889,
          lng: 32.8998,
          governorate: 'aswan',
        ),
    ];
    final eligible = visitEligiblePlaces(aswanPlaces);
    final progress = calculateVisitProgress(
      currentPoints: 0,
      previousPlaceCount: 0,
      placeCount: eligible.length,
      currentBadges: const [],
    );

    expect(eligible, hasLength(54));
    expect(atmPlaces(aswanPlaces), hasLength(6));
    expect(eligible.any((place) => place.isAtm), isFalse);
    expect(progress.totalPoints, 54 * adminVisitXpPerPlace);
  });
}
