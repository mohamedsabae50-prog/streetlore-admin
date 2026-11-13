import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/data/governorate_preview_seed.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/governorates_config.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'config contains the app-matched Alexandria and unified Cairo boundary',
    () {
      expect(governoratesConfig.keys.toSet(), {'alexandria', 'cairo'});
      expect(alexandriaGovernorate.centerLat, 31.2001);
      expect(alexandriaGovernorate.centerLng, 29.9187);
      expect(alexandriaGovernorate.defaultZoom, 11);
      expect(cairoGovernorate.centerLat, 30.0444);
      expect(cairoGovernorate.centerLng, 31.2357);
      expect(cairoGovernorate.nameEn, 'Cairo & Giza');
      expect(cairoGovernorate.nameAr, 'القاهرة والجيزة');
      expect(cairoGovernorate.defaultZoom, 11);
      expect(alexandriaGovernorate.boundaryPolygon, hasLength(20));
      expect(cairoGovernorate.boundaryPolygon, hasLength(16));
      expect(AdminGovernorate.all, hasLength(2));
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
        hasLength(52),
      );
      expect(
        seed.tours.where((tour) => tour.governorate == 'cairo'),
        hasLength(15),
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
      expect(seed.places.where((place) => place.isAtm), hasLength(20));
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
              const {
                'upload.wikimedia.org',
                'thumb.wikimedia.org',
              }.contains(uri?.host) &&
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
