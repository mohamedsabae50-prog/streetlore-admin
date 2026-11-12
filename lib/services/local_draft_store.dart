import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalDraftStore {
  static const _placesKey = 'streetlore-admin-draft-places-v1';
  static const _toursKey = 'streetlore-admin-draft-tours-v1';
  static const _deletedPlacesKey = 'streetlore-admin-deleted-places-v1';
  static const _deletedToursKey = 'streetlore-admin-deleted-tours-v1';

  Future<List<Place>> places() async =>
      _readRecords<Place>(_placesKey, (json) => Place.fromJson(json));

  Future<List<Tour>> tours() async =>
      _readRecords<Tour>(_toursKey, (json) => Tour.fromJson(json));

  Future<Set<String>> deletedPlaceIds() => _readDeletedIds(_deletedPlacesKey);

  Future<Set<String>> deletedTourIds() => _readDeletedIds(_deletedToursKey);

  Future<void> savePlace(Place place) async {
    await _saveRecord(_placesKey, place.id, place.toJson());
    await _removeDeletedId(_deletedPlacesKey, place.id);
  }

  Future<void> saveTour(Tour tour) async {
    await _saveRecord(_toursKey, tour.id, tour.toJson());
    await _removeDeletedId(_deletedToursKey, tour.id);
  }

  Future<void> savePlaces(Iterable<Place> places) async {
    final preferences = await SharedPreferences.getInstance();
    final records = _readRecordMap(
      preferences.getString(_placesKey),
      _placesKey,
    );
    final savedIds = <String>{};
    for (final place in places) {
      records[place.id] = place.toJson();
      savedIds.add(place.id);
    }
    await preferences.setString(_placesKey, jsonEncode(records));
    final deletedIds = preferences.getStringList(_deletedPlacesKey);
    if (deletedIds != null) {
      deletedIds.removeWhere(savedIds.contains);
      await preferences.setStringList(_deletedPlacesKey, deletedIds);
    }
  }

  Future<void> deletePlace(String id) async {
    await _deleteRecord(_placesKey, id);
    await _addDeletedId(_deletedPlacesKey, id);
  }

  Future<void> deleteTour(String id) async {
    await _deleteRecord(_toursKey, id);
    await _addDeletedId(_deletedToursKey, id);
  }

  Future<List<T>> _readRecords<T>(
    String key,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid local draft data stored under $key.');
    }
    return decoded.values
        .map((value) {
          if (value is! Map) {
            throw FormatException('Invalid record stored under $key.');
          }
          return decode(Map<String, dynamic>.from(value));
        })
        .toList(growable: false);
  }

  Future<void> _saveRecord(
    String key,
    String id,
    Map<String, dynamic> record,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final records = _readRecordMap(preferences.getString(key), key);
    records[id] = record;
    await preferences.setString(key, jsonEncode(records));
  }

  Future<void> _deleteRecord(String key, String id) async {
    final preferences = await SharedPreferences.getInstance();
    final records = _readRecordMap(preferences.getString(key), key);
    records.remove(id);
    await preferences.setString(key, jsonEncode(records));
  }

  Map<String, dynamic> _readRecordMap(String? raw, String key) {
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid local draft data stored under $key.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Set<String>> _readDeletedIds(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(key);
    if (ids == null) return {};
    return ids.toSet();
  }

  Future<void> _addDeletedId(String key, String id) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = (preferences.getStringList(key) ?? <String>[]).toSet()..add(id);
    await preferences.setStringList(key, ids.toList());
  }

  Future<void> _removeDeletedId(String key, String id) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(key);
    if (ids == null || !ids.contains(id)) return;
    ids.remove(id);
    await preferences.setStringList(key, ids);
  }
}
