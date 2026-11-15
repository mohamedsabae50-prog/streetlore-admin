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
      expect(initialPlaces, hasLength(355));
      expect(initialTours, hasLength(32));
      expect(
        initialPlaces.map((place) => place.id),
        containsAll({
          'giza_great_pyramid',
          'giza_grand_egyptian_museum',
          'alexandria_cavafy_museum',
          'aswan_philae_temple',
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

  test('initializes local draft mode from the saved preference', () async {
    SharedPreferences.setMockInitialValues({
      'streetlore-admin-local-draft-mode': true,
    });
    AdminService.localDraftMode.value = false;

    await AdminService.instance.initializeLocalDraftMode();

    expect(AdminService.instance.isLocalDraftMode, isTrue);
  });

  test('setLocalDraftMode persists the selected preference', () async {
    final service = AdminService.instance;

    await service.setLocalDraftMode(true);
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.getBool('streetlore-admin-local-draft-mode'), isTrue);
    expect(service.isLocalDraftMode, isTrue);
  });

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

  test('local preview creates and edits Aswan place and tour drafts', () async {
    final service = AdminService.instance;
    final place = Place(
      id: 'draft_aswan_test_place',
      name: 'Local Aswan Draft',
      nameAr: 'مسودة محلية لأسوان',
      description: 'Local-only Aswan preview record.',
      imageUrl: '',
      rating: 4.5,
      category: 'Historical',
      lat: 24.0254,
      lng: 32.8842,
      governorate: 'aswan',
    );

    expect((await service.createPlace(place)).remoteSynced, isFalse);
    await service.updatePlace(place.copyWith(name: 'Edited Aswan Draft'));
    final savedPlace = (await service.fetchPlaces()).singleWhere(
      (candidate) => candidate.id == place.id,
    );
    expect(savedPlace.name, 'Edited Aswan Draft');
    expect(savedPlace.governorate, 'aswan');

    final tour = Tour(
      id: 'draft_aswan_test_tour',
      title: 'Local Aswan Tour',
      description: 'Local-only Aswan itinerary.',
      duration: '2 Hours',
      imageUrl: '',
      governorate: 'aswan',
      places: [place],
    );
    await service.createTour(tour);
    final savedTour = (await service.fetchTours()).singleWhere(
      (candidate) => candidate.id == tour.id,
    );
    expect(savedTour.governorate, 'aswan');
    expect(savedTour.places.single.governorate, 'aswan');

    await service.deletePlace(place.id);
    await service.deleteTour(tour.id);
  });

  test(
    'local preview separates visitable places from governorate ATMs',
    () async {
      final service = AdminService.instance;
      final places = await service.fetchPlaces();
      expect(visitEligiblePlaces(places), hasLength(317));
      expect(atmPlaces(places), hasLength(38));
      expect((await service.fetchDashboardCounts()).places, 317);

      for (final (governorate, visitCount, atmCount) in [
        ('alexandria', 52, 6),
        ('cairo', 157, 20),
        ('luxor', 54, 6),
        ('aswan', 54, 6),
      ]) {
        expect(
          visitEligiblePlaces(
            places,
          ).where((place) => place.governorate == governorate),
          hasLength(visitCount),
        );
        expect(
          atmPlaces(places).where((place) => place.governorate == governorate),
          hasLength(atmCount),
        );
      }
    },
  );

  test(
    'local ATM drafts remain editable and outside visitable places',
    () async {
      final service = AdminService.instance;
      final atm = Place(
        id: 'atm_draft_local_test',
        name: 'Local Aswan ATM',
        nameAr: 'ماكينة صراف آلي محلية بأسوان',
        description: 'A local draft cash machine record.',
        imageUrl: '',
        rating: 0,
        category: 'ATMs',
        categoryAr: 'ماكينات الصراف الآلي',
        lat: 24.0955,
        lng: 32.9008,
        address: 'Aswan, Egypt',
        openHours: '24 hours',
        governorate: 'aswan',
        priceLevel: PriceLevel.free,
        priceLocalEgp: 0,
        priceForeignerEgp: 0,
      );

      expect((await service.createPlace(atm)).remoteSynced, isFalse);
      await service.updatePlace(atm.copyWith(name: 'Edited Aswan ATM'));
      final savedAtm = (await service.fetchPlaces()).singleWhere(
        (place) => place.id == atm.id,
      );
      expect(savedAtm.name, 'Edited Aswan ATM');
      expect(atmPlaces([savedAtm]), hasLength(1));
      expect(visitEligiblePlaces([savedAtm]), isEmpty);

      await service.deletePlace(atm.id);
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
