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

    final cairoPlaces = places
        .where((place) => place.governorate == 'cairo')
        .toList(growable: false);
    final cairoTours = tours
        .where((tour) => tour.governorate == 'cairo')
        .toList(growable: false);
    final primaryImages = cairoPlaces.map((place) => place.imageUrl).toSet();
    if (cairoPlaces.length != 120 ||
        cairoTours.length != 5 ||
        primaryImages.length != cairoPlaces.length ||
        cairoPlaces.any((place) {
          final uri = Uri.tryParse(place.imageUrl);
          return uri == null ||
              uri.scheme != 'https' ||
              uri.host != 'upload.wikimedia.org' ||
              place.imageUrls.any((image) {
                final imageUri = Uri.tryParse(image);
                return imageUri == null ||
                    imageUri.scheme != 'https' ||
                    imageUri.host != 'upload.wikimedia.org';
              });
        })) {
      throw StateError(
        'The Cairo seed must contain 120 places with unique HTTPS Wikimedia '
        'images and 5 itineraries.',
      );
    }
    return (places: places, tours: tours);
  }
}
