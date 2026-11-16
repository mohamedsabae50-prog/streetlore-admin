import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  test('Place governorate defaults to Alexandria for legacy rows', () {
    final place = Place.fromJson(const {
      'id': 'legacy-place',
      'name': 'Legacy',
    });

    expect(place.governorate, 'alexandria');
    expect(place.toJson()['governorate'], 'alexandria');
    expect(place.toSupabaseUpdate()['governorate'], 'alexandria');
  });

  test('legacy Giza governorate values normalize to Cairo', () {
    final place = Place.fromJson(const {
      'id': 'giza-place',
      'name': 'Giza place',
      'governorate': ' GIZA ',
    });
    final tour = Tour.fromJson(const {
      'id': 'giza-tour',
      'title': 'Giza tour',
      'description': '',
      'duration': '',
      'image_url': '',
      'governorate': 'giza',
    });

    expect(place.governorate, 'cairo');
    expect(place.toJson()['governorate'], 'cairo');
    expect(tour.governorate, 'cairo');
    expect(tour.toSupabaseUpdate()['governorate'], 'cairo');
  });

  test('missing governorate is inferred from coordinates', () {
    final luxorPlace = Place.fromJson(const {
      'id': 'coordinate-luxor-place',
      'name': 'Luxor place',
      'lat': 25.7050,
      'lng': 32.6391,
    });

    expect(Place.inferGovernorate(lat: 25.7050, lng: 32.6391), 'luxor');
    expect(luxorPlace.governorate, 'luxor');
    expect(luxorPlace.toJson()['governorate'], 'luxor');
  });

  test('legacy Aswan values normalize to Luxor & Aswan', () {
    final place = Place.fromJson(const {
      'id': 'coordinate-aswan-place',
      'name': 'Philae Temple',
      'lat': 24.0254,
      'lng': 32.8842,
      'governorate': ' أسوان ',
    });
    final tour = Tour.fromJson(const {
      'id': 'aswan-tour',
      'title': 'Aswan tour',
      'description': '',
      'duration': '',
      'image_url': '',
      'governorate': 'أسوان',
    });

    expect(Place.inferGovernorate(lat: 24.0254, lng: 32.8842), 'luxor');
    expect(place.governorate, 'luxor');
    expect(place.toJson()['governorate'], 'luxor');
    expect(place.toSupabaseUpdate()['governorate'], 'luxor');
    expect(tour.governorate, 'luxor');
    expect(tour.toJson()['governorate'], 'luxor');
    expect(tour.toSupabaseUpdate()['governorate'], 'luxor');
    expect(AdminGovernorate.normalizeId('aswan'), 'luxor');
  });

  test('ATM places remain places but are not visit-eligible', () {
    final places = [
      Place(
        id: 'atm_bank_branch',
        name: 'ATM',
        description: '',
        imageUrl: '',
        rating: 0,
        category: 'Historical',
        lat: 0,
        lng: 0,
      ),
      Place(
        id: 'place_atm_category',
        name: 'Cash machine',
        description: '',
        imageUrl: '',
        rating: 0,
        category: 'aTmS',
        lat: 0,
        lng: 0,
      ),
      Place(
        id: 'place_historical',
        name: 'Museum',
        description: '',
        imageUrl: '',
        rating: 0,
        category: 'Historical',
        lat: 0,
        lng: 0,
      ),
    ];

    expect(places.map((place) => place.isAtm), [true, true, false]);
    expect(visitEligiblePlaces(places).map((place) => place.id), [
      'place_historical',
    ]);
    expect(places[0].toJson()['category'], 'Historical');
    expect(places[1].toJson()['category'], 'aTmS');
  });

  test('admin governorate choices match configured coverage', () {
    expect(AdminGovernorate.all, hasLength(4));
    expect(AdminGovernorate.all.map((item) => item.id).toSet(), {
      'alexandria',
      'cairo',
      'luxor',
      'red_sea',
    });
    expect(AdminGovernorate.all.first.nameEn, 'Alexandria');
    expect(AdminGovernorate.all.first.nameAr, 'الإسكندرية');
  });

  test('legacy Red Sea city values normalize on places and tours', () {
    final hurghadaPlace = Place.fromJson(const {
      'id': 'hurghada-place',
      'name': 'Hurghada place',
      'governorate': 'hurghada',
    });
    final marsaAlamTour = Tour.fromJson(const {
      'id': 'marsa-alam-tour',
      'title': 'Marsa Alam tour',
      'description': '',
      'duration': '',
      'image_url': '',
      'governorate': 'marsa_alam',
    });

    expect(hurghadaPlace.governorate, 'red_sea');
    expect(hurghadaPlace.toJson()['governorate'], 'red_sea');
    expect(marsaAlamTour.governorate, 'red_sea');
    expect(marsaAlamTour.toSupabaseUpdate()['governorate'], 'red_sea');
  });
}
