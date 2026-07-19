import 'dart:typed_data';
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
}
