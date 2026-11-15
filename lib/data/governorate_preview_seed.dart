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
    final luxorPlaces = places
        .where((place) => place.governorate == 'luxor')
        .toList(growable: false);
    final luxorTours = tours
        .where((tour) => tour.governorate == 'luxor')
        .toList(growable: false);
    final alexandriaPlaces = places
        .where((place) => place.governorate == 'alexandria')
        .toList(growable: false);
    final newAlexandriaPlaces = alexandriaPlaces
        .where((place) => place.id.startsWith('alexandria_'))
        .toList(growable: false);
    final primaryImages = cairoPlaces.map((place) => place.imageUrl).toSet();
    final allPrimaryImages = places.map((place) => place.imageUrl).toSet();
    final atms = atmPlaces(places);
    final luxorTourImages = luxorTours.map((tour) => tour.imageUrl).toSet();
    if (places.length != 295 ||
        tours.length != 26 ||
        allPrimaryImages.length != places.length ||
        atms.length != 32 ||
        atms.where((place) => place.governorate == 'alexandria').length != 6 ||
        atms.where((place) => place.governorate == 'cairo').length != 20 ||
        atms.where((place) => place.governorate == 'luxor').length != 6 ||
        atms.any(
          (place) =>
              !_isCommonsImageUrl(place.imageUrl) ||
              Uri.parse(place.imageUrl).host != 'upload.wikimedia.org',
        ) ||
        cairoPlaces.length < 120 ||
        cairoTours.length < 5 ||
        luxorPlaces.length != 60 ||
        luxorTours.length != 6 ||
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
        }) ||
        luxorPlaces.any((place) {
          return !_isCommonsImageUrl(place.imageUrl) ||
              place.imageUrls.any((image) => !_isCommonsImageUrl(image)) ||
              Uri.parse(place.imageUrl).host != 'upload.wikimedia.org' ||
              !isPointInGovernorate(place.lat, place.lng, place.governorate);
        }) ||
        luxorPlaces.map((place) => place.imageUrl).toSet().length !=
            luxorPlaces.length ||
        luxorTours.any(
          (tour) =>
              !_isCommonsImageUrl(tour.imageUrl) ||
              Uri.parse(tour.imageUrl).host != 'upload.wikimedia.org',
        ) ||
        luxorTourImages.length != luxorTours.length ||
        luxorTourImages
            .intersection(luxorPlaces.map((place) => place.imageUrl).toSet())
            .isNotEmpty ||
        luxorTours.any(
          (tour) =>
              tour.places.isEmpty ||
              tour.places.any((place) => place.governorate != 'luxor'),
        )) {
      throw StateError(
        'The preview seed must contain 295 places and 26 tours, including '
        '32 ATMs across the three governorates and 60 in-boundary Luxor '
        'places plus 6 Luxor tours with unique HTTPS Commons images.',
      );
    }
    return (places: places, tours: tours);
  }
}
