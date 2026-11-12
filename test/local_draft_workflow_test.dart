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
      expect(initialPlaces, hasLength(76));
      expect(initialTours, hasLength(7));

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
      await service.createPlace(place);
      await service.updatePlace(place.copyWith(name: 'Edited Cairo Draft'));
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
