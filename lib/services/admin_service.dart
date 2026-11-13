import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show ValueNotifier, compute, debugPrint;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/governorate_preview_seed.dart';
import '../models/models.dart';
import 'local_draft_store.dart';
import 'visit_progress.dart';

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

class PlaceSaveResult {
  const PlaceSaveResult({required this.remoteSynced, this.remoteError});

  final bool remoteSynced;
  final Object? remoteError;
}

class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  AdminService._();

  static const _draftModePreferenceKey = 'streetlore-admin-local-draft-mode';
  static final ValueNotifier<bool> localDraftMode = ValueNotifier(false);
  final LocalDraftStore _localDrafts = LocalDraftStore();
  Future<({List<Place> places, List<Tour> tours})>? _previewSeedFuture;

  SupabaseClient get _client => Supabase.instance.client;

  bool get isLocalDraftMode => localDraftMode.value;

  void _requireLiveWrites(String operation) {
    if (isLocalDraftMode) {
      throw StateError(
        '$operation is disabled while Local Draft Mode is active.',
      );
    }
  }

  Future<void> initializeLocalDraftMode() {
    localDraftMode.value = false;
    return Future<void>.value();
  }

  Future<void> setLocalDraftMode(bool enabled) async {
    if (!enabled && !isLoggedIn) {
      throw StateError('Sign in before enabling live database writes.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_draftModePreferenceKey, enabled);
    localDraftMode.value = enabled;
  }

  Future<({List<Place> places, List<Tour> tours})> _previewSeed() =>
      _previewSeedFuture ??= GovernoratePreviewSeed.load();

  List<T> _mergeById<T>(
    Iterable<T> seeds,
    Iterable<T> remote, {
    required String Function(T) idOf,
    Iterable<T> drafts = const [],
    Set<String> deletedIds = const {},
  }) {
    final merged = <String, T>{};
    for (final record in seeds) {
      merged[idOf(record)] = record;
    }
    for (final record in remote) {
      merged[idOf(record)] = record;
    }
    for (final record in drafts) {
      merged[idOf(record)] = record;
    }
    for (final id in deletedIds) {
      merged.remove(id);
    }
    return merged.values.toList(growable: true);
  }

  bool get isLoggedIn {
    try {
      return _client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  static const _adminEmails = {
    'mohamedsabae50@gmail.com',
    'hackty65@gmail.com',
  };

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
    if (isLocalDraftMode) {
      final places = await fetchPlaces();
      final tours = await fetchTours();
      return (places: places.length, tours: tours.length);
    }
    final seed = await _previewSeed();
    final results = await Future.wait([
      _client.from('places').select('id'),
      _client.from('tours').select('id'),
    ]);
    final placeIds = {for (final place in seed.places) place.id};
    final tourIds = {for (final tour in seed.tours) tour.id};
    for (final row in results[0] as List<dynamic>) {
      placeIds.add((row as Map<String, dynamic>)['id'] as String);
    }
    for (final row in results[1] as List<dynamic>) {
      tourIds.add((row as Map<String, dynamic>)['id'] as String);
    }
    return (places: placeIds.length, tours: tourIds.length);
  }

  Future<int> fetchPhotoCount() async {
    if (isLocalDraftMode) return 0;
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
    _requireLiveWrites('Hidden-gem moderation');
    if (action != 'approve' && action != 'reject') {
      throw ArgumentError.value(action, 'action');
    }
    await _client.rpc(
      'moderate_hidden_gem',
      params: {'p_suggestion_id': suggestionId, 'p_action': action},
    );
  }

  Future<void> dismissReport(String reportId) async {
    _requireLiveWrites('Report moderation');
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
    _requireLiveWrites('Reported-content deletion');
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
    final response = await _invokeAdminFunction(
      body: {
        'action': 'list',
        'query': query,
        'page': page,
        'per_page': perPage,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw await _adminFunctionError(
        'User list request',
        response.status,
        response.data,
      );
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
    final response = await _invokeAdminFunction(
      body: {'action': 'visits', 'user_id': userId},
    );
    final data = await _functionResponseData(response, 'User visits request');
    if (data['visited_place_ids'] is! List) {
      throw const FormatException('Invalid user visits response.');
    }
    return _filterAtmVisits(data, await fetchPlaces());
  }

  Future<Map<String, dynamic>> updateUserVisits({
    required String userId,
    required List<String> placeIds,
    required bool add,
  }) async {
    _requireLiveWrites('Visit editing');
    final places = await fetchPlaces();
    final placesById = {for (final place in places) place.id: place};
    final requestedIds = placeIds.toSet();
    final unknownIds = requestedIds
        .where((id) => !placesById.containsKey(id))
        .toList(growable: false);
    if (unknownIds.isNotEmpty) {
      throw ArgumentError('Unknown place id(s): ${unknownIds.join(', ')}');
    }
    final eligibleIds = visitEligiblePlaces(
      requestedIds.map((id) => placesById[id]!),
    ).map((place) => place.id).toList(growable: false);
    if (eligibleIds.isEmpty) return fetchUserVisitState(userId);
    try {
      if (add) {
        await _ensureRemotePlaces(eligibleIds, placesById);
      }
      final response = await _invokeAdminFunction(
        body: {
          'action': add ? 'add_visits' : 'remove_visits',
          'user_id': userId,
          'place_ids': eligibleIds,
        },
      );
      final data = await _functionResponseData(response, 'User visits update');
      if (data['visited_place_ids'] is! List ||
          data['badges'] is! List ||
          data['newly_unlocked'] is! List) {
        throw const FormatException('Invalid user visits update response.');
      }
      return _filterAtmVisits(data, places);
    } catch (edgeError) {
      try {
        return await _updateUserVisitsDirectly(
          userId: userId,
          placeIds: eligibleIds,
          add: add,
          places: places,
        );
      } catch (fallbackError) {
        throw StateError(
          'User visits update failed in the Edge Function ($edgeError) and '
          'the direct database fallback ($fallbackError).',
        );
      }
    }
  }

  Future<Map<String, dynamic>> _updateUserVisitsDirectly({
    required String userId,
    required List<String> placeIds,
    required bool add,
    required List<Place> places,
  }) async {
    await _requireAdminForDirectVisitWrites();
    Object? lastMissingTableError;
    for (final table in const ['user_visits', 'visits']) {
      try {
        final currentRows = await _client
            .from(table)
            .select('place_id')
            .eq('user_id', userId);
        final currentIds = (currentRows as List<dynamic>)
            .map((row) => (row as Map<String, dynamic>)['place_id'] as String)
            .toSet();
        final eligibleIds = visitEligiblePlaces(
          places,
        ).map((place) => place.id).toSet();
        final previousPlaceCount = currentIds.intersection(eligibleIds).length;
        var addedCount = 0;
        var removedCount = 0;
        if (add) {
          final missingIds = placeIds
              .where((id) => !currentIds.contains(id))
              .toList(growable: false);
          if (missingIds.isNotEmpty) {
            await _client.from(table).insert([
              for (final id in missingIds) {'user_id': userId, 'place_id': id},
            ]);
          }
          addedCount = missingIds.length;
        } else {
          removedCount = currentIds.intersection(placeIds.toSet()).length;
          await _client
              .from(table)
              .delete()
              .eq('user_id', userId)
              .inFilter('place_id', placeIds);
        }

        final updatedRows = await _client
            .from(table)
            .select('place_id')
            .eq('user_id', userId);
        final visitedIds = (updatedRows as List<dynamic>)
            .map((row) => (row as Map<String, dynamic>)['place_id'] as String)
            .where(eligibleIds.contains)
            .toSet();
        final leaderboard = await _syncDirectVisitCount(
          userId: userId,
          placeCount: visitedIds.length,
          previousPlaceCount: previousPlaceCount,
        );
        return {
          'visited_place_ids': visitedIds.toList(growable: false),
          'places_visited': visitedIds.length,
          'added_count': addedCount,
          'removed_count': removedCount,
          'total_points': leaderboard['total_points'] ?? 0,
          'badges': leaderboard['badges'] is List
              ? leaderboard['badges']
              : const <dynamic>[],
          'newly_unlocked': leaderboard['newly_unlocked'] is List
              ? leaderboard['newly_unlocked']
              : const <dynamic>[],
          'fallback_used': true,
        };
      } on PostgrestException catch (error) {
        if (!_isMissingVisitTable(error) || table == 'visits') rethrow;
        lastMissingTableError = error;
      }
    }
    throw StateError(
      'No supported visit table was found: $lastMissingTableError',
    );
  }

  Future<void> _requireAdminForDirectVisitWrites() async {
    final email = _client.auth.currentUser?.email?.trim().toLowerCase() ?? '';
    if (_adminEmails.contains(email)) return;
    final isAdmin = await _client.rpc('is_admin') == true;
    if (!isAdmin) {
      throw StateError(
        'Direct visit writes require an authenticated admin session.',
      );
    }
  }

  bool _isMissingVisitTable(PostgrestException error) =>
      error.code == '42P01' || error.code == 'PGRST205';

  Future<Map<String, dynamic>> _syncDirectVisitCount({
    required String userId,
    required int placeCount,
    required int previousPlaceCount,
  }) async {
    final current = await _client
        .from('leaderboard')
        .select('total_points,places_visited,badges')
        .eq('user_id', userId)
        .maybeSingle();
    final progress = calculateVisitProgress(
      currentPoints: (current?['total_points'] as num?)?.toInt() ?? 0,
      previousPlaceCount: current == null
          ? 0
          : (current['places_visited'] as num?)?.toInt() ?? previousPlaceCount,
      placeCount: placeCount,
      currentBadges: current?['badges'] is List
          ? current!['badges'] as List<dynamic>
          : const <dynamic>[],
    );
    if (current == null) {
      await _client.from('leaderboard').insert({
        'user_id': userId,
        'user_name': '',
        'total_points': progress.totalPoints,
        'places_visited': placeCount,
        'badges': progress.badges,
        'level': 'Explorer',
      });
      return {
        'total_points': progress.totalPoints,
        'badges': progress.badges,
        'newly_unlocked': progress.newlyUnlocked,
      };
    }
    await _client
        .from('leaderboard')
        .update({
          'places_visited': placeCount,
          'total_points': progress.totalPoints,
          'badges': progress.badges,
        })
        .eq('user_id', userId);
    return {
      'total_points': progress.totalPoints,
      'badges': progress.badges,
      'newly_unlocked': progress.newlyUnlocked,
    };
  }

  Future<void> _ensureRemotePlaces(
    List<String> placeIds,
    Map<String, Place> placesById,
  ) async {
    final rows = await _client
        .from('places')
        .select('id')
        .inFilter('id', placeIds);
    final remoteIds = (rows as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['id'] as String)
        .toSet();
    for (final id in placeIds) {
      if (remoteIds.contains(id)) continue;
      final place = placesById[id];
      if (place == null) {
        throw StateError('Cannot find place $id to prepare its visit.');
      }
      await _upsertPlace(place);
      await _localDrafts.savePlace(place);
    }
  }

  Map<String, dynamic> _filterAtmVisits(
    Map<String, dynamic> state,
    List<Place> places,
  ) {
    final eligibleIds = visitEligiblePlaces(
      places,
    ).map((place) => place.id).toSet();
    final visitedIds = (state['visited_place_ids'] as List)
        .map((id) => id.toString())
        .where(eligibleIds.contains)
        .toSet();
    return {
      ...state,
      'visited_place_ids': visitedIds.toList(growable: false),
      'places_visited': visitedIds.length,
    };
  }

  Future<FunctionResponse> _invokeAdminFunction({
    required Map<String, dynamic> body,
  }) async {
    try {
      return await _client.functions.invoke(
        'admin-user-management',
        body: body,
      );
    } on FunctionException catch (error) {
      if (error.status == 403) {
        throw await _adminFunctionError(
          'Admin request',
          error.status,
          error.details,
        );
      }
      rethrow;
    }
  }

  dynamic _decodeFunctionData(dynamic responseData) => switch (responseData) {
    String value => jsonDecode(value),
    Uint8List value => jsonDecode(utf8.decode(value)),
    _ => responseData,
  };

  Future<StateError> _adminFunctionError(
    String requestName,
    int status,
    dynamic responseData,
  ) async {
    final data = _decodeFunctionData(responseData);
    final detail = data is Map ? data['message'] ?? data['error'] : null;
    if (status == 403 || detail == 'forbidden') {
      final email = _client.auth.currentUser?.email?.trim() ?? '';
      var isAdmin = _adminEmails.contains(email.toLowerCase());
      try {
        isAdmin = isAdmin || await _client.rpc('is_admin') == true;
      } catch (_) {
        // The current email still identifies the two configured admin accounts.
      }
      if (!isAdmin) {
        return StateError(
          'The current session (${email.isEmpty ? 'Unknown account' : email}) '
          'is not an admin. Sign out of the test account and sign in to '
          'StreetLore Admin as mohamedsabae50@gmail.com.',
        );
      }
      return StateError(
        '$requestName was rejected for the admin session ($email). '
        'Sign out and sign back in to refresh the admin session.',
      );
    }
    return StateError(
      '$requestName failed ($status)'
      '${detail == null ? '' : ': $detail'}',
    );
  }

  Future<Map<String, dynamic>> _functionResponseData(
    FunctionResponse response,
    String requestName,
  ) async {
    if (response.status < 200 || response.status >= 300) {
      throw await _adminFunctionError(
        requestName,
        response.status,
        response.data,
      );
    }
    final data = _decodeFunctionData(response.data);
    if (data is! Map<String, dynamic>) {
      throw FormatException('Invalid $requestName response.');
    }
    return data;
  }

  Future<void> deleteUser(String userId) async {
    _requireLiveWrites('User deletion');
    final response = await _invokeAdminFunction(
      body: {'action': 'delete', 'user_id': userId},
    );
    if (response.status < 200 || response.status >= 300) {
      throw await _adminFunctionError(
        'User deletion',
        response.status,
        response.data,
      );
    }
  }

  Future<({String tier, DateTime? endDate})> setUserSubscriptionPlan(
    String userId,
    String plan,
  ) async {
    _requireLiveWrites('Subscription changes');
    final normalizedPlan = switch (plan.toLowerCase().trim()) {
      'yearly' => 'annual',
      'pro' => 'lifetime',
      final value => value,
    };
    final durationDays = switch (normalizedPlan) {
      'weekly' => 7,
      'monthly' => 30,
      'annual' => 365,
      _ => null,
    };

    Object? edgeError;
    try {
      final response = await _invokeAdminFunction(
        body: {'action': 'set_plan', 'user_id': userId, 'plan': normalizedPlan},
      );
      if (response.status >= 200 && response.status < 300) {
        return _subscriptionPlanResult(response.data);
      }
      edgeError = StateError(
        'Edge Function returned HTTP ${response.status}: ${response.data}',
      );
    } catch (error) {
      edgeError = error;
    }

    try {
      final response = await _client.rpc(
        'admin_update_user_plan',
        params: {
          'p_user_id': userId,
          'p_tier': normalizedPlan,
          'p_duration_days': durationDays,
        },
      );
      return _subscriptionPlanResult(response);
    } catch (rpcError) {
      final email = _client.auth.currentUser?.email ?? 'Unknown account';
      bool isAdmin = false;
      try {
        isAdmin = await _client.rpc('is_admin') == true;
      } catch (_) {
        isAdmin = false;
      }
      if (!isAdmin) {
        throw StateError(
          'The current session ($email) is not authorized to manage plans. '
          'Sign out of the test account and sign in to StreetLore Admin as '
          'mohamedsabae50@gmail.com.',
        );
      }
      throw StateError(
        'Subscription plan update failed. Edge Function: $edgeError. '
        'Database RPC: $rpcError',
      );
    }
  }

  ({String tier, DateTime? endDate}) _subscriptionPlanResult(dynamic data) {
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
    final response = await _invokeAdminFunction(
      body: {'action': 'chat_logs', 'page': page, 'per_page': perPage},
    );
    if (response.status < 200 || response.status >= 300) {
      throw await _adminFunctionError(
        'AI chat logs request',
        response.status,
        response.data,
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
    final seed = await _previewSeed();
    if (isLocalDraftMode) {
      return _sortPlaces(
        _mergeById(
          seed.places,
          const <Place>[],
          idOf: (place) => place.id,
          drafts: await _localDrafts.places(),
          deletedIds: await _localDrafts.deletedPlaceIds(),
        ),
      );
    }
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
    final remote = (res as List<dynamic>)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
    return _sortPlaces(
      _mergeById(
        seed.places,
        remote,
        idOf: (place) => place.id,
        drafts: await _localDrafts.places(),
        deletedIds: await _localDrafts.deletedPlaceIds(),
      ),
    );
  }

  List<Place> _sortPlaces(List<Place> places) {
    places.sort((a, b) {
      final order = a.displayOrder.compareTo(b.displayOrder);
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    return places;
  }

  Future<PlaceSaveResult> createPlace(Place place) => _savePlace(place);

  Future<PlaceSaveResult> updatePlace(Place place) => _savePlace(place);

  Future<PlaceSaveResult> _savePlace(Place place) async {
    if (isLocalDraftMode) {
      await _localDrafts.savePlace(place);
      return const PlaceSaveResult(remoteSynced: false);
    }
    try {
      await _upsertPlace(place);
    } on Exception catch (error) {
      await _localDrafts.savePlace(place);
      debugPrint(
        'Place ${place.id} was saved to the local overlay because the '
        'Supabase write failed: $error',
      );
      return PlaceSaveResult(remoteSynced: false, remoteError: error);
    }
    await _localDrafts.savePlace(place);
    return const PlaceSaveResult(remoteSynced: true);
  }

  Future<void> _upsertPlace(Place place) async {
    final row = place.toJson();
    while (true) {
      try {
        final selectedColumns = [
          'id',
          if (row.containsKey('enable_chat')) 'enable_chat',
          if (row.containsKey('enable_gallery')) 'enable_gallery',
        ].join(',');
        final saved = await _client
            .from('places')
            .upsert(row, onConflict: 'id')
            .select(selectedColumns)
            .single();
        _verifyFeatureFlags(saved, place);
        return;
      } on PostgrestException catch (error) {
        final unsupportedColumn = _unsupportedPlaceColumn(error);
        if (unsupportedColumn == null ||
            unsupportedColumn == 'id' ||
            !row.containsKey(unsupportedColumn)) {
          rethrow;
        }
        row.remove(unsupportedColumn);
      }
    }
  }

  String? _unsupportedPlaceColumn(PostgrestException error) {
    final message = '${error.message} ${error.details ?? ''}';
    final schemaCacheMatch = RegExp(
      "Could not find the ['\"]([a-z_][a-z0-9_]*)['\"] column",
      caseSensitive: false,
    ).firstMatch(message);
    if (schemaCacheMatch != null) {
      return schemaCacheMatch.group(1)?.toLowerCase();
    }
    final missingColumnMatch = RegExp(
      r'column\s+(?:[a-z_][a-z0-9_]*\.)?([a-z_][a-z0-9_]*)\s+does not exist',
      caseSensitive: false,
    ).firstMatch(message);
    return missingColumnMatch?.group(1)?.toLowerCase();
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
    if (isLocalDraftMode) {
      final places = await fetchPlaces();
      final index = places.indexWhere((place) => place.id == placeId);
      if (index < 0) {
        throw StateError('Cannot find local place $placeId to update images.');
      }
      await _localDrafts.savePlace(
        places[index].copyWith(imageUrl: cover, imageUrls: merged),
      );
      return merged;
    }
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
    if ((row.containsKey('enable_chat') &&
            row['enable_chat'] != place.enableChat) ||
        (row.containsKey('enable_gallery') &&
            row['enable_gallery'] != place.enableGallery)) {
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

    if (isLocalDraftMode) {
      final currentPlaces = await fetchPlaces();
      final placesById = {for (final place in currentPlaces) place.id: place};
      final updated = <Place>[];
      for (var i = 0; i < placeIds.length; i++) {
        final place = placesById[placeIds[i]];
        if (place != null) {
          updated.add(place.copyWith(displayOrder: newOrders[i]));
        }
      }
      await _localDrafts.savePlaces(updated);
      return;
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
    if (isLocalDraftMode) {
      await _localDrafts.deletePlace(id);
      return;
    }
    await _client.from('places').delete().eq('id', id);
    await _localDrafts.deletePlace(id);
  }

  Future<List<Tour>> fetchTours() async {
    final seed = await _previewSeed();
    if (isLocalDraftMode) {
      return _mergeById(
        seed.tours,
        const <Tour>[],
        idOf: (tour) => tour.id,
        drafts: await _localDrafts.tours(),
        deletedIds: await _localDrafts.deletedTourIds(),
      );
    }
    final res = await _client
        .from('tours_with_places')
        .select()
        .order('id', ascending: true);
    final remote = (res as List<dynamic>)
        .map((e) => Tour.fromJson(e as Map<String, dynamic>))
        .toList();
    return _mergeById(seed.tours, remote, idOf: (tour) => tour.id);
  }

  Future<Tour> createTour(Tour tour) async {
    if (isLocalDraftMode) {
      await _localDrafts.saveTour(tour);
      return tour;
    }
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
      'governorate': tour.governorate,
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
    if (isLocalDraftMode) {
      await _localDrafts.saveTour(tour);
      return tour;
    }
    await _client
        .from('tours')
        .update(tour.toSupabaseUpdate())
        .eq('id', tour.id);
    await _replaceTourWaypoints(tour.id, tour.places.map((p) => p.id).toList());
    return tour;
  }

  Future<void> deleteTour(String id) async {
    if (isLocalDraftMode) {
      await _localDrafts.deleteTour(id);
      return;
    }
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
    _requireLiveWrites('Image uploads');
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
    _requireLiveWrites('Photo creation');
    await _client.from('place_photos').insert(photo.toJson());
    return photo;
  }

  Future<PlacePhoto> updatePhoto(PlacePhoto photo) async {
    _requireLiveWrites('Photo updates');
    await _client
        .from('place_photos')
        .update(photo.toSupabaseUpdate())
        .eq('id', photo.id);
    return photo;
  }

  Future<void> deletePhoto(String id) async {
    _requireLiveWrites('Photo deletion');
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
    _requireLiveWrites('Chat-message deletion');
    await _client.from('place_chat').delete().eq('id', id);
  }
}
