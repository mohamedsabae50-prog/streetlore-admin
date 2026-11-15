import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/governorates_config.dart';
import '../models/models.dart';

bool _isCommonsImageUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'upload.wikimedia.org' &&
      uri.path.startsWith('/wikipedia/commons/');
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
    final aswanPlaces = places
        .where((place) => place.governorate == 'aswan')
        .toList(growable: false);
    final aswanTours = tours
        .where((tour) => tour.governorate == 'aswan')
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
    final aswanTourImages = aswanTours.map((tour) => tour.imageUrl).toSet();
    if (places.length != 355 ||
        tours.length != 32 ||
        allPrimaryImages.length != places.length ||
        places.any((place) => !_isCommonsImageUrl(place.imageUrl)) ||
        atms.length != 38 ||
        atms.where((place) => place.governorate == 'alexandria').length != 6 ||
        atms.where((place) => place.governorate == 'cairo').length != 20 ||
        atms.where((place) => place.governorate == 'luxor').length != 6 ||
        atms.where((place) => place.governorate == 'aswan').length != 6 ||
        atms.any((place) => !_isCommonsImageUrl(place.imageUrl)) ||
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
        ) ||
        aswanPlaces.length != 60 ||
        aswanPlaces.where((place) => !place.isAtm).length != 54 ||
        aswanPlaces.where((place) => place.isAtm).length != 6 ||
        visitEligiblePlaces(aswanPlaces).length != 54 ||
        aswanPlaces.any(
          (place) =>
              !_isCommonsImageUrl(place.imageUrl) ||
              place.imageUrls.any((image) => !_isCommonsImageUrl(image)) ||
              !place.imageUrls.contains(place.imageUrl) ||
              !isPointInGovernorate(place.lat, place.lng, 'aswan'),
        ) ||
        aswanPlaces.map((place) => place.imageUrl).toSet().length !=
            aswanPlaces.length ||
        aswanTours.length != 6 ||
        aswanTours.any(
          (tour) =>
              !_isCommonsImageUrl(tour.imageUrl) ||
              tour.places.isEmpty ||
              tour.places.any((place) => place.governorate != 'aswan'),
        ) ||
        aswanTourImages.length != aswanTours.length ||
        aswanTourImages
            .intersection(aswanPlaces.map((place) => place.imageUrl).toSet())
            .isNotEmpty) {
      throw StateError(
        'The preview seed must contain 355 places and 32 tours, including '
        '38 ATMs across four governorates and 60 in-boundary Aswan places '
        'plus 6 Aswan tours with unique upload.wikimedia.org images.',
      );
    }
    return (places: places, tours: tours);
  }
}
