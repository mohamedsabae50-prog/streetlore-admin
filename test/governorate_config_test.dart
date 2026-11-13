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
    expect(cairoGovernorate.boundaryPolygon, hasLength(17));
    expect(AdminGovernorate.all, hasLength(2));
    expect(
      AdminGovernorate.all
          .singleWhere((governorate) => governorate.id == 'cairo')
          .boundaryPolygon,
      cairoGovernorate.boundaryPolygon,
    );
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
    'expanded validation includes nearby edges but excludes distant areas',
    () {
      expect(
        isPointInGovernorateOrExpandedBounds(30.17, 31.4, 'cairo'),
        isTrue,
      );
      expect(
        isPointInGovernorateOrExpandedBounds(29.9792, 31.1342, 'cairo'),
        isFalse,
      );
      expect(isPointInGovernorateOrExpandedBounds(0, 0, 'unknown'), isFalse);
    },
  );

  test(
    'preview asset includes all Cairo and Alexandria places and tours',
    () async {
      final seed = await GovernoratePreviewSeed.load();

      expect(
        seed.places.where((place) => place.governorate == 'cairo'),
        hasLength(greaterThanOrEqualTo(120)),
      );
      expect(
        seed.places.where((place) => place.governorate == 'alexandria'),
        hasLength(42),
      );
      expect(
        seed.tours.where((tour) => tour.governorate == 'cairo'),
        hasLength(greaterThanOrEqualTo(10)),
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
      final cairoPlaces = seed.places
          .where((place) => place.governorate == 'cairo')
          .toList(growable: false);
      expect(
        cairoPlaces.map((place) => place.id),
        containsAll({
          'mosque_muhammad_ali',
          'qasr_el_nil_bridge',
          'ben_ezra_synagogue',
          'babylon_fortress',
          'mahmoud_mukhtar_museum',
          'al_gawhara_palace',
          'sultan_al_ghuri_complex',
        }),
      );
      expect(
        cairoPlaces.map((place) => place.imageUrl).toSet(),
        hasLength(cairoPlaces.length),
      );
      expect(
        cairoPlaces.every(
          (place) =>
              Uri.tryParse(place.imageUrl)?.scheme == 'https' &&
              Uri.tryParse(place.imageUrl)?.host == 'upload.wikimedia.org',
        ),
        isTrue,
      );
      expect(
        seed.tours.map((tour) => tour.id),
        containsAll({
          'cairo_citadel_mosque_palace',
          'cairo_coptic_cairo_heritage',
          'cairo_nile_bridge_and_art',
          'cairo_mamluk_al_muizz_route',
          'cairo_old_cairo_and_citadel',
        }),
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
