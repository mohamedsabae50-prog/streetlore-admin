import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  Map<String, dynamic> suggestionJson({
    required String type,
    required bool isHiddenGem,
    required int rewardDays,
  }) => {
    'id': 'suggestion-id',
    'user_id': 'user-id',
    'title': 'Suggested place',
    'name_ar': 'مكان مقترح',
    'description': 'A suggested place',
    'category': 'Historical',
    'category_ar': 'تاريخي',
    'lat': 31.2,
    'lng': 29.9,
    'address': 'Alexandria',
    'status': 'pending',
    'suggestion_type': type,
    'is_hidden_gem': isHiddenGem,
    'reward_days': rewardDays,
    'created_at': '2026-11-16T10:00:00Z',
  };

  test('parses a regular place suggestion with a 7-day Pro reward', () {
    final suggestion = SuggestedPlace.fromJson(
      suggestionJson(type: 'regular', isHiddenGem: false, rewardDays: 7),
    );

    expect(suggestion.type, PlaceSuggestionType.regular);
    expect(suggestion.isHiddenGem, isFalse);
    expect(suggestion.rewardDays, 7);
    expect(suggestion.typeLabel, 'Regular Place · مكان عادي');
    expect(
      suggestion.rewardLabel,
      'Reward: 7 Days Free Pro (أسبوع Pro مجاناً)',
    );

    final publishedPlace = suggestion.toPlace(isHiddenGem: false);
    expect(publishedPlace.id, suggestion.id);
    expect(publishedPlace.isHiddenGem, isFalse);
  });

  test('parses a hidden gem suggestion with a 30-day Pro reward', () {
    final suggestion = SuggestedPlace.fromJson(
      suggestionJson(type: 'hidden_gem', isHiddenGem: true, rewardDays: 30),
    );

    expect(suggestion.type, PlaceSuggestionType.hiddenGem);
    expect(suggestion.isHiddenGem, isTrue);
    expect(suggestion.rewardDays, 30);
    expect(suggestion.typeLabel, 'Hidden Gem · جوهرة مخفية');
    expect(suggestion.rewardLabel, 'Reward: 30 Days Free Pro (شهر Pro مجاناً)');

    final publishedPlace = suggestion.toPlace(isHiddenGem: true);
    expect(publishedPlace.id, suggestion.id);
    expect(publishedPlace.isHiddenGem, isTrue);
  });

  test('normalizes reward days when approval type is changed', () {
    final suggestion = SuggestedPlace.fromJson(
      suggestionJson(type: 'regular', isHiddenGem: false, rewardDays: 7),
    );

    final approvedAsGem = suggestion.copyWith(
      type: PlaceSuggestionType.hiddenGem,
    );

    expect(approvedAsGem.rewardDays, 30);
    expect(
      approvedAsGem.toPlace(isHiddenGem: approvedAsGem.isHiddenGem).isHiddenGem,
      isTrue,
    );
  });
}
