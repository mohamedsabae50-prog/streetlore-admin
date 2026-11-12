import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

class GovernoratePreviewSeed {
  const GovernoratePreviewSeed._();

  static Future<({List<Place> places, List<Tour> tours})> load() async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/governorate_preview_seed.json'),
    );
    if (decoded is! Map<String, dynamic> ||
        decoded['places'] is! List ||
        decoded['tours'] is! List) {
      throw const FormatException('Invalid local governorate preview seed.');
    }

    final places = (decoded['places'] as List)
        .map((row) => Place.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final tours = (decoded['tours'] as List)
        .map((row) => Tour.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);

    if (places.where((place) => place.governorate == 'cairo').length != 34 ||
        tours.where((tour) => tour.governorate == 'cairo').length != 2) {
      throw StateError(
        'The local Cairo preview must contain 34 places and 2 itineraries.',
      );
    }
    return (places: places, tours: tours);
  }
}
