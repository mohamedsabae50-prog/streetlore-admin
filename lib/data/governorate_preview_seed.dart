import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/governorates_config.dart';
import '../models/models.dart';

bool _isCommonsImageUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      const {'upload.wikimedia.org', 'thumb.wikimedia.org'}.contains(uri.host);
}

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

    final cairoPlaces = places
        .where((place) => place.governorate == 'cairo')
        .toList(growable: false);
    final cairoTours = tours
        .where((tour) => tour.governorate == 'cairo')
        .toList(growable: false);
    final alexandriaPlaces = places
        .where((place) => place.governorate == 'alexandria')
        .toList(growable: false);
    final newAlexandriaPlaces = alexandriaPlaces
        .where((place) => place.id.startsWith('alexandria_'))
        .toList(growable: false);
    final primaryImages = cairoPlaces.map((place) => place.imageUrl).toSet();
    if (cairoPlaces.length < 120 ||
        cairoTours.length < 5 ||
        primaryImages.length != cairoPlaces.length ||
        cairoPlaces.any(
          (place) =>
              !isPointInGovernorate(place.lat, place.lng, place.governorate),
        ) ||
        alexandriaPlaces.any(
          (place) =>
              !isPointInGovernorate(place.lat, place.lng, place.governorate),
        ) ||
        newAlexandriaPlaces.length != 10 ||
        newAlexandriaPlaces.map((place) => place.imageUrl).toSet().length !=
            10 ||
        cairoPlaces.any((place) {
          return !_isCommonsImageUrl(place.imageUrl) ||
              place.imageUrls.any((image) => !_isCommonsImageUrl(image));
        }) ||
        newAlexandriaPlaces.any((place) {
          return !_isCommonsImageUrl(place.imageUrl);
        })) {
      throw StateError(
        'The unified Cairo seed must contain at least 120 places and 5 tours, '
        'with in-boundary coordinates and unique HTTPS Wikimedia images.',
      );
    }
    return (places: places, tours: tours);
  }
}
