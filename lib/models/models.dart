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
  final List<String> imageUrls;
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
  final bool isHiddenGem;
  final bool isFeatured;
  final int? priceLocalEgp;
  final int? priceForeignerEgp;
  final int displayOrder;
  final bool enableChat;
  final bool enableGallery;
  final bool enablePhotoUpload;

  const Place({
    required this.id,
    required this.name,
    this.nameAr,
    required this.description,
    this.descriptionAr,
    required this.imageUrl,
    this.imageUrls = const <String>[],
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
    this.isHiddenGem = false,
    this.isFeatured = false,
    this.priceLocalEgp,
    this.priceForeignerEgp,
    this.displayOrder = 999,
    this.enableChat = true,
    this.enableGallery = true,
    this.enablePhotoUpload = true,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final urlsRaw = json['image_urls'] ?? json['imageUrls'];
    List<String> urls = const <String>[];
    if (urlsRaw is List) {
      urls = urlsRaw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    return Place(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      nameAr: json['name_ar'] as String?,
      description: (json['description'] as String?) ?? '',
      descriptionAr: json['description_ar'] as String?,
      imageUrl: (json['image_url'] as String?) ?? '',
      imageUrls: urls,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?) ?? 'General',
      categoryAr: json['category_ar'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      address: (json['address'] as String?) ?? 'Alexandria, Egypt',
      addressAr: json['address_ar'] as String?,
      openHours: (json['open_hours'] as String?) ?? '9:00 AM - 6:00 PM',
      reviewCount: (json['review_count'] as int?) ?? 0,
      priceLevel: priceLevelFromString(json['price_level'] as String?),
      priceNote: (json['price_note'] as String?) ?? '',
      isHiddenGem: (json['is_hidden_gem'] as bool?) ?? false,
      isFeatured: (json['is_featured'] as bool?) ?? false,
      priceLocalEgp: (json['price_local_egp'] as num?)?.toInt(),
      priceForeignerEgp: (json['price_foreigner_egp'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 999,
      enableChat:
          (json['enable_chat'] as bool?) ??
          (json['is_chat_enabled'] as bool?) ??
          true,
      enableGallery: (json['enable_gallery'] as bool?) ?? true,
      enablePhotoUpload:
          (json['enable_photo_upload'] as bool?) ??
          (json['is_photo_upload_enabled'] as bool?) ??
          true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ar': nameAr,
    'description': description,
    'description_ar': descriptionAr,
    'image_url': imageUrl,
    'image_urls': imageUrls,
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
    'is_hidden_gem': isHiddenGem,
    'is_featured': isFeatured,
    'price_local_egp': priceLocalEgp,
    'price_foreigner_egp': priceForeignerEgp,
    'display_order': displayOrder,
    'enable_chat': enableChat,
    'enable_gallery': enableGallery,
    'enable_photo_upload': enablePhotoUpload,
  };

  Map<String, dynamic> toSupabaseUpdate() => {
    'name': name,
    'name_ar': nameAr,
    'description': description,
    'description_ar': descriptionAr,
    'image_url': imageUrl,
    'image_urls': imageUrls,
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
    'is_hidden_gem': isHiddenGem,
    'is_featured': isFeatured,
    'price_local_egp': priceLocalEgp,
    'price_foreigner_egp': priceForeignerEgp,
    'display_order': displayOrder,
    'enable_chat': enableChat,
    'enable_gallery': enableGallery,
    'enable_photo_upload': enablePhotoUpload,
  };

  Place copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? imageUrl,
    List<String>? imageUrls,
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
    bool? isHiddenGem,
    bool? isFeatured,
    int? priceLocalEgp,
    int? priceForeignerEgp,
    int? displayOrder,
    bool? enableChat,
    bool? enableGallery,
    bool? enablePhotoUpload,
  }) => Place(
    id: id ?? this.id,
    name: name ?? this.name,
    nameAr: nameAr ?? this.nameAr,
    description: description ?? this.description,
    descriptionAr: descriptionAr ?? this.descriptionAr,
    imageUrl: imageUrl ?? this.imageUrl,
    imageUrls: imageUrls ?? this.imageUrls,
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
    isHiddenGem: isHiddenGem ?? this.isHiddenGem,
    isFeatured: isFeatured ?? this.isFeatured,
    priceLocalEgp: priceLocalEgp ?? this.priceLocalEgp,
    priceForeignerEgp: priceForeignerEgp ?? this.priceForeignerEgp,
    displayOrder: displayOrder ?? this.displayOrder,
    enableChat: enableChat ?? this.enableChat,
    enableGallery: enableGallery ?? this.enableGallery,
    enablePhotoUpload: enablePhotoUpload ?? this.enablePhotoUpload,
  );
}

class Tour {
  final String id;
  final String title;
  final String? titleAr;
  final String description;
  final String? descriptionAr;
  final String duration;
  final String? durationAr;
  final String category;
  final String? categoryAr;
  final String imageUrl;
  final List<Place> places;

  const Tour({
    required this.id,
    required this.title,
    this.titleAr,
    required this.description,
    this.descriptionAr,
    required this.duration,
    this.durationAr,
    this.category = 'General',
    this.categoryAr,
    required this.imageUrl,
    this.places = const [],
  });

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    titleAr: json['title_ar'] as String?,
    description: (json['description'] as String?) ?? '',
    descriptionAr: json['description_ar'] as String?,
    duration: (json['duration'] as String?) ?? '',
    durationAr: json['duration_ar'] as String?,
    category: (json['category'] as String?) ?? 'General',
    categoryAr: json['category_ar'] as String?,
    imageUrl: (json['image_url'] as String?) ?? '',
    places: ((json['places'] as List<dynamic>?) ?? const [])
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'title_ar': titleAr,
    'description': description,
    'description_ar': descriptionAr,
    'duration': duration,
    'duration_ar': durationAr,
    'category': category,
    'category_ar': categoryAr,
    'image_url': imageUrl,
    'places': places.map((e) => e.toJson()).toList(),
  };

  Map<String, dynamic> toSupabaseUpdate() => {
    'title': title,
    'title_ar': titleAr ?? '',
    'description': description,
    'description_ar': descriptionAr ?? '',
    'duration': duration,
    'duration_ar': durationAr ?? '',
    'category': category,
    'category_ar': categoryAr ?? '',
    'image_url': imageUrl,
  };

  Tour copyWith({
    String? id,
    String? title,
    String? titleAr,
    String? description,
    String? descriptionAr,
    String? duration,
    String? durationAr,
    String? category,
    String? categoryAr,
    String? imageUrl,
    List<Place>? places,
  }) => Tour(
    id: id ?? this.id,
    title: title ?? this.title,
    titleAr: titleAr ?? this.titleAr,
    description: description ?? this.description,
    descriptionAr: descriptionAr ?? this.descriptionAr,
    duration: duration ?? this.duration,
    durationAr: durationAr ?? this.durationAr,
    category: category ?? this.category,
    categoryAr: categoryAr ?? this.categoryAr,
    imageUrl: imageUrl ?? this.imageUrl,
    places: places ?? this.places,
  );
}

class PlacePhoto {
  final String id;
  final String placeId;
  // v1.0.72 — owner id, required by the new RLS policy on place_photos.
  final String userId;
  final String userName;
  final String imageUrl;
  final String captionAr;
  final String captionEn;
  final int likes;
  final DateTime? createdAt;

  const PlacePhoto({
    required this.id,
    required this.placeId,
    required this.userId,
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
    userId: (json['user_id'] as String?) ?? '',
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
    'user_id': userId,
    'user_name': userName,
    'image_url': imageUrl,
    'caption_ar': captionAr,
    'caption_en': captionEn,
    'likes': likes,
  };

  Map<String, dynamic> toSupabaseUpdate() => {
    'place_id': placeId,
    'user_id': userId,
    'user_name': userName,
    'image_url': imageUrl,
    'caption_ar': captionAr,
    'caption_en': captionEn,
    'likes': likes,
  };
}

class ChatMessage {
  final String id;
  final String placeId;
  final String userId;
  final String userName;
  final String text;
  final DateTime sentAt;
  final String? userAvatarColor;

  const ChatMessage({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.sentAt,
    this.userAvatarColor,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] as String?) ?? '',
    placeId: (json['place_id'] as String?) ?? '',
    userId: (json['user_id'] as String?) ?? '',
    userName: (json['user_name'] as String?) ?? 'Streetlore',
    text: (json['text'] as String?) ?? '',
    sentAt: json['sent_at'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['sent_at'] as String) ?? DateTime.now(),
    userAvatarColor: json['user_avatar_color'] as String?,
  );
}
