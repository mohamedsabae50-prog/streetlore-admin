// This deterministic policy is only used when the canonical Edge sync fails.
const adminVisitXpPerPlace = 10;

const _visitMilestones = <({int threshold, String id, String name})>[
  (threshold: 1, id: 'visit_milestone_1', name: 'First Visit'),
  (threshold: 5, id: 'visit_milestone_5', name: 'Place Explorer'),
  (threshold: 10, id: 'visit_milestone_10', name: 'City Guide'),
  (threshold: 25, id: 'visit_milestone_25', name: 'Heritage Seeker'),
  (threshold: 50, id: 'visit_milestone_50', name: 'Pathfinder'),
  (threshold: 100, id: 'visit_milestone_100', name: 'Landmark Collector'),
];

class VisitProgress {
  const VisitProgress({
    required this.totalPoints,
    required this.badges,
    required this.newlyUnlocked,
  });

  final int totalPoints;
  final List<dynamic> badges;
  final List<Map<String, String>> newlyUnlocked;
}

VisitProgress calculateVisitProgress({
  required int currentPoints,
  required int previousPlaceCount,
  required int placeCount,
  required List<dynamic> currentBadges,
}) {
  final adjustedPoints =
      currentPoints + (placeCount - previousPlaceCount) * adminVisitXpPerPlace;
  final badges = List<dynamic>.from(currentBadges);
  final knownBadgeIds = <String>{};
  for (final badge in currentBadges) {
    if (badge is String) {
      knownBadgeIds.add(badge);
    } else if (badge is Map && badge['id'] is String) {
      knownBadgeIds.add(badge['id'] as String);
    }
  }
  final newlyUnlocked = <Map<String, String>>[];

  for (final milestone in _visitMilestones) {
    if (placeCount < milestone.threshold || !knownBadgeIds.add(milestone.id)) {
      continue;
    }
    final badge = {'id': milestone.id, 'name': milestone.name};
    badges.add(badge);
    newlyUnlocked.add(badge);
  }

  return VisitProgress(
    totalPoints: adjustedPoints < 0 ? 0 : adjustedPoints,
    badges: badges,
    newlyUnlocked: newlyUnlocked,
  );
}
