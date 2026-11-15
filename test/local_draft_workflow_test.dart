import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlore_admin/models/models.dart';
import 'package:streetlore_admin/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdminService.localDraftMode.value = true;
  });

  test(
    'local preview creates, edits, and deletes place and tour drafts',
    () async {
      final service = AdminService.instance;
      final initialPlaces = await service.fetchPlaces();
      final initialTours = await service.fetchTours();
      expect(initialPlaces, hasLength(289));
      expect(initialTours, hasLength(26));
      expect(
        initialPlaces.map((place) => place.id),
        containsAll({
          'giza_great_pyramid',
          'giza_grand_egyptian_museum',
          'alexandria_cavafy_museum',
        }),
      );

      final place = Place(
        id: 'draft_cairo_test_place',
        name: 'Local Cairo Draft',
        nameAr: 'مسودة محلية للقاهرة',
        description: 'Local-only preview record.',
        imageUrl: '',
        rating: 4.5,
        category: 'Historical',
        lat: 30.0444,
        lng: 31.2357,
        governorate: 'cairo',
      );
      expect((await service.createPlace(place)).remoteSynced, isFalse);
      expect(
        (await service.updatePlace(
          place.copyWith(name: 'Edited Cairo Draft'),
        )).remoteSynced,
        isFalse,
      );
      expect(
        (await service.fetchPlaces())
            .singleWhere((candidate) => candidate.id == place.id)
            .name,
        'Edited Cairo Draft',
      );

      final tour = Tour(
        id: 'draft_cairo_test_tour',
        title: 'Local Cairo Tour',
        description: 'Local-only preview itinerary.',
        duration: '2 Hours',
        imageUrl: '',
        governorate: 'cairo',
        places: [place],
      );
      await service.createTour(tour);
      expect(
        (await service.fetchTours())
            .singleWhere((candidate) => candidate.id == tour.id)
            .governorate,
        'cairo',
      );

      await service.deletePlace(place.id);
      await service.deleteTour(tour.id);
      expect(
        (await service.fetchPlaces()).any(
          (candidate) => candidate.id == place.id,
        ),
        isFalse,
      );
      expect(
        (await service.fetchTours()).any(
          (candidate) => candidate.id == tour.id,
        ),
        isFalse,
      );
    },
  );

  test('local preview creates and edits Luxor place and tour drafts', () async {
    final service = AdminService.instance;
    final place = Place(
      id: 'draft_luxor_test_place',
      name: 'Local Luxor Draft',
      nameAr: 'مسودة محلية للأقصر',
      description: 'Local-only Luxor preview record.',
      imageUrl: '',
      rating: 4.5,
      category: 'Historical',
      lat: 25.7050,
      lng: 32.6391,
      governorate: 'luxor',
    );

    expect((await service.createPlace(place)).remoteSynced, isFalse);
    await service.updatePlace(place.copyWith(name: 'Edited Luxor Draft'));
    expect(
      (await service.fetchPlaces())
          .singleWhere((candidate) => candidate.id == place.id)
          .governorate,
      'luxor',
    );

    final tour = Tour(
      id: 'draft_luxor_test_tour',
      title: 'Local Luxor Tour',
      description: 'Local-only Luxor itinerary.',
      duration: '2 Hours',
      imageUrl: '',
      governorate: 'luxor',
      places: [place],
    );
    await service.createTour(tour);
    expect(
      (await service.fetchTours())
          .singleWhere((candidate) => candidate.id == tour.id)
          .governorate,
      'luxor',
    );

    await service.deletePlace(place.id);
    await service.deleteTour(tour.id);
  });

  test('local mode rejects image uploads before contacting Supabase', () async {
    await expectLater(
      AdminService.instance.uploadImageBytes(
        Uint8List.fromList([1]),
        'places',
        'draft.jpg',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
