import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class AdminService {
  static AdminService? _instance;
  static AdminService get instance =>
      _instance ??= AdminService._();
  AdminService._();

  SupabaseClient get _client => Supabase.instance.client;

  bool get isLoggedIn {
    try {
      return _client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<List<Place>> fetchPlaces() async {
    final res = await _client
        .from('places')
        .select()
        .order('id', ascending: true);
    return (res as List<dynamic>)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Place> createPlace(Place place) async {
    await _client.from('places').insert(place.toJson());
    return place;
  }

  Future<Place> updatePlace(Place place) async {
    await _client
        .from('places')
        .update(place.toSupabaseUpdate())
        .eq('id', place.id);
    return place;
  }

  /// Batch update display_order for many places at once (used by the
  /// drag-and-drop UI). Each entry is a {id, displayOrder} pair.
  ///
  /// v1.0.66 rewrite — verify-after-write strategy:
  ///   1. Send every UPDATE individually.
  ///   2. Re-fetch all rows from Supabase with a SELECT.
  ///   3. Compare the actual `display_order` of each id against the
  ///      intended value. If anything is off, throw with a full diff so
  ///      the UI can surface a real error and roll back the optimistic
  ///      re-order. This catches every silent-RLS, network-truncated,
  ///      and missing-row failure mode — the previous `.select('id')`
  ///      on the UPDATE response was unreliable under RLS.
  Future<void> updateDisplayOrders(
    List<({String id, int displayOrder})> entries,
  ) async {
    if (entries.isEmpty) return;

    // Phase 1 — fire every UPDATE.
    final expected = <String, int>{
      for (final e in entries) e.id: e.displayOrder,
    };
    final updateErrors = <String>[];
    for (final e in entries) {
      try {
        await _client
            .from('places')
            .update({'display_order': e.displayOrder})
            .eq('id', e.id);
      } on PostgrestException catch (err) {
        updateErrors.add('${e.id} [${err.code}] ${err.message}');
        debugPrint(
          'AdminService.updateDisplayOrders: PostgrestException for '
          'id=${e.id}: ${err.code} ${err.message}',
        );
      } catch (err) {
        updateErrors.add('$e.id $err');
        debugPrint(
          'AdminService.updateDisplayOrders: error for id=${e.id}: $err',
        );
      }
    }

    // Phase 2 — re-fetch every id and verify the value actually landed.
    // We pull the whole places table (admin can read everything) and
    // filter to the ids we just touched, since the supabase_flutter
    // version pinned here doesn't expose `.inFilter()` / `.in_()`.
    final ids = entries.map((e) => e.id).toList(growable: false);
    final allPlaces = await _client
        .from('places')
        .select('id, display_order') as List<dynamic>;
    final rows = allPlaces
        .where((r) => ids.contains((r as Map<String, dynamic>)['id']))
        .map<({String id, int displayOrder})>((r) {
          final m = r as Map<String, dynamic>;
          return (
            id: m['id'] as String,
            displayOrder: (m['display_order'] as num?)?.toInt() ?? -1,
          );
        })
        .toList();

    final mismatches = <String>[];
    final missing = <String>[];
    final seen = <String>{};
    for (final row in rows) {
      seen.add(row.id);
      final want = expected[row.id];
      if (want == null) continue;
      if (row.displayOrder != want) {
        mismatches.add(
          '${row.id}: expected $want, DB has ${row.displayOrder}',
        );
      }
    }
    for (final id in ids) {
      if (!seen.contains(id)) missing.add(id);
    }

    if (updateErrors.isNotEmpty || mismatches.isNotEmpty || missing.isNotEmpty) {
      final buf = StringBuffer(
        'display_order save FAILED — Supabase did not persist the new order.\n\n',
      );
      if (updateErrors.isNotEmpty) {
        buf.writeln(
          'UPDATE errors (${updateErrors.length}):\n  • '
          '${updateErrors.take(5).join("\n  • ")}'
          '${updateErrors.length > 5 ? "\n  • …" : ""}\n',
        );
      }
      if (mismatches.isNotEmpty) {
        buf.writeln(
          'VERIFY mismatches (${mismatches.length}):\n  • '
          '${mismatches.take(5).join("\n  • ")}'
          '${mismatches.length > 5 ? "\n  • …" : ""}\n',
        );
      }
      if (missing.isNotEmpty) {
        buf.writeln(
          'Missing rows (${missing.length}): ${missing.take(5).join(", ")}'
          '${missing.length > 5 ? ", …" : ""}\n',
        );
      }
      buf.writeln(
        'This almost always means the Supabase places table is missing '
        'an UPDATE policy for the admin account. Run '
        'supabase/migrations/2026_10_03_admin_places_rls.sql.',
      );
      throw Exception(buf.toString());
    }
  }

  Future<void> deletePlace(String id) async {
    await _client.from('places').delete().eq('id', id);
  }

  Future<List<Tour>> fetchTours() async {
    final res = await _client
        .from('tours_with_places')
        .select()
        .order('id', ascending: true);
    return (res as List<dynamic>)
        .map((e) => Tour.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Tour> createTour(Tour tour) async {
    await _client.from('tours').insert({
      'id': tour.id,
      'title': tour.title,
      'description': tour.description,
      'duration': tour.duration,
      'image_url': tour.imageUrl,
    });
    if (tour.places.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < tour.places.length; i++) {
        rows.add({
          'tour_id': tour.id,
          'place_id': tour.places[i].id,
          'position': i,
        });
      }
      await _client.from('tour_places').insert(rows);
    }
    return tour;
  }

  Future<Tour> updateTour(Tour tour) async {
    await _client
        .from('tours')
        .update(tour.toSupabaseUpdate())
        .eq('id', tour.id);
    await _client.from('tour_places').delete().eq('tour_id', tour.id);
    if (tour.places.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < tour.places.length; i++) {
        rows.add({
          'tour_id': tour.id,
          'place_id': tour.places[i].id,
          'position': i,
        });
      }
      await _client.from('tour_places').insert(rows);
    }
    return tour;
  }

  Future<void> deleteTour(String id) async {
    await _client.from('tours').delete().eq('id', id);
  }

  Future<String> uploadImageBytes(
    Uint8List bytes,
    String folder,
    String fileName, {
    String contentType = 'image/jpeg',
  }) async {
    final path = '$folder/$fileName';
    await _client.storage.from(SupabaseConfig.imagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage
        .from(SupabaseConfig.imagesBucket)
        .getPublicUrl(path);
  }

  String publicImageUrl(String path) => _client.storage
      .from(SupabaseConfig.imagesBucket)
      .getPublicUrl(path);

  Future<List<PlacePhoto>> fetchPhotos({String? placeId}) async {
    final base = _client.from('place_photos').select();
    final filtered = placeId == null ? base : base.eq('place_id', placeId);
    final res = await filtered.order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((e) => PlacePhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlacePhoto> createPhoto(PlacePhoto photo) async {
    await _client.from('place_photos').insert(photo.toJson());
    return photo;
  }

  Future<PlacePhoto> updatePhoto(PlacePhoto photo) async {
    await _client
        .from('place_photos')
        .update(photo.toSupabaseUpdate())
        .eq('id', photo.id);
    return photo;
  }

  Future<void> deletePhoto(String id) async {
    await _client.from('place_photos').delete().eq('id', id);
  }

  /// v1.0.64: Granular moderation — fetch every chat message for a
  /// specific place, newest first. Uses the `place_chat` table (the same
  /// table the mobile ChatProvider writes to).
  Future<List<ChatMessage>> fetchChatMessages(String placeId) async {
    final res = await _client
        .from('place_chat')
        .select()
        .eq('place_id', placeId)
        .order('sent_at', ascending: false);
    return (res as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// v1.0.64: Granular moderation — delete a single chat message by id.
  /// RLS policy `admin can delete place_chat` (see migration
  /// `2026_10_03_admin_moderation.sql`) authorizes the admin user.
  Future<void> deleteChatMessage(String id) async {
    await _client.from('place_chat').delete().eq('id', id);
  }
}
