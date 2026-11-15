import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/data/governorate_preview_seed.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/governorates_config.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'config contains Alexandria, Cairo & Giza, Luxor, and Aswan boundaries',
    () {
      expect(governoratesConfig.keys.toSet(), {
        'alexandria',
        'cairo',
        'luxor',
        'aswan',
      });
      expect(alexandriaGovernorate.centerLat, 31.2001);
      expect(alexandriaGovernorate.centerLng, 29.9187);
      expect(alexandriaGovernorate.defaultZoom, 11);
      expect(cairoGovernorate.centerLat, 30.0444);
      expect(cairoGovernorate.centerLng, 31.2357);
      expect(cairoGovernorate.nameEn, 'Cairo & Giza');
      expect(cairoGovernorate.nameAr, 'القاهرة والجيزة');
      expect(cairoGovernorate.defaultZoom, 11);
      expect(luxorGovernorate.centerLat, 25.7050);
      expect(luxorGovernorate.centerLng, 32.6391);
      expect(luxorGovernorate.nameEn, 'Luxor');
      expect(luxorGovernorate.nameAr, 'الأقصر');
      expect(luxorGovernorate.defaultZoom, 12.0);
      expect(aswanGovernorate.id, 'aswan');
      expect(aswanGovernorate.nameEn, 'Aswan');
      expect(aswanGovernorate.nameAr, 'أسوان');
      expect(aswanGovernorate.centerLat, 24.0889);
      expect(aswanGovernorate.centerLng, 32.8998);
      expect(aswanGovernorate.defaultZoom, 12.0);
      expect(alexandriaGovernorate.boundaryPolygon, hasLength(20));
      expect(cairoGovernorate.boundaryPolygon, hasLength(16));
      expect(luxorGovernorate.boundaryPolygon, hasLength(8));
      expect(aswanGovernorate.boundaryPolygon, hasLength(10));
      expect(
        aswanGovernorate.boundaryPolygon
            .map((point) => (point.latitude, point.longitude))
            .toList(),
        [
          (25.0200, 32.8000),
          (25.0200, 32.9600),
          (24.5000, 33.0000),
          (24.1500, 32.9600),
          (23.9300, 32.9500),
          (22.2800, 31.7000),
          (22.2800, 31.5500),
          (22.4200, 31.5500),
          (24.1200, 32.8000),
          (24.4500, 32.8400),
        ],
      );
      expect(
        luxorGovernorate.boundaryPolygon
            .map((point) => (point.latitude, point.longitude))
            .toList(),
        [
          (25.8200, 32.5200),
          (25.8300, 32.7200),
          (25.7500, 32.7800),
          (25.6200, 32.7600),
          (25.5200, 32.6800),
          (25.5000, 32.5000),
          (25.6000, 32.4500),
          (25.7400, 32.5000),
        ],
      );
      expect(AdminGovernorate.all, hasLength(4));
      expect(
        AdminGovernorate.all
            .singleWhere((governorate) => governorate.id == 'cairo')
            .boundaryPolygon,
        cairoGovernorate.boundaryPolygon,
      );
    },
  );

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

  test('Luxor boundary contains Luxor and does not overlap other regions', () {
    expect(isPointInGovernorate(25.7050, 32.6391, 'luxor'), isTrue);
    expect(isPointInGovernorate(25.8200, 32.5200, 'luxor'), isTrue);
    expect(isPointInGovernorate(25.7050, 32.6391, 'alexandria'), isFalse);
    expect(isPointInGovernorate(25.7050, 32.6391, 'cairo'), isFalse);
    expect(normalizeGovernorateId(' LUXOR '), 'luxor');
    expect(AdminGovernorate.byId(' luxor ')?.id, 'luxor');
    expect(Place.inferGovernorate(lat: 25.7050, lng: 32.6391), 'luxor');
    expect(Place.inferGovernorate(lat: 31.2001, lng: 29.9187), 'alexandria');
    expect(Place.inferGovernorate(lat: 30.0444, lng: 31.2357), 'cairo');
  });

  test(
    'Aswan boundary contains its sites without overlapping other regions',
    () {
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
        expect(isPointInGovernorate(lat, lng, 'luxor'), isFalse);
        expect(isPointInGovernorate(lat, lng, 'cairo'), isFalse);
        expect(isPointInGovernorate(lat, lng, 'alexandria'), isFalse);
        expect(Place.inferGovernorate(lat: lat, lng: lng), 'aswan');
      }

      expect(isPointInGovernorate(25.7050, 32.6391, 'aswan'), isFalse);
      expect(isPointInGovernorate(25.0200, 32.8000, 'aswan'), isTrue);
      expect(normalizeGovernorateId(' أسوان '), 'aswan');
      expect(AdminGovernorate.byId('أسوان')?.id, 'aswan');
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

  test('preview asset includes Cairo, Alexandria, Luxor, and Aswan', () async {
    final seed = await GovernoratePreviewSeed.load();

    expect(
      seed.places.where((place) => place.governorate == 'cairo'),
      hasLength(greaterThanOrEqualTo(120)),
    );
    expect(
      seed.places.where((place) => place.governorate == 'alexandria'),
      hasLength(58),
    );
    expect(
      seed.tours.where((tour) => tour.governorate == 'cairo'),
      hasLength(15),
    );
    expect(
      seed.tours.where((tour) => tour.governorate == 'alexandria'),
      hasLength(5),
    );
    final luxorPlaces = seed.places
        .where((place) => place.governorate == 'luxor')
        .toList(growable: false);
    final luxorTours = seed.tours
        .where((tour) => tour.governorate == 'luxor')
        .toList(growable: false);
    expect(luxorPlaces, hasLength(60));
    expect(luxorTours, hasLength(6));
    expect(luxorPlaces.where((place) => !place.isAtm), hasLength(54));
    expect(luxorPlaces.where((place) => place.isAtm), hasLength(6));
    expect(visitEligiblePlaces(luxorPlaces), hasLength(54));
    final aswanPlaces = seed.places
        .where((place) => place.governorate == 'aswan')
        .toList(growable: false);
    final aswanTours = seed.tours
        .where((tour) => tour.governorate == 'aswan')
        .toList(growable: false);
    expect(aswanPlaces, hasLength(60));
    expect(aswanTours, hasLength(6));
    expect(aswanPlaces.where((place) => !place.isAtm), hasLength(54));
    expect(aswanPlaces.where((place) => place.isAtm), hasLength(6));
    expect(visitEligiblePlaces(aswanPlaces), hasLength(54));
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
    };
    expect(aswanPlaceIds, hasLength(60));
    expect(aswanPlaces.map((place) => place.id), containsAll(aswanPlaceIds));
    expect(aswanPlaces.map((place) => place.id).toSet(), hasLength(60));
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
            tour.places.every((place) => place.governorate == 'luxor'),
      ),
      isTrue,
    );
    expect(luxorPlaces.map((place) => place.imageUrl).toSet(), hasLength(60));
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
            (place) =>
                isPointInGovernorate(place.lat, place.lng, place.governorate),
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
    expect(seed.places, hasLength(355));
    expect(seed.tours, hasLength(32));
    expect(seed.places.where((place) => place.isAtm), hasLength(38));
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
      hasLength(6),
    );
    expect(
      atmPlaces(seed.places).where((place) => place.governorate == 'aswan'),
      hasLength(6),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'alexandria'),
      hasLength(52),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'cairo'),
      hasLength(157),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'luxor'),
      hasLength(54),
    );
    expect(
      visitEligiblePlaces(
        seed.places,
      ).where((place) => place.governorate == 'aswan'),
      hasLength(54),
    );
    expect(visitEligiblePlaces(seed.places), hasLength(317));
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
      expect(seed.places, hasLength(355));
      expect(seed.tours, hasLength(32));

      final urls = <String>{};
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

      expect(urls, hasLength(355));
      final luxorPlaces = seed.places
          .where((place) => place.governorate == 'luxor')
          .toList(growable: false);
      final luxorTours = seed.tours
          .where((tour) => tour.governorate == 'luxor')
          .toList(growable: false);
      final luxorUrls = luxorPlaces.map((place) => place.imageUrl).toSet();
      final luxorTourUrls = luxorTours.map((tour) => tour.imageUrl).toSet();
      expect(luxorUrls, hasLength(60));
      expect(luxorTourUrls, hasLength(6));
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
