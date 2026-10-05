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

  /// v1.0.72 — the signed-in admin's auth.uid() (JWT subject). Required
  /// for the RLS policy `user_id::text = auth.uid()::text` to admit
  /// admin-owned INSERTs into `place_photos`.
  String get adminUserId {
    try {
      return _client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
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
    // v1.0.69 fix: sort by display_order first, then by id. Previously
    // this only ordered by id, which made the admin page always show
    // places in DB insertion order — so drag-and-drop reorders looked
    // like they "reverted on refresh" even though the RPC had actually
    // written the new display_order values. The mobile app already uses
    // the same sort, so the admin UI now matches what users see in the
    // app.
    final res = await _client
        .from('places')
        .select()
        .order('display_order', ascending: true)
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
  /// v1.0.67/68 Sledgehammer — we no longer use the client-side
  /// `.update()` path which was silently failing under Supabase RLS.
  /// Instead we call a single RPC `force_update_display_orders(
  /// p_place_ids text[], p_new_orders int[])` that is declared with
  /// `postgres` ownership (`SECURITY DEFINER`) so it bypasses every
  /// places RLS policy. The function also gates on the admin's JWT email
  /// and raises a hard SQL EXCEPTION if the call is unauthorized or any
  /// row couldn't be updated — PostgREST surfaces that as a real
  /// PostgrestException which Flutter can NOT mistake for success.
  ///
  /// v1.0.68 fix: places.id is TEXT (some rows are plain integers like
  /// "10" / "11"), so the RPC accepts text[] and the client passes ids
  /// through verbatim with no UUID parsing.
  Future<void> updateDisplayOrders(
    List<({String id, int displayOrder})> entries,
  ) async {
    if (entries.isEmpty) return;

    // Pass place ids through verbatim — places.id is TEXT, not UUID.
    // Empty / whitespace-only ids are still rejected locally so we get a
    // clean error message instead of a Postgres EXCEPTION.
    final placeIds = <String>[];
    final newOrders = <int>[];
    for (final e in entries) {
      final id = e.id.trim();
      if (id.isEmpty) {
        throw Exception(
          'Bad entry in drag-and-drop payload: empty place id.',
        );
      }
      placeIds.add(id);
      newOrders.add(e.displayOrder);
    }

    try {
      final result = await _client.rpc(
        'force_update_display_orders',
        params: {
          'p_place_ids': placeIds,
          'p_new_orders': newOrders,
        },
      );
      // RPC returned without raising. Verify the return table actually
      // contains every requested id with the requested order — the SQL
      // function only does this check inside itself, but if the function
      // definition ever drifts, this is the last line of defence.
      final rows = (result as List<dynamic>)
          .map<({String id, int displayOrder})>((r) {
            final m = r as Map<String, dynamic>;
            return (
              id: m['updated_id'] as String,
              displayOrder: (m['updated_order'] as num).toInt(),
            );
          })
          .toList();
      final expected = <String, int>{
        for (final e in entries) e.id: e.displayOrder,
      };
      final mismatches = <String>[];
      for (final row in rows) {
        final want = expected[row.id];
        if (want == null) continue;
        if (row.displayOrder != want) {
          mismatches.add(
            '${row.id}: expected $want, DB has ${row.displayOrder}',
          );
        }
      }
      if (rows.length != entries.length || mismatches.isNotEmpty) {
        throw Exception(
          'force_update_display_orders returned '
          '${rows.length} rows, expected ${entries.length}.\n'
          '${mismatches.isEmpty ? "" : "Mismatches: ${mismatches.join(", ")}"}',
        );
      }
    } on PostgrestException catch (err) {
      // Hard SQL EXCEPTION — surface verbatim.
      debugPrint(
        'AdminService.updateDisplayOrders: PostgrestException '
        '${err.code} ${err.message}',
      );
      throw Exception(
        'force_update_display_orders REJECTED by Supabase.\n\n'
        'code: ${err.code}\n'
        'message: ${err.message}\n\n'
        'If "Unauthorized" — make sure you are signed in with the admin '
        'account and re-run 2026_10_03_admin_force_update_display_orders.sql.\n'
        'If "array length mismatch" / "missing ids" — the RPC did not '
        'write every row; refresh and try again.',
      );
    } catch (err) {
      debugPrint('AdminService.updateDisplayOrders: $err');
      rethrow;
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
      'title_ar': tour.titleAr ?? '',
      'description': tour.description,
      'description_ar': tour.descriptionAr ?? '',
      'duration': tour.duration,
      'duration_ar': tour.durationAr ?? '',
      'category': tour.category,
      'category_ar': tour.categoryAr ?? '',
      'image_url': tour.imageUrl,
    });
    if (tour.places.isNotEmpty) {
      await _replaceTourWaypoints(tour.id, tour.places.map((p) => p.id).toList());
    }
    return tour;
  }

  Future<Tour> updateTour(Tour tour) async {
    await _client
        .from('tours')
        .update(tour.toSupabaseUpdate())
        .eq('id', tour.id);
    await _replaceTourWaypoints(
      tour.id,
      tour.places.map((p) => p.id).toList(),
    );
    return tour;
  }

  Future<void> deleteTour(String id) async {
    // The tour_places rows are removed by the `on delete cascade` FK on
    // tour_places.tour_id. (Migration 004 leaves that FK in place.)
    await _client.from('tours').delete().eq('id', id);
  }

  /// Batch-rewrite every waypoint row for [tourId] to match
  /// [orderedPlaceIds]. Done as delete-all + insert-all so the final
  /// ordering is identical to the admin's drag-and-drop state regardless
  /// of how many stops were reordered. Runs inside the admin RLS
  /// policies declared in migration 004.
  Future<void> _replaceTourWaypoints(
    String tourId,
    List<String> orderedPlaceIds,
  ) async {
    await _client.from('tour_places').delete().eq('tour_id', tourId);
    if (orderedPlaceIds.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedPlaceIds.length; i++) {
      rows.add({
        'tour_id': tourId,
        'place_id': orderedPlaceIds[i],
        'position': i,
      });
    }
    await _client.from('tour_places').insert(rows);
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
