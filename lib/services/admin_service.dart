import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

Uint8List _compressImageToJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }
  final normalized = img.bakeOrientation(decoded);
  final longestSide = math.max(normalized.width, normalized.height);
  final resized = longestSide > 1280
      ? img.copyResize(
          normalized,
          width: (normalized.width * 1280 / longestSide).round(),
          height: (normalized.height * 1280 / longestSide).round(),
          interpolation: img.Interpolation.average,
        )
      : normalized;
  return img.encodeJpg(resized, quality: 80, chroma: img.JpegChroma.yuv420);
}

class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  AdminService._();

  SupabaseClient get _client => Supabase.instance.client;

  bool get isLoggedIn {
    try {
      return _client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  String get currentUserEmail =>
      _client.auth.currentUser?.email ?? 'Unknown account';

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
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<({int places, int tours})> fetchDashboardCounts() async {
    final results = await Future.wait([
      _client.from('places').select('id').count(),
      _client.from('tours').select('id').count(),
    ]);

    final places = (results[0] as dynamic).count;
    final tours = (results[1] as dynamic).count;
    if (places is! int || tours is! int) {
      throw StateError('Supabase did not return exact dashboard counts.');
    }
    return (places: places, tours: tours);
  }

  Future<int> fetchPhotoCount() async {
    final adminId = adminUserId;
    if (adminId.isEmpty) {
      throw StateError(
        'Cannot identify the signed-in admin for photo moderation.',
      );
    }
    final result = await _client
        .from('place_photos')
        .select('id')
        .or('user_id.is.null,user_id.neq.$adminId')
        .count();
    final count = (result as dynamic).count;
    if (count is! int) {
      throw StateError('Supabase did not return the photo count.');
    }
    return count;
  }

  Future<List<Map<String, dynamic>>> fetchPendingReports() async {
    final response = await _client.rpc(
      'get_pending_reports',
      params: {'p_limit': 100},
    );
    if (response is! List) {
      throw const FormatException('Invalid pending reports response.');
    }
    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchPendingHiddenGems() async {
    final rows = await _client
        .from('suggested_places')
        .select(
          'id,user_id,title,name_ar,description,category,category_ar,'
          'lat,lng,address,image_url,created_at',
        )
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> moderateHiddenGem(String suggestionId, String action) async {
    if (action != 'approve' && action != 'reject') {
      throw ArgumentError.value(action, 'action');
    }
    await _client.rpc(
      'moderate_hidden_gem',
      params: {'p_suggestion_id': suggestionId, 'p_action': action},
    );
  }

  Future<void> dismissReport(String reportId) async {
    await _client
        .from('reports')
        .update({'status': 'dismissed'})
        .eq('id', reportId)
        .eq('status', 'pending');
  }

  Future<void> deleteReportedContent(
    String reportId,
    String targetType,
    String targetId,
  ) async {
    switch (targetType) {
      case 'place':
        await _client.from('places').delete().eq('id', targetId);
        break;
      case 'user':
        await deleteUser(targetId);
        break;
      case 'review':
        throw StateError(
          'Review deletion is not available because reviews are not stored '
          'in a Supabase table yet.',
        );
      default:
        throw ArgumentError.value(targetType, 'targetType');
    }
    await _client
        .from('reports')
        .update({'status': 'resolved'})
        .eq('id', reportId)
        .eq('status', 'pending');
  }

  Future<AdminAnalytics> fetchAdminAnalytics() async {
    final response = await _client.rpc('get_admin_analytics');
    if (response is! Map) {
      throw const FormatException('Invalid admin analytics response.');
    }
    return AdminAnalytics.fromJson(Map<String, dynamic>.from(response));
  }

  Future<({List<AdminUser> users, bool hasMore})> fetchUsers({
    String query = '',
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _client.functions.invoke(
      'admin-user-management',
      body: {
        'action': 'list',
        'query': query,
        'page': page,
        'per_page': perPage,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('User list request failed (${response.status}).');
    }
    final responseData = response.data;
    final dynamic data = switch (responseData) {
      String value => jsonDecode(value),
      Uint8List value => jsonDecode(utf8.decode(value)),
      _ => responseData,
    };
    if (data is! Map<String, dynamic> || data['users'] is! List) {
      throw const FormatException('Invalid user list response.');
    }
    return (
      users: (data['users'] as List<dynamic>)
          .map((user) => AdminUser.fromJson(user as Map<String, dynamic>))
          .toList(),
      hasMore: data['has_more'] == true,
    );
  }

  Future<Map<String, dynamic>> fetchUserVisitState(String userId) async {
    final response = await _client.functions.invoke(
      'admin-user-management',
      body: {'action': 'visits', 'user_id': userId},
    );
    final data = _functionResponseData(response, 'User visits request');
    if (data['visited_place_ids'] is! List) {
      throw const FormatException('Invalid user visits response.');
    }
    return data;
  }

  Future<Map<String, dynamic>> updateUserVisits({
    required String userId,
    required List<String> placeIds,
    required bool add,
  }) async {
    late final Map<String, dynamic> data;
    if (add) {
      final response = await _client.rpc(
        'admin_add_visits_and_sync',
        params: {
          'target_user_id': userId,
          'place_ids': placeIds,
        },
      );
      if (response is! Map) {
        throw const FormatException('Invalid user visits update response.');
      }
      data = Map<String, dynamic>.from(response);
    } else {
      final response = await _client.functions.invoke(
        'admin-user-management',
        body: {
          'action': 'remove_visits',
          'user_id': userId,
          'place_ids': placeIds,
        },
      );
      data = _functionResponseData(response, 'User visits update');
    }
    if (data['visited_place_ids'] is! List ||
        data['badges'] is! List ||
        data['newly_unlocked'] is! List) {
      throw const FormatException('Invalid user visits update response.');
    }
    return data;
  }

  Map<String, dynamic> _functionResponseData(
    FunctionResponse response,
    String requestName,
  ) {
    if (response.status < 200 || response.status >= 300) {
      final responseData = response.data;
      final dynamic data = switch (responseData) {
        String value => jsonDecode(value),
        Uint8List value => jsonDecode(utf8.decode(value)),
        _ => responseData,
      };
      final detail = data is Map<String, dynamic>
          ? data['message'] ?? data['error']
          : null;
      throw StateError(
        '$requestName failed (${response.status})'
        '${detail == null ? '' : ': $detail'}',
      );
    }
    final responseData = response.data;
    final dynamic data = switch (responseData) {
      String value => jsonDecode(value),
      Uint8List value => jsonDecode(utf8.decode(value)),
      _ => responseData,
    };
    if (data is! Map<String, dynamic>) {
      throw FormatException('Invalid $requestName response.');
    }
    return data;
  }

  Future<void> deleteUser(String userId) async {
    final response = await _client.functions.invoke(
      'admin-user-management',
      body: {'action': 'delete', 'user_id': userId},
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final detail = data is Map<String, dynamic>
          ? data['message'] ?? data['error']
          : null;
      throw StateError(
        'User deletion failed (${response.status})'
        '${detail == null ? '' : ': $detail'}',
      );
    }
  }

  Future<({String tier, DateTime? endDate})> setUserSubscriptionPlan(
    String userId,
    String plan,
  ) async {
    final response = await _client.functions.invoke(
      'admin-user-management',
      body: {'action': 'set_plan', 'user_id': userId, 'plan': plan},
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final detail = data is Map<String, dynamic>
          ? data['message'] ?? data['error']
          : null;
      throw StateError(
        'Subscription plan update failed (${response.status})'
        '${detail == null ? '' : ': $detail'}',
      );
    }
    final data = response.data;
    if (data is! Map || data['subscription_tier'] is! String) {
      throw const FormatException('Invalid subscription plan response.');
    }
    return (
      tier: data['subscription_tier'] as String,
      endDate: DateTime.tryParse(
        (data['subscription_end_date'] as String?) ?? '',
      ),
    );
  }

  Future<({List<AdminChatLog> logs, bool hasMore})> fetchAiChatLogs({
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _client.functions.invoke(
      'admin-user-management',
      body: {'action': 'chat_logs', 'page': page, 'per_page': perPage},
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final detail = data is Map<String, dynamic>
          ? data['message'] ?? data['error']
          : null;
      throw StateError(
        'AI chat logs request failed (${response.status})'
        '${detail == null ? '' : ': $detail'}',
      );
    }
    final responseData = response.data;
    final dynamic data = switch (responseData) {
      String value => jsonDecode(value),
      Uint8List value => jsonDecode(utf8.decode(value)),
      _ => responseData,
    };
    final envelope = data is Map
        ? Map<String, dynamic>.fromEntries(
            data.entries
                .where((entry) => entry.key is String)
                .map((entry) => MapEntry(entry.key as String, entry.value)),
          )
        : const <String, dynamic>{};
    final rawItems = data is List
        ? data
        : envelope['threads'] is List
        ? envelope['threads']
        : envelope['sessions'] is List
        ? envelope['sessions']
        : envelope['logs'] is List
        ? envelope['logs']
        : envelope['items'] is List
        ? envelope['items']
        : const <dynamic>[];
    final logs = <AdminChatLog>[];
    for (final item in rawItems as List) {
      final row = _stringKeyedMap(item);
      if (row == null) continue;
      final messages = row['messages'];
      if (messages is List) {
        for (final message in messages) {
          final messageRow = _stringKeyedMap(message);
          if (messageRow == null) continue;
          logs.add(
            AdminChatLog.fromJson({
              ...messageRow,
              'user_id': messageRow['user_id'] ?? row['user_id'],
              'user_email':
                  messageRow['user_email'] ??
                  messageRow['email'] ??
                  row['user_email'] ??
                  row['email'],
              'session_id': messageRow['session_id'] ?? row['session_id'],
            }),
          );
        }
      } else {
        logs.add(AdminChatLog.fromJson(row));
      }
    }
    if (data is! List && envelope.isEmpty && data is! Map) {
      debugPrint(
        'AdminService.fetchAiChatLogs: unrecognised payload type '
        '${data.runtimeType}.',
      );
    }
    return (logs: logs, hasMore: envelope['has_more'] == true);
  }

  Map<String, dynamic>? _stringKeyedMap(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.fromEntries(
      value.entries
          .where((entry) => entry.key is String)
          .map((entry) => MapEntry(entry.key as String, entry.value)),
    );
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
    final row = await _client
        .from('places')
        .insert(place.toJson())
        .select('id, enable_chat, enable_gallery')
        .single();
    _verifyFeatureFlags(row, place);
    return place;
  }

  Future<Place> updatePlace(Place place) async {
    final row = await _client
        .from('places')
        .update(place.toSupabaseUpdate())
        .eq('id', place.id)
        .select('id, enable_chat, enable_gallery')
        .maybeSingle();
    if (row == null) {
      throw StateError('Supabase did not update place ${place.id}.');
    }
    _verifyFeatureFlags(row, place);
    return place;
  }

  Future<List<String>> syncPlaceImageUrls(
    String placeId, {
    required String coverImageUrl,
    required List<String> preferredUrls,
  }) async {
    final merged = <String>[];
    final seen = <String>{};
    void add(String value) {
      final url = value.trim();
      if (url.isNotEmpty && seen.add(url)) merged.add(url);
    }

    add(coverImageUrl);
    for (final url in preferredUrls) {
      add(url);
    }
    final cover = merged.isEmpty ? '' : merged.first;
    final updated = await _client
        .from('places')
        .update({'image_url': cover, 'image_urls': merged})
        .eq('id', placeId)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Supabase did not update the gallery for $placeId.');
    }
    return merged;
  }

  void _verifyFeatureFlags(Map<String, dynamic> row, Place place) {
    if (row['enable_chat'] != place.enableChat ||
        row['enable_gallery'] != place.enableGallery) {
      throw StateError(
        'Supabase saved different feature flags for place ${place.id}.',
      );
    }
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
        throw Exception('Bad entry in drag-and-drop payload: empty place id.');
      }
      placeIds.add(id);
      newOrders.add(e.displayOrder);
    }

    try {
      final result = await _client.rpc(
        'force_update_display_orders',
        params: {'p_place_ids': placeIds, 'p_new_orders': newOrders},
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
      'status': tour.status,
      'is_premium': tour.isPremium,
      'is_hidden_gem': tour.isHiddenGem,
    });
    if (tour.places.isNotEmpty) {
      await _replaceTourWaypoints(
        tour.id,
        tour.places.map((p) => p.id).toList(),
      );
    }
    return tour;
  }

  Future<Tour> updateTour(Tour tour) async {
    await _client
        .from('tours')
        .update(tour.toSupabaseUpdate())
        .eq('id', tour.id);
    await _replaceTourWaypoints(tour.id, tour.places.map((p) => p.id).toList());
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
    String fileName,
  ) async {
    final compressedBytes = await _compressImage(bytes);
    final jpegName = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '.jpg');
    final path = '$folder/$jpegName';
    await _client.storage
        .from(SupabaseConfig.imagesBucket)
        .uploadBinary(
          path,
          compressedBytes,
          fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    final publicUrl = _client.storage
        .from(SupabaseConfig.imagesBucket)
        .getPublicUrl(path);
    final parsedPublicUrl = Uri.parse(publicUrl);
    final verificationUrl = parsedPublicUrl.replace(
      queryParameters: {
        ...parsedPublicUrl.queryParameters,
        'verify': DateTime.now().microsecondsSinceEpoch.toString(),
      },
    );
    final response = await http
        .get(verificationUrl)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'Uploaded image is not publicly reachable '
        '(HTTP ${response.statusCode}).',
      );
    }
    return publicUrl;
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'Image file is empty.');
    }
    return compute(
      _compressImageToJpeg,
      bytes,
      debugLabel: 'Compress admin upload image',
    );
  }

  String publicImageUrl(String path) =>
      _client.storage.from(SupabaseConfig.imagesBucket).getPublicUrl(path);

  Future<List<PlacePhoto>> fetchPhotos({String? placeId}) async {
    final base = _client.from('place_photos').select();
    final filtered = placeId == null ? base : base.eq('place_id', placeId);
    final res = await filtered.order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((e) => PlacePhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlacePhoto>> fetchUserSubmittedPhotos({String? placeId}) async {
    final adminId = adminUserId;
    if (adminId.isEmpty) {
      throw StateError(
        'Cannot identify the signed-in admin for photo moderation.',
      );
    }
    var query = _client
        .from('place_photos')
        .select()
        .or('user_id.is.null,user_id.neq.$adminId');
    if (placeId != null) {
      query = query.eq('place_id', placeId);
    }
    final res = await query.order('created_at', ascending: false);
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
    final photo = await _client
        .from('place_photos')
        .select('image_url')
        .eq('id', id)
        .maybeSingle();
    if (photo == null) {
      throw StateError('Photo $id no longer exists.');
    }
    final imageUrl = photo['image_url'] as String? ?? '';
    final storagePath = _placeImageStoragePath(imageUrl);
    final deleted = await _client
        .from('place_photos')
        .delete()
        .eq('id', id)
        .select('id');
    if ((deleted as List<dynamic>).isEmpty) {
      throw StateError('Supabase did not delete photo $id.');
    }
    if (storagePath != null) {
      await _client.storage.from('place-images').remove([storagePath]);
    }
  }

  String? _placeImageStoragePath(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    final supabaseUri = Uri.tryParse(SupabaseConfig.url);
    if (uri == null || supabaseUri == null || uri.host != supabaseUri.host) {
      return null;
    }
    final segments = uri.pathSegments;
    for (var i = 0; i + 2 < segments.length; i++) {
      if (segments[i] == 'public' && segments[i + 1] == 'place-images') {
        final path = segments.skip(i + 2).join('/');
        return path.isEmpty ? null : path;
      }
    }
    return null;
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
