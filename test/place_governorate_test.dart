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
    expect(AdminGovernorate.all, hasLength(2));
    expect(AdminGovernorate.all.map((item) => item.id).toSet(), {
      'alexandria',
      'cairo',
    });
    expect(AdminGovernorate.all.first.nameEn, 'Alexandria');
    expect(AdminGovernorate.all.first.nameAr, 'الإسكندرية');
  });
}
