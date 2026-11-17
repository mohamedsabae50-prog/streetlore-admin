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
    final alexandriaPlaces = places
        .where((place) => place.governorate == 'alexandria')
        .toList(growable: false);
    final redSeaPlaces = places
        .where((place) => place.governorate == 'red_sea')
        .toList(growable: false);
    final redSeaTours = tours
        .where((tour) => tour.governorate == 'red_sea')
        .toList(growable: false);
    final newAlexandriaPlaces = alexandriaPlaces
        .where((place) => place.id.startsWith('alexandria_'))
        .toList(growable: false);
    const westernAlexandriaPlaceIds = {
      'alex_bitash_palm_beach_promenade',
      'alex_hannoville_coral_bay_beach',
      'alex_abu_talat_seafront_lagoon',
      'alex_sidi_kreir_white_dunes_beach',
      'alex_dekheila_harbour_seafood_terrace',
      'alex_agami_marina_specialty_cafe',
      'alex_lake_mariout_west_bird_sanctuary',
      'alex_marea_ancient_lakeport_ruins',
      'alex_amreya_heritage_bedouin_souq',
      'alex_king_mariout_palm_country_club',
      'alex_king_mariout_bedouin_mandi_house',
      'alex_borg_el_arab_international_stadium_park',
      'alex_new_borg_el_arab_central_park',
      'alex_new_borg_el_arab_city_center_mall',
      'alex_new_borg_el_arab_grand_mosque',
    };
    final westernAlexandriaPlaces = alexandriaPlaces
        .where((place) => westernAlexandriaPlaceIds.contains(place.id))
        .toList(growable: false);
    final primaryImages = cairoPlaces.map((place) => place.imageUrl).toSet();
    final allPrimaryImages = places.map((place) => place.imageUrl).toSet();
    final decodedImagePaths = places
        .map((place) => Uri.tryParse(place.imageUrl)?.path)
        .whereType<String>()
        .map(Uri.decodeComponent)
        .toSet();
    final atms = atmPlaces(places);
    final luxorTourImages = luxorTours.map((tour) => tour.imageUrl).toSet();
    if (places.length != 442 ||
        tours.length != 39 ||
        visitEligiblePlaces(places).length != 398 ||
        allPrimaryImages.length != places.length ||
        decodedImagePaths.length != places.length ||
        places.any((place) => !_isCommonsImageUrl(place.imageUrl)) ||
        atms.length != 44 ||
        atms.where((place) => place.governorate == 'alexandria').length != 6 ||
        atms.where((place) => place.governorate == 'cairo').length != 20 ||
        atms.where((place) => place.governorate == 'luxor').length != 12 ||
        atms.where((place) => place.governorate == 'red_sea').length != 6 ||
        alexandriaPlaces.length != 77 ||
        visitEligiblePlaces(alexandriaPlaces).length != 71 ||
        atms.any((place) => !_isCommonsImageUrl(place.imageUrl)) ||
        cairoPlaces.length < 120 ||
        cairoTours.length < 5 ||
        luxorPlaces.length != 124 ||
        luxorTours.length != 12 ||
        redSeaPlaces.length != 60 ||
        visitEligiblePlaces(redSeaPlaces).length != 54 ||
        redSeaTours.length != 6 ||
        redSeaPlaces.map((place) => place.imageUrl).toSet().length != 60 ||
        redSeaPlaces.any(
          (place) =>
              !place.imageUrls.contains(place.imageUrl) ||
              !isPointInGovernorate(place.lat, place.lng, place.governorate),
        ) ||
        redSeaTours.any(
          (tour) =>
              tour.places.isEmpty ||
              tour.places.any(
                (place) =>
                    place.governorate != 'red_sea' ||
                    !isPointInGovernorate(
                      place.lat,
                      place.lng,
                      place.governorate,
                    ),
              ),
        ) ||
        primaryImages.length != cairoPlaces.length ||
        cairoPlaces.any(
          (place) =>
              !isPointInGovernorate(place.lat, place.lng, place.governorate),
        ) ||
        alexandriaPlaces.any(
          (place) => !isPointInGovernorateOrExpandedBounds(
            place.lat,
            place.lng,
            place.governorate,
            expansionKm: 6,
          ),
        ) ||
        newAlexandriaPlaces.length != 10 ||
        newAlexandriaPlaces.map((place) => place.imageUrl).toSet().length !=
            10 ||
        westernAlexandriaPlaces.length != westernAlexandriaPlaceIds.length ||
        westernAlexandriaPlaces.any(
          (place) =>
              !_isCommonsImageUrl(place.imageUrl) ||
              !place.imageUrls.contains(place.imageUrl) ||
              !isPointInGovernorate(place.lat, place.lng, place.governorate),
        ) ||
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
              !place.imageUrls.contains(place.imageUrl) ||
              Uri.parse(place.imageUrl).host != 'upload.wikimedia.org' ||
              !isPointInGovernorate(place.lat, place.lng, place.governorate);
        }) ||
        luxorPlaces.map((place) => place.imageUrl).toSet().length !=
            luxorPlaces.length ||
        luxorPlaces.where((place) => !place.isAtm).length != 112 ||
        luxorPlaces.where((place) => place.isAtm).length != 12 ||
        visitEligiblePlaces(luxorPlaces).length != 112 ||
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
              tour.places.any(
                (place) =>
                    place.governorate != 'luxor' ||
                    !isPointInGovernorate(
                      place.lat,
                      place.lng,
                      place.governorate,
                    ),
              ),
        ) ||
        luxorTours.any((tour) => !_isCommonsImageUrl(tour.imageUrl)) ||
        luxorTourImages
            .intersection(luxorPlaces.map((place) => place.imageUrl).toSet())
            .isNotEmpty) {
      throw StateError(
        'The preview seed must contain 442 places and 39 tours, including '
        '44 ATMs and 398 visitable places across four governorates, with '
        '71 Alexandria visitable places, 60 Red Sea places, six Red Sea '
        'tours, and unique upload.wikimedia.org place image paths.',
      );
    }
    return (places: places, tours: tours);
  }
}
