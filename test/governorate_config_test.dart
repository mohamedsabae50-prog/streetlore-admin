import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/data/governorate_preview_seed.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/governorates_config.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('config contains the unified governorate boundaries', () {
    expect(governoratesConfig.keys.toSet(), {
      'alexandria',
      'cairo',
      'luxor',
      'red_sea',
    });
    expect(alexandriaGovernorate.centerLat, 31.2001);
    expect(alexandriaGovernorate.centerLng, 29.9187);
    expect(alexandriaGovernorate.defaultZoom, 11);
    expect(cairoGovernorate.centerLat, 30.0444);
    expect(cairoGovernorate.centerLng, 31.2357);
    expect(cairoGovernorate.nameEn, 'Cairo & Giza');
    expect(cairoGovernorate.nameAr, 'القاهرة والجيزة');
    expect(cairoGovernorate.defaultZoom, 11);
    expect(luxorGovernorate.id, 'luxor');
    expect(luxorGovernorate.centerLat, 24.9500);
    expect(luxorGovernorate.centerLng, 32.7600);
    expect(luxorGovernorate.nameEn, 'Luxor & Aswan');
    expect(luxorGovernorate.nameAr, 'الأقصر وأسوان');
    expect(luxorGovernorate.defaultZoom, 8.8);
    expect(redSeaGovernorate.id, 'red_sea');
    expect(redSeaGovernorate.centerLat, 26.8500);
    expect(redSeaGovernorate.centerLng, 33.9500);
    expect(redSeaGovernorate.nameEn, 'Hurghada & Marsa Alam');
    expect(redSeaGovernorate.nameAr, 'الغردقة ومرسى علم');
    expect(redSeaGovernorate.defaultZoom, 8.8);
    expect(alexandriaGovernorate.boundaryPolygon, hasLength(10));
    expect(cairoGovernorate.boundaryPolygon, hasLength(9));
    expect(luxorGovernorate.boundaryPolygon, hasLength(10));
    expect(redSeaGovernorate.boundaryPolygon, hasLength(10));
    expect(
      alexandriaGovernorate.boundaryPolygon
          .map((point) => (point.latitude, point.longitude))
          .toList(),
      [
        (31.3350, 30.0950),
        (31.2600, 30.1400),
        (31.1200, 30.0800),
        (30.9500, 29.9800),
        (30.8000, 29.8500),
        (30.7800, 29.5500),
        (30.8800, 29.4800),
        (31.0500, 29.6800),
        (31.1600, 29.8200),
        (31.2800, 29.9500),
      ],
    );
    expect(
      cairoGovernorate.boundaryPolygon
          .map((point) => (point.latitude, point.longitude))
          .toList(),
      [
        (30.2600, 30.7500),
        (30.2800, 31.1500),
        (30.2800, 31.5200),
        (30.2200, 31.8800),
        (29.9200, 31.8800),
        (29.6000, 31.5000),
        (29.5500, 31.1800),
        (29.7800, 30.8200),
        (30.0200, 30.7200),
      ],
    );
    expect(
      luxorGovernorate.boundaryPolygon
          .map((point) => (point.latitude, point.longitude))
          .toList(),
      [
        (25.9000, 32.3000),
        (25.9000, 33.1500),
        (25.2000, 33.2500),
        (24.5000, 33.4500),
        (23.8000, 33.5500),
        (22.1500, 32.1000),
        (22.1500, 31.3500),
        (23.1000, 31.4500),
        (24.1500, 32.2500),
        (25.2500, 32.2500),
      ],
    );
    expect(
      redSeaGovernorate.boundaryPolygon
          .map((point) => (point.latitude, point.longitude))
          .toList(),
      [
        (29.1000, 32.2500),
        (29.1000, 33.1500),
        (27.6000, 34.1500),
        (26.2000, 34.6500),
        (24.8000, 35.3500),
        (24.0500, 35.6500),
        (24.0500, 34.4500),
        (25.2000, 34.1000),
        (26.3500, 33.4000),
        (27.5000, 33.0500),
      ],
    );
    expect(AdminGovernorate.all, hasLength(4));
    expect(AdminGovernorate.all.map((governorate) => governorate.id), [
      'alexandria',
      'cairo',
      'luxor',
      'red_sea',
    ]);
    expect(
      AdminGovernorate.all.map(
        (governorate) => (governorate.nameEn, governorate.nameAr),
      ),
      [
        ('Alexandria', 'الإسكندرية'),
        ('Cairo & Giza', 'القاهرة والجيزة'),
        ('Luxor & Aswan', 'الأقصر وأسوان'),
        ('Hurghada & Marsa Alam', 'الغردقة ومرسى علم'),
      ],
    );
    expect(
      AdminGovernorate.all
          .singleWhere((governorate) => governorate.id == 'cairo')
          .boundaryPolygon,
      cairoGovernorate.boundaryPolygon,
    );
  });

  test('unified boundary accepts Cairo and Giza and rejects Banha', () {
    expect(isPointInGovernorate(30.0444, 31.2357, 'cairo'), isTrue);
    expect(isPointInGovernorate(29.9792, 31.1342, 'cairo'), isTrue);
    expect(isPointInGovernorate(29.9930, 31.1190, 'cairo'), isTrue);
    expect(isPointInGovernorate(30.0120, 30.9900, 'cairo'), isTrue);
    expect(isPointInGovernorate(29.9792, 31.1342, 'giza'), isTrue);
    expect(isPointInGovernorate(30.4660, 31.1840, 'cairo'), isFalse);
    expect(isPointInGovernorate(31.2001, 29.9187, 'alexandria'), isTrue);
    expect(isPointInGovernorate(31.2001, 29.9187, 'cairo'), isFalse);
    expect(isPointInGovernorate(30.0444, 31.2357, 'alexandria'), isFalse);
    expect(AdminGovernorate.normalizeId(' GIZA '), 'cairo');
    expect(AdminGovernorate.byId('giza')?.id, 'cairo');
    expect(isPointInGovernorate(0, 0, 'unknown'), isFalse);
  });

  test('Luxor & Aswan boundary contains both cities', () {
    expect(isPointInGovernorate(25.7050, 32.6391, 'luxor'), isTrue);
    expect(isPointInGovernorate(25.8200, 32.5200, 'luxor'), isTrue);
    expect(isPointInGovernorate(24.0889, 32.8998, 'luxor'), isTrue);
    expect(isPointInGovernorate(24.0889, 32.8998, 'aswan'), isTrue);
    expect(isPointInGovernorate(25.7050, 32.6391, 'alexandria'), isFalse);
    expect(isPointInGovernorate(25.7050, 32.6391, 'cairo'), isFalse);
    expect(normalizeGovernorateId(' LUXOR '), 'luxor');
    expect(normalizeGovernorateId('ASWAN'), 'luxor');
    expect(AdminGovernorate.byId(' luxor ')?.id, 'luxor');
    expect(AdminGovernorate.byId('aswan')?.id, 'luxor');
    expect(Place.inferGovernorate(lat: 25.7050, lng: 32.6391), 'luxor');
    expect(Place.inferGovernorate(lat: 24.0889, lng: 32.8998), 'luxor');
    expect(Place.inferGovernorate(lat: 31.2001, lng: 29.9187), 'alexandria');
    expect(Place.inferGovernorate(lat: 30.0444, lng: 31.2357), 'cairo');
  });

  test('Red Sea boundary and aliases resolve to one governorate', () {
    expect(isPointInGovernorate(26.8500, 33.9500, 'red_sea'), isTrue);
    expect(isPointInGovernorate(26.8500, 33.9500, 'hurghada'), isTrue);
    expect(isPointInGovernorate(26.8500, 33.9500, 'marsa_alam'), isTrue);
    expect(normalizeGovernorateId(' HURGHADA '), 'red_sea');
    expect(normalizeGovernorateId('MARSA_ALAM'), 'red_sea');
    expect(AdminGovernorate.byId('hurghada')?.id, 'red_sea');
    expect(AdminGovernorate.byId('marsa_alam')?.id, 'red_sea');
    expect(Place.inferGovernorate(lat: 26.8500, lng: 33.9500), 'red_sea');
  });

  test('legacy Aswan values normalize to the unified boundary', () {
    const aswanSites = [
      (24.0889, 32.8998),
      (24.0254, 32.8842),
      (23.9700, 32.8772),
      (22.3372, 31.6258),
      (24.4520, 32.9283),
      (24.9780, 32.8733),
    ];
    for (final (lat, lng) in aswanSites) {
      expect(isPointInGovernorate(lat, lng, 'aswan'), isTrue);
      expect(isPointInGovernorate(lat, lng, 'luxor'), isTrue);
      expect(isPointInGovernorate(lat, lng, 'cairo'), isFalse);
      expect(isPointInGovernorate(lat, lng, 'alexandria'), isFalse);
      expect(Place.inferGovernorate(lat: lat, lng: lng), 'luxor');
    }

    expect(isPointInGovernorate(25.7050, 32.6391, 'aswan'), isTrue);
    expect(isPointInGovernorate(25.0200, 32.8000, 'aswan'), isTrue);
    expect(normalizeGovernorateId(' أسوان '), 'luxor');
    expect(AdminGovernorate.byId('أسوان')?.id, 'luxor');
  });

  test(
    'Red Sea preview records match requested coordinates and prices',
    () async {
      final seed = await GovernoratePreviewSeed.load();
      final placesById = {for (final place in seed.places) place.id: place};
      const expected = <String, (double, double, int, int)>{
        'red_sea_el_quseir_ottoman_fortress': (26.1044, 34.2778, 40, 200),
        'red_sea_hurghada_museum': (27.1456, 33.8225, 80, 300),
        'red_sea_hurghada_grand_aquarium': (27.1292, 33.8247, 250, 1200),
        'red_sea_sand_city_hurghada': (27.0925, 33.8285, 120, 450),
        'red_sea_mini_egypt_park_makadi': (26.9885, 33.8895, 150, 500),
        'red_sea_mons_claudianus_roman_quarry': (26.8092, 33.4869, 40, 200),
        'red_sea_mons_porphyrites_quarry': (27.2510, 33.3015, 40, 200),
        'red_sea_myos_hormos_quseir_qadim': (26.1565, 34.2435, 40, 180),
        'red_sea_bir_umm_fawakhir_mines': (26.0085, 33.6085, 40, 180),
        'red_sea_sikait_smaragdus_mines': (24.6510, 34.7890, 50, 220),
        'red_sea_el_gouna_cultural_museum': (27.3975, 33.6752, 60, 220),
        'red_sea_dolphin_world_makadi': (26.9795, 33.8840, 200, 750),
        'red_sea_sahl_hasheesh_sunken_city': (27.0425, 33.8965, 50, 200),
        'red_sea_safaga_old_port_citadel': (26.7385, 33.9395, 30, 120),
        'red_sea_port_ghalib_khan_promenade': (25.5345, 34.6395, 50, 200),
        'red_sea_ras_gharib_lighthouse_heritage': (28.3525, 33.0815, 30, 120),
        'red_sea_giftun_island_orange_bay': (27.2045, 33.9315, 150, 600),
        'red_sea_mahmya_island_reserve': (27.1815, 33.9525, 200, 800),
        'red_sea_abu_dabbab_dugong_bay': (25.3385, 34.7395, 100, 450),
        'red_sea_wadi_el_gemal_national_park': (24.5580, 35.1250, 60, 300),
        'red_sea_sharm_el_luli_lagoon': (24.5515, 35.1545, 60, 300),
        'red_sea_nayzak_natural_meteor_pool': (24.9915, 34.9455, 50, 200),
        'red_sea_sataya_dolphin_house_reef': (24.1650, 35.6000, 150, 650),
        'red_sea_samadai_dolphin_house_marsa': (24.9885, 35.0125, 150, 650),
        'red_sea_qulaan_mangrove_lagoon': (24.3515, 35.2855, 50, 200),
        'red_sea_el_fanadir_reef_hurghada': (27.2985, 33.8315, 100, 400),
        'red_sea_soma_bay_ras_abu_soma': (26.8525, 33.9925, 100, 400),
        'red_sea_zeytouna_beach_el_gouna': (27.4025, 33.6885, 120, 450),
        'red_sea_makadi_bay_house_reef': (26.9925, 33.9025, 100, 400),
        'red_sea_sharm_el_naga_coral_bay': (26.8995, 33.9635, 120, 500),
        'red_sea_marsa_mubarak_turtle_bay': (25.5085, 34.6545, 120, 500),
        'red_sea_hurghada_marina_boulevard_walk': (27.2245, 33.8415, 0, 0),
        'red_sea_al_mina_masjid_hurghada': (27.2305, 33.8442, 0, 0),
        'red_sea_st_shenouda_cathedral_hurghada': (27.2565, 33.8125, 0, 0),
        'red_sea_st_anthony_monastery': (28.9244, 32.3497, 0, 0),
        'red_sea_st_paul_anchorite_monastery': (28.8469, 32.5519, 0, 0),
        'red_sea_shaykh_al_farran_mosque_quseir': (26.1068, 34.2802, 0, 0),
        'red_sea_starfish_seafood_hurghada': (27.2215, 33.8375, 250, 900),
        'red_sea_el_halaka_fish_restaurant': (27.2285, 33.8428, 180, 650),
        'red_sea_moby_dick_steak_seafood': (27.2165, 33.8395, 350, 1200),
        'red_sea_abu_tig_marina_bistro_gouna': (27.4095, 33.6795, 250, 900),
        'red_sea_granada_panorama_terrace_hurghada': (
          27.2115,
          33.8425,
          180,
          650,
        ),
        'red_sea_marina_breeze_lounge_cafe': (27.2232, 33.8405, 150, 550),
        'red_sea_tamr_henna_plaza_cafe_gouna': (27.3955, 33.6735, 120, 450),
        'red_sea_el_dahar_old_bazaar_hurghada': (27.2525, 33.8185, 0, 0),
        'red_sea_senzo_mall_hurghada': (27.0955, 33.8255, 0, 0),
        'red_sea_sheraton_road_tourist_bazaar': (27.2185, 33.8385, 0, 0),
        'red_sea_abu_tig_marina_boutiques_gouna': (27.4075, 33.6812, 0, 0),
        'red_sea_steigenberger_aldau_hurghada': (27.1595, 33.8285, 7500, 14000),
        'red_sea_oberoi_beach_resort_sahl_hasheesh': (
          27.0685,
          33.8905,
          12000,
          25000,
        ),
        'red_sea_kempinski_hotel_soma_bay': (26.8585, 33.9885, 6000, 12000),
        'red_sea_sheraton_miramar_el_gouna': (27.3995, 33.6855, 7500, 15000),
        'red_sea_hilton_marsa_alam_nubian_resort': (
          25.3445,
          34.7355,
          5000,
          9500,
        ),
        'red_sea_jaz_palace_port_ghalib_resort': (25.5385, 34.6435, 4500, 8500),
        'atm_nbe_hurghada_new_marina': (27.2255, 33.8402, 0, 0),
        'atm_banque_misr_sheraton_road_hurghada': (27.2145, 33.8398, 0, 0),
        'atm_cib_abu_tig_marina_el_gouna': (27.4085, 33.6782, 0, 0),
        'atm_qnb_senzo_mall_hurghada': (27.0968, 33.8262, 0, 0),
        'atm_nbe_port_ghalib_marina_marsa_alam': (25.5332, 34.6382, 0, 0),
        'atm_banque_misr_marsa_alam_town_center': (25.0695, 34.8965, 0, 0),
      };
      final redSeaPlaces = seed.places
          .where((place) => place.governorate == 'red_sea')
          .toList(growable: false);
      final redSeaTours = seed.tours
          .where((tour) => tour.governorate == 'red_sea')
          .toList(growable: false);

      expect(seed.places, hasLength(427));
      expect(seed.tours, hasLength(38));
      expect(redSeaPlaces, hasLength(60));
      expect(redSeaTours, hasLength(6));
      expect(
        redSeaPlaces.map((place) => place.id).toSet(),
        expected.keys.toSet(),
      );
      expect(redSeaPlaces.where((place) => !place.isAtm), hasLength(54));
      expect(atmPlaces(redSeaPlaces), hasLength(6));
      expect(
        redSeaPlaces.map((place) => place.imageUrl).toSet(),
        hasLength(60),
      );
      for (final entry in expected.entries) {
        final place = placesById[entry.key]!;
        expect(
          (
            place.lat,
            place.lng,
            place.priceLocalEgp ?? 0,
            place.priceForeignerEgp ?? 0,
          ),
          entry.value,
          reason: place.id,
        );
      }

      expect(
        redSeaPlaces.where(
          (place) =>
              place.category == 'Historical' || place.category == 'Culture',
        ),
        hasLength(16),
      );
      expect(
        redSeaPlaces.where((place) => place.category == 'Nature'),
        hasLength(16),
      );
      expect(
        redSeaPlaces.where(
          (place) =>
              place.category == 'Mosques' || place.category == 'Churches',
        ),
        hasLength(5),
      );
      expect(
        redSeaPlaces.where(
          (place) => place.category == 'Food' || place.category == 'Cafe',
        ),
        hasLength(7),
      );
      expect(
        redSeaPlaces.where((place) => place.category == 'Shopping'),
        hasLength(4),
      );
      expect(
        redSeaPlaces.where((place) => place.category == 'Hotels'),
        hasLength(6),
      );
      expect(
        redSeaTours.map((tour) => tour.id),
        containsAll({
          'red_sea_giftun_marina_al_mina_trail',
          'red_sea_el_gouna_lagoons_marina_walk',
          'red_sea_sahl_hasheesh_makadi_soma_bay_route',
          'red_sea_marsa_alam_abu_dabbab_nayzak_expedition',
          'red_sea_wadi_el_gemal_sharm_el_luli_eco_safari',
          'red_sea_quseir_fortress_roman_quarries_heritage',
        }),
      );
      expect(
        redSeaTours.every(
          (tour) =>
              tour.places.isNotEmpty &&
              tour.places.every(
                (place) =>
                    place.governorate == 'red_sea' &&
                    isPointInGovernorate(place.lat, place.lng, 'red_sea'),
              ),
        ),
        isTrue,
      );
    },
  );

  test(
    'expanded validation includes nearby edges but excludes distant areas',
    () {
      expect(
        isPointInGovernorateOrExpandedBounds(30.17, 31.4, 'cairo'),
        isTrue,
      );
      expect(
        isPointInGovernorateOrExpandedBounds(30.4660, 31.1840, 'cairo'),
        isFalse,
      );
      expect(isPointInGovernorateOrExpandedBounds(0, 0, 'unknown'), isFalse);
    },
  );

  test('preview asset includes the four configured governorates', () async {
    final seed = await GovernoratePreviewSeed.load();

    expect(
      seed.places.where((place) => place.governorate == 'cairo'),
      hasLength(greaterThanOrEqualTo(120)),
    );
    expect(
      seed.places.where((place) => place.governorate == 'alexandria'),
      hasLength(62),
    );
    expect(
      seed.tours.where((tour) => tour.governorate == 'cairo'),
      hasLength(15),
    );
    expect(
      seed.tours.where((tour) => tour.governorate == 'alexandria'),
      hasLength(5),
    );
    const newLandmarks = <String, (String, double, double, int, int)>{
      'alex_abu_mena_unesco': ('alexandria', 30.8411, 29.6633, 40, 150),
      'alex_el_max_venice_canal': ('alexandria', 31.1535, 29.8442, 0, 0),
      'alex_taposiris_magna_temple': ('alexandria', 30.9461, 29.5186, 40, 150),
      'alex_amreya_heritage_souq': ('alexandria', 30.9985, 29.7850, 0, 0),
      'cairo_abusir_pyramids_necropolis': ('cairo', 29.8978, 31.2039, 60, 300),
      'cairo_helwan_japanese_garden': ('cairo', 29.8489, 31.3408, 30, 100),
      'cairo_helwan_wax_museum': ('cairo', 29.8525, 31.3342, 40, 150),
      'cairo_wissa_wassef_art_center': ('cairo', 29.9615, 31.1785, 40, 150),
      'luxor_esna_khnum_temple': ('luxor', 25.2933, 32.5561, 40, 300),
      'aswan_el_kab_necropolis': ('luxor', 25.1189, 32.7981, 40, 200),
      'aswan_wadi_el_sebua_temples': ('luxor', 22.7936, 32.5458, 40, 260),
      'aswan_amada_pennut_temples': ('luxor', 22.7311, 32.2625, 40, 260),
    };
    final placesById = {for (final place in seed.places) place.id: place};
    expect(newLandmarks, hasLength(12));
    for (final entry in newLandmarks.entries) {
      final place = placesById[entry.key]!;
      expect(
        (
          place.governorate,
          place.lat,
          place.lng,
          place.priceLocalEgp ?? -1,
          place.priceForeignerEgp ?? -1,
        ),
        entry.value,
        reason: place.id,
      );
      expect(place.isAtm, isFalse, reason: place.id);
      expect(place.openHours, isNotEmpty, reason: place.id);
    }
    final luxorPlaces = seed.places
        .where((place) => place.governorate == 'luxor')
        .toList(growable: false);
    final luxorTours = seed.tours
        .where((tour) => tour.governorate == 'luxor')
        .toList(growable: false);
    expect(luxorPlaces, hasLength(124));
    expect(luxorTours, hasLength(12));
    expect(luxorPlaces.where((place) => !place.isAtm), hasLength(112));
    expect(luxorPlaces.where((place) => place.isAtm), hasLength(12));
    expect(visitEligiblePlaces(luxorPlaces), hasLength(112));
    final aswanPlaces = seed.places
        .where(
          (place) =>
              place.id.startsWith('aswan_') ||
              place.id.contains('aswan') ||
              place.id == 'atm_nbe_kom_ombo_temple_plaza' ||
              place.id == 'atm_banque_misr_edfu_temple_square',
        )
        .toList(growable: false);
    final aswanTours = seed.tours
        .where((tour) => tour.id.startsWith('aswan_'))
        .toList(growable: false);
    expect(aswanPlaces, hasLength(63));
    expect(aswanTours, hasLength(6));
    expect(aswanPlaces.where((place) => !place.isAtm), hasLength(57));
    expect(aswanPlaces.where((place) => place.isAtm), hasLength(6));
    expect(visitEligiblePlaces(aswanPlaces), hasLength(57));
    const aswanPlaceIds = {
      'aswan_philae_temple',
      'aswan_abu_simbel_great_temple',
      'aswan_abu_simbel_nefertari_temple',
      'aswan_nubian_museum',
      'aswan_unfinished_obelisk',
      'aswan_high_dam_memorial',
      'aswan_old_low_dam',
      'aswan_kalabsha_temple',
      'aswan_beit_el_wali_temple',
      'aswan_kiosk_of_qertassi',
      'aswan_qubbet_el_hawa_tombs',
      'aswan_st_simeon_monastery',
      'aswan_elephantine_museum_ruins',
      'aswan_elephantine_nilometer',
      'aswan_sehel_island_famine_stele',
      'aswan_aga_khan_mausoleum',
      'aswan_fatimid_cemetery',
      'aswan_kom_ombo_temple',
      'aswan_crocodile_museum_kom_ombo',
      'aswan_edfu_horus_temple',
      'aswan_tell_edfu_archaeological_site',
      'aswan_nile_museum',
      'aswan_cultural_palace_theater',
      'aswan_international_sculpture_park',
      'aswan_botanical_garden_kitchener',
      'aswan_gharb_soheil_nubian_village',
      'aswan_saluga_ghazal_protectorate',
      'aswan_heissa_nubian_island',
      'aswan_nile_corniche_promenade',
      'aswan_faryal_garden_corniche',
      'aswan_west_bank_sand_dunes_viewpoint',
      'aswan_el_tabia_mosque',
      'aswan_el_haj_hassan_mosque',
      'aswan_sayyida_zaynab_mosque_souq',
      'aswan_archangel_michael_cathedral',
      'aswan_virgin_mary_church_corniche',
      'aswan_1902_restaurant_old_cataract',
      'aswan_al_masry_restaurant',
      'aswan_al_dokkah_nubian_island_restaurant',
      'aswan_makka_corniche_restaurant',
      'aswan_ibis_panorama_restaurant',
      'aswan_old_cataract_terrace_cafe',
      'aswan_nubian_dreams_cafe_gharb_soheil',
      'aswan_karkadeh_souq_heritage_cafe',
      'aswan_sharia_el_souq_bazaar',
      'aswan_nubian_spices_henna_market',
      'aswan_gharb_soheil_handicraft_bazaar',
      'aswan_daraw_historic_market',
      'aswan_sofitel_legend_old_cataract',
      'aswan_movenpick_resort_elephantine',
      'aswan_benben_by_dhara_heissa',
      'aswan_tolip_hotel_corniche',
      'aswan_kato_dool_wellness_resort',
      'aswan_pyramisa_isis_island_resort',
      'atm_nbe_aswan_corniche_station',
      'atm_banque_misr_old_cataract_aswan',
      'atm_cib_aswan_tourist_souq',
      'atm_qnb_nubian_museum_aswan',
      'atm_nbe_kom_ombo_temple_plaza',
      'atm_banque_misr_edfu_temple_square',
      'aswan_el_kab_necropolis',
      'aswan_wadi_el_sebua_temples',
      'aswan_amada_pennut_temples',
    };
    expect(aswanPlaceIds, hasLength(63));
    expect(aswanPlaces.map((place) => place.id), containsAll(aswanPlaceIds));
    expect(aswanPlaces.map((place) => place.id).toSet(), hasLength(63));
    expect(
      aswanPlaces.every(
        (place) => isPointInGovernorate(place.lat, place.lng, 'aswan'),
      ),
      isTrue,
    );
    const aswanTicketPrices = <String, (int, int)>{
      'aswan_philae_temple': (80, 550),
      'aswan_abu_simbel_great_temple': (100, 750),
      'aswan_abu_simbel_nefertari_temple': (100, 750),
      'aswan_nubian_museum': (40, 400),
      'aswan_unfinished_obelisk': (40, 220),
      'aswan_high_dam_memorial': (30, 200),
      'aswan_old_low_dam': (20, 100),
      'aswan_kalabsha_temple': (40, 300),
      'aswan_beit_el_wali_temple': (40, 300),
      'aswan_kiosk_of_qertassi': (40, 300),
      'aswan_qubbet_el_hawa_tombs': (40, 200),
      'aswan_st_simeon_monastery': (40, 160),
      'aswan_elephantine_museum_ruins': (40, 200),
      'aswan_elephantine_nilometer': (40, 200),
      'aswan_sehel_island_famine_stele': (40, 160),
      'aswan_aga_khan_mausoleum': (30, 100),
      'aswan_fatimid_cemetery': (30, 100),
      'aswan_kom_ombo_temple': (60, 450),
      'aswan_crocodile_museum_kom_ombo': (40, 200),
      'aswan_edfu_horus_temple': (80, 550),
      'aswan_tell_edfu_archaeological_site': (40, 150),
      'aswan_nile_museum': (35, 150),
      'aswan_cultural_palace_theater': (30, 120),
      'aswan_international_sculpture_park': (30, 120),
    };
    final aswanPlacesById = {for (final place in aswanPlaces) place.id: place};
    expect(aswanTicketPrices, hasLength(24));
    for (final entry in aswanTicketPrices.entries) {
      final place = aswanPlacesById[entry.key]!;
      expect(
        (place.priceLocalEgp, place.priceForeignerEgp),
        entry.value,
        reason: place.id,
      );
      expect(place.priceLocalEgp, greaterThan(0), reason: place.id);
      expect(place.priceForeignerEgp, greaterThan(0), reason: place.id);
    }
    expect(
      atmPlaces(aswanPlaces).map((place) => place.id),
      containsAll({
        'atm_nbe_aswan_corniche_station',
        'atm_banque_misr_old_cataract_aswan',
        'atm_cib_aswan_tourist_souq',
        'atm_qnb_nubian_museum_aswan',
        'atm_nbe_kom_ombo_temple_plaza',
        'atm_banque_misr_edfu_temple_square',
      }),
    );
    expect(
      aswanPlaces
          .where(
            (place) =>
                place.category == 'Historical' || place.category == 'Culture',
          )
          .every(
            (place) =>
                place.priceLevel == PriceLevel.moderate ||
                place.priceLevel == PriceLevel.expensive,
          ),
      isTrue,
    );
    final aswanWorshipAndShopping = aswanPlaces
        .where(
          (place) =>
              place.category == 'Mosques' ||
              place.category == 'Churches' ||
              place.category == 'Shopping',
        )
        .toList(growable: false);
    expect(aswanWorshipAndShopping, hasLength(9));
    expect(
      aswanWorshipAndShopping.every(
        (place) =>
            place.priceLevel == PriceLevel.free &&
            place.priceLocalEgp == 0 &&
            place.priceForeignerEgp == 0,
      ),
      isTrue,
    );
    final aswanFoodAndCafes = aswanPlaces
        .where((place) => place.category == 'Food' || place.category == 'Cafe')
        .toList(growable: false);
    expect(aswanFoodAndCafes, hasLength(8));
    expect(
      aswanFoodAndCafes.every(
        (place) =>
            (place.priceLevel == PriceLevel.moderate ||
                place.priceLevel == PriceLevel.expensive) &&
            place.priceLocalEgp != null &&
            place.priceLocalEgp! > 0 &&
            place.priceForeignerEgp != null &&
            place.priceForeignerEgp! > 0,
      ),
      isTrue,
    );
    final aswanHotels = aswanPlaces
        .where((place) => place.category == 'Hotels')
        .toList(growable: false);
    expect(aswanHotels, hasLength(6));
    expect(
      aswanHotels.every(
        (place) =>
            place.priceLevel == PriceLevel.expensive &&
            place.priceLocalEgp != null &&
            place.priceLocalEgp! > 0 &&
            place.priceForeignerEgp != null &&
            place.priceForeignerEgp! > 0,
      ),
      isTrue,
    );
    expect(
      aswanPlaces
          .where((place) => place.category == 'Hotels' || place.isAtm)
          .every((place) => place.openHours == '24 hours'),
      isTrue,
    );
    expect(
      aswanPlaces
          .where(
            (place) => place.category == 'Food' || place.category == 'Cafe',
          )
          .every((place) => place.openHours == '10:00 AM - 01:00 AM'),
      isTrue,
    );
    expect(
      aswanTours.map((tour) => tour.id),
      containsAll({
        'aswan_philae_high_dam_obelisk_trail',
        'aswan_nubian_museum_cataract_elephantine',
        'aswan_west_bank_nobles_simeon_nubian_village',
        'aswan_botanical_island_sehel_corniche_sail',
        'aswan_kom_ombo_edfu_nile_temples_route',
        'aswan_abu_simbel_lake_nasser_royal_expedition',
      }),
    );
    expect(aswanTours.map((tour) => tour.imageUrl).toSet(), hasLength(6));
    expect(
      aswanTours
          .map((tour) => tour.imageUrl)
          .toSet()
          .intersection(aswanPlaces.map((place) => place.imageUrl).toSet()),
      isEmpty,
    );
    const ticketPrices = <String, (int, int)>{
      'luxor_karnak_temple': (80, 600),
      'luxor_temple': (80, 500),
      'luxor_avenue_of_sphinxes': (80, 500),
      'luxor_museum': (50, 400),
      'luxor_mummification_museum': (40, 300),
      'luxor_valley_of_the_kings': (100, 750),
      'luxor_tomb_of_tutankhamun': (80, 700),
      'luxor_tomb_of_ramesses_vi': (60, 220),
      'luxor_valley_of_the_queens': (60, 220),
      'luxor_tomb_of_nefertari': (600, 2000),
      'luxor_hatshepsut_temple': (80, 440),
      'luxor_medinet_habu': (60, 220),
      'luxor_ramesseum': (60, 220),
      'luxor_colossi_of_memnon': (0, 0),
      'luxor_deir_el_medina': (60, 220),
      'luxor_tombs_of_the_nobles': (60, 200),
      'luxor_ramose_tomb': (40, 160),
      'luxor_sennedjem_tomb': (40, 160),
      'luxor_howard_carter_house': (60, 220),
      'luxor_temple_of_seti_i_qurna': (40, 160),
      'luxor_merenptah_mortuary_temple': (40, 140),
      'luxor_assasif_necropolis': (40, 160),
      'luxor_deir_el_shelwit': (30, 100),
      'luxor_medamud_temple': (30, 100),
      'luxor_tod_temple': (30, 100),
      'luxor_armant_temple': (30, 100),
    };
    final luxorPlacesById = {for (final place in luxorPlaces) place.id: place};
    expect(ticketPrices.keys, hasLength(26));
    for (final entry in ticketPrices.entries) {
      final place = luxorPlacesById[entry.key]!;
      expect(
        (place.priceLocalEgp, place.priceForeignerEgp),
        entry.value,
        reason: place.id,
      );
    }
    expect(
      luxorPlaces
          .where(
            (place) =>
                (place.category == 'Historical' ||
                    place.category == 'Culture') &&
                place.id != 'luxor_colossi_of_memnon',
          )
          .every(
            (place) =>
                (place.priceLevel == PriceLevel.moderate ||
                    place.priceLevel == PriceLevel.expensive) &&
                place.priceLocalEgp != null &&
                place.priceLocalEgp! > 0 &&
                place.priceForeignerEgp != null &&
                place.priceForeignerEgp! > 0,
          ),
      isTrue,
    );
    expect(
      luxorPlaces
          .singleWhere((place) => place.id == 'luxor_colossi_of_memnon')
          .priceLevel,
      PriceLevel.free,
    );
    expect(
      luxorPlaces
          .where((place) => place.category == 'Hotels' || place.isAtm)
          .every((place) => place.openHours == '24 hours'),
      isTrue,
    );
    expect(
      luxorPlaces.every(
        (place) => isPointInGovernorate(place.lat, place.lng, 'luxor'),
      ),
      isTrue,
    );
    expect(
      luxorTours.every(
        (tour) =>
            tour.places.isNotEmpty &&
            tour.places.every(
              (place) =>
                  place.governorate == 'luxor' &&
                  isPointInGovernorate(place.lat, place.lng, 'luxor'),
            ),
      ),
      isTrue,
    );
    expect(luxorPlaces.map((place) => place.imageUrl).toSet(), hasLength(124));
    expect(
      seed.places
          .where((place) => place.governorate == 'cairo')
          .every(
            (place) =>
                isPointInGovernorate(place.lat, place.lng, place.governorate),
          ),
      isTrue,
    );
    expect(
      seed.places
          .where((place) => place.governorate == 'alexandria')
          .every(
            (place) => isPointInGovernorateOrExpandedBounds(
              place.lat,
              place.lng,
              place.governorate,
              expansionKm: 6,
            ),
          ),
      isTrue,
    );
    final cairoPlaces = seed.places
        .where((place) => place.governorate == 'cairo')
        .toList(growable: false);
    const addedPlaceIds = {
      'giza_great_pyramid',
      'giza_pyramid_khafre',
      'giza_pyramid_menkaure',
      'giza_great_sphinx',
      'giza_grand_egyptian_museum',
      'giza_saqqara_step_pyramid',
      'giza_serapeum_saqqara',
      'giza_pyramid_unas',
      'giza_imhotep_museum',
      'giza_bent_pyramid',
      'giza_red_pyramid',
      'giza_memphis_museum',
      'giza_pharaonic_village',
      'giza_cairo_university_dome',
      'giza_orman_botanical_garden',
      'giza_zoo',
      'giza_taha_hussein_museum',
      'giza_ahmed_shawki_museum',
      'giza_mahmoud_khalil_museum',
      'giza_zed_park',
      'giza_al_hosary_mosque',
      'giza_mustafa_mahmoud_mosque',
      'giza_al_shorta_mosque',
      'giza_archangel_michael_cathedral',
      'giza_9_pyramids_lounge',
      'giza_andrea_mariouteya',
      'giza_kebdet_el_prince_imbaba',
      'giza_abou_shakra_mohandessin',
      'giza_arkan_plaza_cafe',
      'giza_mall_of_egypt',
      'giza_mall_of_arabia',
      'giza_arkan_plaza',
      'giza_first_mall',
      'giza_marriott_mena_house',
      'giza_four_seasons_first_residence',
      'giza_sheraton_cairo_dokki',
      'giza_hyatt_regency_west_cairo',
      'atm_arkan_plaza',
      'atm_mall_of_egypt',
      'atm_mall_of_arabia',
      'cairo_egyptian_textile_museum',
      'cairo_sabil_umm_abbas',
      'cairo_wakala_qaytbay',
      'cairo_hammam_inal',
      'cairo_opera_museum',
      'cairo_al_horreya_garden',
      'cairo_azbakeya_book_market',
      'cairo_korba_heritage_walk',
      'cairo_new_capital_arts_culture_city',
      'cairo_maadi_felucca_pier',
      'alexandria_cavafy_museum',
      'alexandria_sadat_museum',
      'alexandria_ras_el_tin_palace',
      'alexandria_antoniadis_gardens',
      'alexandria_mahmoud_said_museum',
      'alexandria_st_mark_cathedral',
      'alexandria_eliyahu_hanavi_synagogue',
      'alexandria_shatby_ancient_tombs',
      'alexandria_nelson_island',
      'alexandria_gleem_bay_promenade',
    };
    final additions = seed.places
        .where((place) => addedPlaceIds.contains(place.id))
        .toList(growable: false);
    expect(additions, hasLength(60));
    expect(
      additions.where((place) => place.governorate == 'cairo'),
      hasLength(50),
    );
    expect(
      additions.where((place) => place.governorate == 'alexandria'),
      hasLength(10),
    );
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
        'giza_great_pyramid',
        'giza_pyramid_khafre',
        'giza_pyramid_menkaure',
        'giza_great_sphinx',
        'giza_grand_egyptian_museum',
        'giza_zed_park',
        'cairo_new_capital_arts_culture_city',
        'cairo_maadi_felucca_pier',
      }),
    );
    expect(
      cairoPlaces.where((place) => !place.isAtm).map((place) => place.id),
      containsAll({
        'giza_great_pyramid',
        'giza_grand_egyptian_museum',
        'giza_zed_park',
        'cairo_new_capital_arts_culture_city',
      }),
    );
    expect(seed.places, hasLength(427));
    expect(seed.tours, hasLength(38));
    expect(seed.places.where((place) => place.isAtm), hasLength(44));
    expect(
      atmPlaces(
        seed.places,
      ).where((place) => place.governorate == 'alexandria'),
      hasLength(6),
    );
    expect(
      atmPlaces(seed.places).where((place) => place.governorate == 'cairo'),
      hasLength(20),
    );
    expect(
      atmPlaces(seed.places).where((place) => place.governorate == 'luxor'),
      hasLength(12),
    );
    expect(
      atmPlaces(seed.places).where((place) => place.governorate == 'red_sea'),
      hasLength(6),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'alexandria'),
      hasLength(56),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'cairo'),
      hasLength(161),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'luxor'),
      hasLength(112),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'red_sea'),
      hasLength(54),
    );
    expect(visitEligiblePlaces(seed.places), hasLength(383));
    expect(
      visitEligiblePlaces(seed.places).map((place) => place.id),
      isNot(
        containsAll({
          'atm_arkan_plaza',
          'atm_mall_of_egypt',
          'atm_mall_of_arabia',
        }),
      ),
    );
    final alexandriaPlaces = seed.places
        .where((place) => place.governorate == 'alexandria')
        .toList(growable: false);
    expect(
      alexandriaPlaces.map((place) => place.id),
      containsAll({
        'alexandria_cavafy_museum',
        'alexandria_sadat_museum',
        'alexandria_ras_el_tin_palace',
        'alexandria_gleem_bay_promenade',
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
            const {
              'upload.wikimedia.org',
              'thumb.wikimedia.org',
            }.contains(Uri.tryParse(place.imageUrl)?.host),
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
        'giza_pyramids_sphinx_gem_trail',
        'saqqara_memphis_dahshur_necropolis',
        'giza_dokki_nile_museums_gardens',
        'sheikh_zayed_october_modern_walk',
        'greater_cairo_east_to_west_grand_tour',
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
    final addedImageUrls = additions;
    expect(
      addedImageUrls.map((place) => place.imageUrl).toSet(),
      hasLength(60),
    );
    expect(
      addedImageUrls.every((place) {
        final uri = Uri.tryParse(place.imageUrl);
        return uri?.scheme == 'https' &&
            uri?.host == 'upload.wikimedia.org' &&
            uri?.path.startsWith('/wikipedia/commons/') == true &&
            place.imageUrls.contains(place.imageUrl);
      }),
      isTrue,
    );
    expect(
      visitEligiblePlaces(seed.places).length,
      seed.places.where((place) => !place.isAtm).length,
    );
    expect(
      visitEligiblePlaces(seed.places).map((place) => place.id),
      containsAll({'giza_great_pyramid', 'alexandria_cavafy_museum'}),
    );
    expect(
      visitEligiblePlaces(seed.places).map((place) => place.id),
      isNot(contains('atm_arkan_plaza')),
    );
  });

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

  test(
    'the complete preview catalog has repaired descriptions, prices, and images',
    () async {
      final seed = await GovernoratePreviewSeed.load();
      expect(seed.places, hasLength(427));
      expect(seed.tours, hasLength(38));

      final urls = <String>{};
      final decodedImagePaths = <String>{};
      const forbiddenText = [
        'confirm current visitor information',
        'is a culture destination in',
        'a place to explore in',
        'a landmark of the history and culture of',
        'check current opening hours',
        'check current prices and fees',
      ];
      const forbiddenImageTerms = [
        'construction',
        'britishmuseum',
        'loc_matpc',
        'sheikh_zayed_road',
      ];
      for (final place in seed.places) {
        final english = place.description.trim();
        final arabic = place.descriptionAr?.trim() ?? '';
        expect(english.length, greaterThanOrEqualTo(95), reason: place.id);
        expect(arabic.length, greaterThanOrEqualTo(65), reason: place.id);
        expect(
          english.toLowerCase(),
          contains(place.name.toLowerCase()),
          reason: place.id,
        );
        expect(arabic, contains(place.nameAr ?? place.name), reason: place.id);
        for (final phrase in forbiddenText) {
          expect(
            '${english.toLowerCase()} $arabic',
            isNot(contains(phrase)),
            reason: place.id,
          );
        }

        expect(urls.add(place.imageUrl), isTrue, reason: place.id);
        final imageUri = Uri.tryParse(place.imageUrl);
        expect(imageUri?.scheme, 'https', reason: place.id);
        expect(imageUri?.host, 'upload.wikimedia.org', reason: place.id);
        expect(
          imageUri?.path.startsWith('/wikipedia/commons/'),
          isTrue,
          reason: place.id,
        );
        expect(
          decodedImagePaths.add(Uri.decodeComponent(imageUri!.path)),
          isTrue,
          reason: place.id,
        );
        expect(
          place.imageUrls.every((url) {
            final uri = Uri.tryParse(url);
            return uri?.scheme == 'https' &&
                uri?.host == 'upload.wikimedia.org' &&
                uri?.path.startsWith('/wikipedia/commons/') == true;
          }),
          isTrue,
          reason: place.id,
        );
        for (final term in forbiddenImageTerms) {
          expect(
            place.imageUrl.toLowerCase(),
            isNot(contains(term)),
            reason: place.id,
          );
        }

        if (place.priceLevel == PriceLevel.free) {
          expect(place.priceLocalEgp ?? 0, 0, reason: place.id);
          expect(place.priceForeignerEgp ?? 0, 0, reason: place.id);
        } else {
          expect(
            place.priceLevel,
            isIn({PriceLevel.moderate, PriceLevel.expensive}),
            reason: place.id,
          );
          expect(place.priceLocalEgp, greaterThan(0), reason: place.id);
          expect(place.priceForeignerEgp, greaterThan(0), reason: place.id);
          expect(place.priceNote.trim(), isNotEmpty, reason: place.id);
        }
      }

      expect(urls, hasLength(427));
      expect(decodedImagePaths, hasLength(427));
      final luxorPlaces = seed.places
          .where((place) => place.governorate == 'luxor')
          .toList(growable: false);
      final luxorTours = seed.tours
          .where((tour) => tour.governorate == 'luxor')
          .toList(growable: false);
      final luxorUrls = luxorPlaces.map((place) => place.imageUrl).toSet();
      final luxorTourUrls = luxorTours.map((tour) => tour.imageUrl).toSet();
      expect(luxorUrls, hasLength(124));
      expect(luxorTourUrls, hasLength(12));
      expect(luxorUrls.intersection(luxorTourUrls), isEmpty);
      expect(
        [...luxorPlaces.map((place) => place.imageUrl), ...luxorTourUrls].every(
          (url) =>
              Uri.tryParse(url)?.scheme == 'https' &&
              Uri.tryParse(url)?.host == 'upload.wikimedia.org',
        ),
        isTrue,
      );
      final placesById = {for (final place in seed.places) place.id: place};
      for (final tour in seed.tours) {
        for (final snapshot in tour.places) {
          final canonical = placesById[snapshot.id];
          if (canonical == null) continue;
          expect(snapshot.imageUrl, canonical.imageUrl, reason: tour.id);
          expect(snapshot.description, canonical.description, reason: tour.id);
          expect(snapshot.openHours, canonical.openHours, reason: tour.id);
          expect(
            snapshot.priceLocalEgp,
            canonical.priceLocalEgp,
            reason: tour.id,
          );
          expect(
            snapshot.priceForeignerEgp,
            canonical.priceForeignerEgp,
            reason: tour.id,
          );
        }
      }
    },
  );
}
