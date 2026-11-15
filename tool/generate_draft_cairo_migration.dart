import 'dart:convert';
import 'dart:io';

import 'package:streetlore_admin/models/governorates_config.dart';

const _placeColumns = [
  'id',
  'name',
  'name_en',
  'name_ar',
  'description',
  'description_en',
  'description_ar',
  'image_url',
  'image_urls',
  'rating',
  'category',
  'category_ar',
  'lat',
  'lng',
  'address',
  'address_ar',
  'open_hours',
  'review_count',
  'price_level',
  'price_note',
  'price_local_egp',
  'price_foreigner_egp',
  'is_hidden_gem',
  'is_featured',
  'display_order',
  'enable_chat',
  'enable_gallery',
  'governorate',
];

const _tourColumns = [
  'id',
  'title',
  'title_ar',
  'description',
  'description_ar',
  'duration',
  'duration_ar',
  'category',
  'category_ar',
  'image_url',
  'status',
  'is_premium',
  'is_hidden_gem',
  'governorate',
];

String _sqlValue(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'TRUE' : 'FALSE';
  if (value is num) return value.toString();
  if (value is List) {
    final values = value.map((item) => _sqlValue(item)).join(', ');
    return 'ARRAY[$values]::text[]';
  }
  if (value is String) return "'${value.replaceAll("'", "''")}'";
  throw ArgumentError.value(value, 'value', 'Unsupported SQL seed type.');
}

String _insert({
  required String table,
  required List<String> columns,
  required List<Map<String, dynamic>> rows,
  required String conflict,
}) {
  final values = rows
      .map(
        (row) =>
            '  (${columns.map((column) => _sqlValue(row[column])).join(', ')})',
      )
      .join(',\n');
  final updates = columns
      .where((column) => column != 'id')
      .map((column) => '  $column = EXCLUDED.$column')
      .join(',\n');
  return '''INSERT INTO public.$table (
  ${columns.join(', ')}
)
VALUES
$values
ON CONFLICT ($conflict) DO UPDATE SET
$updates;''';
}

Future<void> main() async {
  final seedFile = File(
    r'D:\codes\streetlore_admin\assets\governorate_preview_seed.json',
  );
  final decoded = jsonDecode(await seedFile.readAsString()) as Map;
  final places = (decoded['places'] as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .where(
        (row) =>
            {'cairo', 'luxor'}.contains(row['governorate']) ||
            (row['governorate'] == 'alexandria' &&
                const {'ATM', 'ATMs'}.contains(row['category'])),
      )
      .toList();
  final tours = (decoded['tours'] as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .where((row) => {'cairo', 'luxor'}.contains(row['governorate']))
      .toList();

  final luxorPlaces = places
      .where((place) => place['governorate'] == 'luxor')
      .toList();
  final luxorTours = tours
      .where((tour) => tour['governorate'] == 'luxor')
      .toList();
  if (places.where((place) => place['governorate'] == 'cairo').length < 120 ||
      tours.where((tour) => tour['governorate'] == 'cairo').length < 5 ||
      luxorPlaces.length != 120 ||
      luxorTours.length != 12) {
    throw StateError(
      'Expected at least 120 Cairo places and 5 tours, plus 120 Luxor & '
      'Aswan places with 12 tours.',
    );
  }
  final ids = places.map((place) => place['id'] as String).toSet();
  if (ids.length != places.length ||
      places.any(
        (place) => !isPointInGovernorate(
          (place['lat'] as num).toDouble(),
          (place['lng'] as num).toDouble(),
          place['governorate'] as String,
        ),
      )) {
    throw StateError('Seed IDs or governorate boundary validation failed.');
  }
  for (final tour in tours) {
    final stops = tour['places'] as List;
    final governorate = tour['governorate'];
    if (stops.isEmpty ||
        stops.any((stop) => (stop as Map)['governorate'] != governorate)) {
      throw StateError('$governorate tour contains an invalid stop.');
    }
  }

  final placeRows = places
      .map(
        (place) => {
          ...place,
          'name_en': place['name'],
          'description_en': place['description'],
        },
      )
      .toList();
  final tourRows = tours
      .map(
        (tour) => {
          for (final column in _tourColumns)
            column: switch (column) {
              'category' => tour['category'] ?? 'Heritage',
              'category_ar' => tour['category_ar'] ?? 'تراث',
              _ => tour[column],
            },
        },
      )
      .toList();

  final tourIds = tours.map((tour) => tour['id'] as String).toList();
  final stopRows = <String>[];
  for (final tour in tours) {
    final stops = tour['places'] as List;
    for (var index = 0; index < stops.length; index++) {
      final stop = Map<String, dynamic>.from(stops[index] as Map);
      stopRows.add(
        '  (${_sqlValue(tour['id'])}, ${_sqlValue(stop['id'])}, $index)',
      );
    }
  }
  final deleteTourIds = tourIds.map(_sqlValue).join(', ');
  final sql =
      '''-- DRAFT ONLY: do not apply to production until the Play review is complete.
-- Generated from the verified local Alexandria/Cairo/Luxor/Aswan preview seed.
BEGIN;

ALTER TABLE public.places
  ADD COLUMN IF NOT EXISTS governorate text NOT NULL DEFAULT 'alexandria';
UPDATE public.places
SET governorate = 'alexandria'
WHERE governorate IS NULL OR btrim(governorate) = '';
ALTER TABLE public.places
  ALTER COLUMN governorate SET DEFAULT 'alexandria',
  ALTER COLUMN governorate SET NOT NULL;

ALTER TABLE public.tours
  ADD COLUMN IF NOT EXISTS governorate text NOT NULL DEFAULT 'alexandria';
UPDATE public.tours
SET governorate = 'alexandria'
WHERE governorate IS NULL OR btrim(governorate) = '';
ALTER TABLE public.tours
  ALTER COLUMN governorate SET DEFAULT 'alexandria',
  ALTER COLUMN governorate SET NOT NULL;

UPDATE public.places SET governorate = 'luxor' WHERE governorate = 'aswan';
UPDATE public.tours SET governorate = 'luxor' WHERE governorate = 'aswan';

ALTER TABLE public.places
  DROP CONSTRAINT IF EXISTS places_governorate_check;
ALTER TABLE public.places
  ADD CONSTRAINT places_governorate_check
  CHECK (governorate IN ('alexandria', 'cairo', 'luxor'));

ALTER TABLE public.tours
  DROP CONSTRAINT IF EXISTS tours_governorate_check;
ALTER TABLE public.tours
  ADD CONSTRAINT tours_governorate_check
  CHECK (governorate IN ('alexandria', 'cairo', 'luxor'));

ALTER TABLE public.places
  DROP CONSTRAINT IF EXISTS places_category_check;
ALTER TABLE public.places
  ADD CONSTRAINT places_category_check CHECK (
    category IN (
      'Historical', 'Culture', 'Nature', 'Food', 'Cafe', 'Shopping',
      'Mosques', 'Churches', 'Streets', 'Hotels', 'ATM', 'ATMs'
    )
  );

CREATE INDEX IF NOT EXISTS idx_places_governorate
  ON public.places USING btree (governorate);
CREATE INDEX IF NOT EXISTS idx_tours_governorate
  ON public.tours USING btree (governorate);

${_insert(table: 'places', columns: _placeColumns, rows: placeRows, conflict: 'id')}

${_insert(table: 'tours', columns: _tourColumns, rows: tourRows, conflict: 'id')}

DELETE FROM public.tour_places
WHERE tour_id IN ($deleteTourIds);
INSERT INTO public.tour_places (tour_id, place_id, position)
VALUES
${stopRows.join(',\n')}
ON CONFLICT (tour_id, place_id) DO UPDATE
SET position = EXCLUDED.position;

CREATE OR REPLACE VIEW public.tours_with_places AS
SELECT
  t.id,
  t.title,
  t.title_ar,
  t.description,
  t.description_ar,
  t.duration,
  t.duration_ar,
  t.category,
  t.category_ar,
  t.image_url,
  t.created_at,
  t.updated_at,
  COALESCE(
    (
      SELECT json_agg(
        json_build_object(
          'id', p.id,
          'name', p.name,
          'name_ar', p.name_ar,
          'description', p.description,
          'description_ar', p.description_ar,
          'image_url', p.image_url,
          'imageUrl', p.image_url,
          'image_urls', p.image_urls,
          'rating', p.rating,
          'category', p.category,
          'category_ar', p.category_ar,
          'lat', p.lat,
          'lng', p.lng,
          'address', p.address,
          'address_ar', p.address_ar,
          'open_hours', p.open_hours,
          'openHours', p.open_hours,
          'review_count', p.review_count,
          'reviewCount', p.review_count,
          'price_level', p.price_level,
          'priceLevel', p.price_level,
          'price_note', p.price_note,
          'priceNote', p.price_note,
          'price_local_egp', p.price_local_egp,
          'priceLocalEgp', p.price_local_egp,
          'price_foreigner_egp', p.price_foreigner_egp,
          'priceForeignerEgp', p.price_foreigner_egp,
          'is_hidden_gem', p.is_hidden_gem,
          'isHiddenGem', p.is_hidden_gem,
          'is_featured', p.is_featured,
          'governorate', p.governorate,
          'display_order', p.display_order,
          'enable_chat', p.enable_chat,
          'enable_gallery', p.enable_gallery
        )
        ORDER BY tp.position
      )
      FROM public.tour_places tp
      JOIN public.places p ON p.id = tp.place_id
      WHERE tp.tour_id = t.id
    ),
    '[]'::json
  ) AS places,
  t.status,
  t.view_count,
  t.is_premium,
  t.is_hidden_gem,
  t.governorate
FROM public.tours t;

COMMIT;
''';

  final output = File.fromUri(
    Platform.script.resolve('draft_cairo_multi_governorate.sql'),
  );
  await output.writeAsString(sql);
  stdout.writeln(
    'Wrote local-only draft SQL with ${places.length} Cairo and '
    'Luxor & Aswan places plus Alexandria ATMs, ${tours.length} itineraries, and '
    '${stopRows.length} ordered stops '
    '(${luxorPlaces.length} Luxor & Aswan places, '
    '${luxorTours.length} Luxor & Aswan tours).',
  );
}
