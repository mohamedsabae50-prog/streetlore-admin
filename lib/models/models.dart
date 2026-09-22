enum PriceLevel { free, cheap, moderate, expensive }

PriceLevel priceLevelFromString(String? s) {
  switch (s) {
    case 'cheap':
      return PriceLevel.cheap;
    case 'moderate':
      return PriceLevel.moderate;
    case 'expensive':
      return PriceLevel.expensive;
    default:
      return PriceLevel.free;
  }
}

String priceLevelToString(PriceLevel p) => p.name;

class Place {
  final String id;
  final String name;
  final String? nameAr;
  final String description;
  final String? descriptionAr;
  final String imageUrl;
  final double rating;
  final String category;
  final String? categoryAr;
  final double lat;
  final double lng;
  final String address;
  final String? addressAr;
  final String openHours;
  final int reviewCount;
  final PriceLevel priceLevel;
  final String priceNote;
  final String? priceNoteAr;
  final bool isHiddenGem;
  final bool isFeatured;
  final int? priceLocalEgp;
  final int? priceForeignerEgp;
  /// Admin-supplied "best time to visit" label (e.g. "Morning",
  /// "Sunset", "Late Night"). When non-empty, the Best Time screen
  /// surfaces this label verbatim instead of computing one.
  final String? bestTimeToVisit;

  const Place({
    required this.id,
    required this.name,
    this.nameAr,
    required this.description,
    this.descriptionAr,
    required this.imageUrl,
    required this.rating,
    required this.category,
    this.categoryAr,
    required this.lat,
    required this.lng,
    this.address = 'Alexandria, Egypt',
    this.addressAr,
    this.openHours = '9:00 AM - 6:00 PM',
    this.reviewCount = 0,
    this.priceLevel = PriceLevel.free,
    this.priceNote = '',
    this.priceNoteAr,
    this.isHiddenGem = false,
    this.isFeatured = false,
    this.priceLocalEgp,
    this.priceForeignerEgp,
    this.bestTimeToVisit,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        nameAr: json['name_ar'] as String?,
        description: (json['description'] as String?) ?? '',
        descriptionAr: json['description_ar'] as String?,
        imageUrl: (json['image_url'] as String?) ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        category: (json['category'] as String?) ?? 'General',
        categoryAr: json['category_ar'] as String?,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        address: (json['address'] as String?) ?? 'Alexandria, Egypt',
        addressAr: json['address_ar'] as String?,
        openHours:
            (json['open_hours'] as String?) ?? '9:00 AM - 6:00 PM',
        reviewCount: (json['review_count'] as int?) ?? 0,
        priceLevel: priceLevelFromString(json['price_level'] as String?),
        priceNote: (json['price_note'] as String?) ?? '',
        priceNoteAr: json['price_note_ar'] as String?,
        isHiddenGem: (json['is_hidden_gem'] as bool?) ?? false,
        isFeatured: (json['is_featured'] as bool?) ?? false,
        priceLocalEgp: (json['price_local_egp'] as num?)?.toInt(),
        priceForeignerEgp: (json['price_foreigner_egp'] as num?)?.toInt(),
        bestTimeToVisit: json['best_time_to_visit'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'description_ar': descriptionAr,
        'image_url': imageUrl,
        'rating': rating,
        'category': category,
        'category_ar': categoryAr,
        'lat': lat,
        'lng': lng,
        'address': address,
        'address_ar': addressAr,
        'open_hours': openHours,
        'review_count': reviewCount,
        'price_level': priceLevelToString(priceLevel),
        'price_note': priceNote,
        'price_note_ar': priceNoteAr,
        'is_hidden_gem': isHiddenGem,
        'is_featured': isFeatured,
        'price_local_egp': priceLocalEgp,
        'price_foreigner_egp': priceForeignerEgp,
        'best_time_to_visit': bestTimeToVisit,
      };

  Map<String, dynamic> toSupabaseUpdate() => {
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'description_ar': descriptionAr,
        'image_url': imageUrl,
        'rating': rating,
        'category': category,
        'category_ar': categoryAr,
        'lat': lat,
        'lng': lng,
        'address': address,
        'address_ar': addressAr,
        'open_hours': openHours,
        'review_count': reviewCount,
        'price_level': priceLevelToString(priceLevel),
        'price_note': priceNote,
        'price_note_ar': priceNoteAr,
        'is_hidden_gem': isHiddenGem,
        'is_featured': isFeatured,
        'price_local_egp': priceLocalEgp,
        'price_foreigner_egp': priceForeignerEgp,
        'best_time_to_visit': bestTimeToVisit,
      };

  Place copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? imageUrl,
    double? rating,
    String? category,
    String? categoryAr,
    double? lat,
    double? lng,
    String? address,
    String? addressAr,
    String? openHours,
    int? reviewCount,
    PriceLevel? priceLevel,
    String? priceNote,
    String? priceNoteAr,
    bool? isHiddenGem,
    bool? isFeatured,
    int? priceLocalEgp,
    int? priceForeignerEgp,
    String? bestTimeToVisit,
  }) =>
      Place(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        description: description ?? this.description,
        descriptionAr: descriptionAr ?? this.descriptionAr,
        imageUrl: imageUrl ?? this.imageUrl,
        rating: rating ?? this.rating,
        category: category ?? this.category,
        categoryAr: categoryAr ?? this.categoryAr,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        address: address ?? this.address,
        addressAr: addressAr ?? this.addressAr,
        openHours: openHours ?? this.openHours,
        reviewCount: reviewCount ?? this.reviewCount,
        priceLevel: priceLevel ?? this.priceLevel,
        priceNote: priceNote ?? this.priceNote,
        priceNoteAr: priceNoteAr ?? this.priceNoteAr,
        isHiddenGem: isHiddenGem ?? this.isHiddenGem,
        isFeatured: isFeatured ?? this.isFeatured,
        priceLocalEgp: priceLocalEgp ?? this.priceLocalEgp,
        priceForeignerEgp: priceForeignerEgp ?? this.priceForeignerEgp,
        bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      );
}

class Tour {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String imageUrl;
  final List<Place> places;

  const Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.imageUrl,
    this.places = const [],
  });

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        duration: (json['duration'] as String?) ?? '',
        imageUrl: (json['image_url'] as String?) ?? '',
        places: ((json['places'] as List<dynamic>?) ?? const [])
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'duration': duration,
        'image_url': imageUrl,
        'places': places.map((e) => e.toJson()).toList(),
      };

  Map<String, dynamic> toSupabaseUpdate() => {
        'title': title,
        'description': description,
        'duration': duration,
        'image_url': imageUrl,
      };
}

class PlacePhoto {
  final String id;
  final String placeId;
  final String userName;
  final String imageUrl;
  final String captionAr;
  final String captionEn;
  final int likes;
  final DateTime? createdAt;

  const PlacePhoto({
    required this.id,
    required this.placeId,
    required this.userName,
    required this.imageUrl,
    this.captionAr = '',
    this.captionEn = '',
    this.likes = 0,
    this.createdAt,
  });

  factory PlacePhoto.fromJson(Map<String, dynamic> json) => PlacePhoto(
        id: (json['id'] as String?) ?? '',
        placeId: (json['place_id'] as String?) ?? '',
        userName: (json['user_name'] as String?) ?? 'Streetlore',
        imageUrl: (json['image_url'] as String?) ?? '',
        captionAr: (json['caption_ar'] as String?) ?? '',
        captionEn: (json['caption_en'] as String?) ?? '',
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'place_id': placeId,
        'user_name': userName,
        'image_url': imageUrl,
        'caption_ar': captionAr,
        'caption_en': captionEn,
        'likes': likes,
      };

  Map<String, dynamic> toSupabaseUpdate() => {
        'place_id': placeId,
        'user_name': userName,
        'image_url': imageUrl,
        'caption_ar': captionAr,
        'caption_en': captionEn,
        'likes': likes,
      };
}
