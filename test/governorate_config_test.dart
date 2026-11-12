import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/data/governorate_preview_seed.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/governorates_config.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('config contains the app-matched Alexandria and Cairo boundaries', () {
    expect(governoratesConfig.keys.toSet(), {'alexandria', 'cairo'});
    expect(alexandriaGovernorate.centerLat, 31.2001);
    expect(alexandriaGovernorate.centerLng, 29.9187);
    expect(alexandriaGovernorate.defaultZoom, 11);
    expect(cairoGovernorate.centerLat, 30.0444);
    expect(cairoGovernorate.centerLng, 31.2357);
    expect(cairoGovernorate.defaultZoom, 11);
    expect(alexandriaGovernorate.boundaryPolygon, hasLength(20));
    expect(cairoGovernorate.boundaryPolygon, hasLength(12));
    expect(AdminGovernorate.all, hasLength(2));
  });

  test('point validation rejects the Giza controls and wrong city', () {
    expect(isPointInGovernorate(30.0444, 31.2357, 'cairo'), isTrue);
    expect(isPointInGovernorate(31.2001, 29.9187, 'alexandria'), isTrue);
    expect(isPointInGovernorate(29.9792, 31.1342, 'cairo'), isFalse);
    expect(isPointInGovernorate(30.0385, 31.2118, 'cairo'), isFalse);
    expect(isPointInGovernorate(31.2001, 29.9187, 'cairo'), isFalse);
    expect(isPointInGovernorate(30.0444, 31.2357, 'alexandria'), isFalse);
    expect(isPointInGovernorate(0, 0, 'giza'), isFalse);
  });

  test(
    'preview asset includes all Cairo and Alexandria places and tours',
    () async {
      final seed = await GovernoratePreviewSeed.load();

      expect(
        seed.places.where((place) => place.governorate == 'cairo'),
        hasLength(34),
      );
      expect(
        seed.places.where((place) => place.governorate == 'alexandria'),
        hasLength(42),
      );
      expect(
        seed.tours.where((tour) => tour.governorate == 'cairo'),
        hasLength(2),
      );
      expect(
        seed.tours.where((tour) => tour.governorate == 'alexandria'),
        hasLength(5),
      );
      expect(
        seed.places
            .where((place) => place.governorate == 'cairo')
            .every(
              (place) =>
                  isPointInGovernorate(place.lat, place.lng, place.governorate),
            ),
        isTrue,
      );
      for (final tour in seed.tours.where(
        (tour) => tour.governorate == 'cairo',
      )) {
        expect(tour.places, isNotEmpty);
        expect(
          tour.places.every((place) => place.governorate == 'cairo'),
          isTrue,
        );
      }
    },
  );

  test(
    'legacy tour rows default to Alexandria without a governorate field',
    () {
      final tour = Tour.fromJson(const {
        'id': 'legacy-tour',
        'title': 'Legacy tour',
        'description': 'Legacy description',
        'duration': '2 Hours',
        'image_url': '',
      });

      expect(tour.governorate, 'alexandria');
      expect(tour.toJson()['governorate'], 'alexandria');
      expect(tour.toSupabaseUpdate()['governorate'], 'alexandria');
    },
  );
}
