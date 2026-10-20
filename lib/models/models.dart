enum PriceLevel { free, cheap, moderate, expensive }

class AdminUser {
  final String id;
  final String email;
  final String name;
  final DateTime? createdAt;
  final bool isPro;
  final String? subscriptionTier;
  final DateTime? subscriptionEndDate;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
    this.isPro = false,
    this.subscriptionTier,
    this.subscriptionEndDate,
  });

  AdminUser copyWith({
    bool? isPro,
    String? subscriptionTier,
    DateTime? subscriptionEndDate,
  }) => AdminUser(
    id: id,
    email: email,
    name: name,
    createdAt: createdAt,
    isPro: isPro ?? this.isPro,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    subscriptionEndDate: subscriptionEndDate,
  );

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    email: (json['email'] as String?) ?? '',
    name: (json['name'] as String?) ?? 'Unnamed user',
    createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    isPro: json['is_pro'] == true,
    subscriptionTier: json['subscription_tier'] as String?,
    subscriptionEndDate: DateTime.tryParse(
      (json['subscription_end_date'] as String?) ?? '',
    ),
  );
}

class AdminChatLog {
  final String id;
  final String userId;
  final String? userEmail;
  final String? sessionId;
  final String prompt;
  final String response;
  final DateTime? createdAt;

  const AdminChatLog({
    required this.id,
    required this.userId,
    this.userEmail,
    this.sessionId,
    required this.prompt,
    required this.response,
    this.createdAt,
  });

  factory AdminChatLog.fromJson(Map<String, dynamic> json) {
    final rawEmail = json['user_email'] ?? json['email'];
    final rawSessionId = json['session_id'] ?? json['sessionId'];
    return AdminChatLog(
      id: (json['id'] ?? json['log_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      userEmail: rawEmail?.toString(),
      sessionId: rawSessionId?.toString(),
      prompt:
          (json['user_prompt'] ?? json['prompt'] ?? json['user_message'] ?? '')
              .toString(),
      response:
          (json['ai_response'] ??
                  json['response'] ??
                  json['assistant_message'] ??
                  '')
              .toString(),
      createdAt: DateTime.tryParse(
        (json['created_at'] ?? json['timestamp'] ?? '').toString(),
      ),
    );
  }
}

class AdminChatThread {
  final String id;
  final String userId;
  final String? userEmail;
  final String? sessionId;
  final DateTime? startedAt;
  final DateTime? lastMessageAt;
  final List<AdminChatLog> messages;

  const AdminChatThread({
    required this.id,
    required this.userId,
    required this.messages,
    this.userEmail,
    this.sessionId,
    this.startedAt,
    this.lastMessageAt,
  });
}

List<AdminChatThread> groupAdminChatLogs(List<AdminChatLog> logs) {
  final sortedLogs = logs.toList()
    ..sort((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftTime.compareTo(rightTime);
    });
  final threadMessages = <String, List<AdminChatLog>>{};
  final legacyThreadByUser = <String, String>{};
  final legacyLastMessageByUser = <String, DateTime>{};

  for (final log in sortedLogs) {
    final sessionId = log.sessionId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      final threadId = 'session:${log.userId}:$sessionId';
      threadMessages.putIfAbsent(threadId, () => []).add(log);
      legacyThreadByUser.remove(log.userId);
      legacyLastMessageByUser.remove(log.userId);
      continue;
    }

    final time = log.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final previousTime = legacyLastMessageByUser[log.userId];
    final previousThreadId = legacyThreadByUser[log.userId];
    final canAppendToLegacyThread =
        previousTime != null &&
        previousThreadId != null &&
        time.difference(previousTime) <= const Duration(minutes: 30);
    final threadId = canAppendToLegacyThread
        ? previousThreadId
        : 'legacy:${log.userId}:${log.id}';
    threadMessages.putIfAbsent(threadId, () => []).add(log);
    legacyThreadByUser[log.userId] = threadId;
    legacyLastMessageByUser[log.userId] = time;
  }

  final threads = threadMessages.entries.map((entry) {
    final messages = entry.value;
    final first = messages.first;
    return AdminChatThread(
      id: entry.key,
      userId: first.userId,
      userEmail: first.userEmail,
      sessionId: first.sessionId,
      startedAt: first.createdAt,
      lastMessageAt: messages.last.createdAt,
      messages: List.unmodifiable(messages),
    );
  }).toList();
  threads.sort((left, right) {
    final leftTime =
        left.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightTime =
        right.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return rightTime.compareTo(leftTime);
  });
  return threads;
}

class PopularTour {
  final String id;
  final String title;
  final int viewCount;

  const PopularTour({
    required this.id,
    required this.title,
    required this.viewCount,
  });

  factory PopularTour.fromJson(Map<String, dynamic> json) {
    final viewCount = json['view_count'];
    if (viewCount is! num) {
      throw const FormatException('Popular tour is missing its view count.');
    }
    return PopularTour(
      id: json['id'] as String,
      title: json['title'] as String,
      viewCount: viewCount.toInt(),
    );
  }
}

class PlaceCheckinCount {
  final String placeId;
  final String placeName;
  final int checkinCount;

  const PlaceCheckinCount({
    required this.placeId,
    required this.placeName,
    required this.checkinCount,
  });

  factory PlaceCheckinCount.fromJson(Map<String, dynamic> json) {
    final checkinCount = json['checkin_count'];
    if (checkinCount is! num) {
      throw const FormatException(
        'Popular place is missing its check-in count.',
      );
    }
    return PlaceCheckinCount(
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      checkinCount: checkinCount.toInt(),
    );
  }
}

class AdminAnalytics {
  final int totalAiGuideUsage;
  final int totalCheckins;
  final List<PopularTour> popularTours;
  final List<PlaceCheckinCount> topPlacesByCheckins;

  const AdminAnalytics({
    required this.totalAiGuideUsage,
    required this.totalCheckins,
    required this.popularTours,
    required this.topPlacesByCheckins,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    final aiUsage = json['total_ai_guide_usage'];
    final checkins = json['total_checkins'];
    final popularTours = json['popular_tours'];
    final topPlacesByCheckins = json['top_places_by_checkins'];
    if (aiUsage is! num ||
        checkins is! num ||
        popularTours is! List ||
        topPlacesByCheckins is! List) {
      throw const FormatException('Invalid admin analytics response.');
    }
    return AdminAnalytics(
      totalAiGuideUsage: aiUsage.toInt(),
      totalCheckins: checkins.toInt(),
      popularTours: popularTours
          .map((tour) => PopularTour.fromJson(tour as Map<String, dynamic>))
          .toList(growable: false),
      topPlacesByCheckins: topPlacesByCheckins
          .map(
            (place) =>
                PlaceCheckinCount.fromJson(place as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

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
  final String governorate;
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
    this.governorate = 'alexandria',
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
      governorate: (json['governorate'] as String?)?.trim().isNotEmpty == true
          ? (json['governorate'] as String).trim().toLowerCase()
          : 'alexandria',
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
    'governorate': governorate,
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
    'governorate': governorate,
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
    String? governorate,
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
    governorate: governorate ?? this.governorate,
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
  final String status;
  final int viewCount;
  final bool isPremium;
  final bool isHiddenGem;
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
    this.status = 'published',
    this.viewCount = 0,
    this.isPremium = false,
    this.isHiddenGem = false,
    this.places = const [],
  });

  String? get coverImageUrl {
    String? validUrl(String candidate) {
      final value = candidate.trim();
      final uri = Uri.tryParse(value);
      return uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty
          ? value
          : null;
    }

    final cover = validUrl(imageUrl);
    final placeImages = places
        .map((place) => validUrl(place.imageUrl))
        .whereType<String>()
        .toList(growable: false);
    if (cover != null && placeImages.contains(cover)) return cover;
    if (placeImages.isNotEmpty) return placeImages.first;
    return places.isEmpty ? cover : null;
  }

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
    status: (json['status'] as String?) ?? 'published',
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    isPremium: (json['is_premium'] as bool?) ?? false,
    isHiddenGem: (json['is_hidden_gem'] as bool?) ?? false,
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
    'status': status,
    'view_count': viewCount,
    'is_premium': isPremium,
    'is_hidden_gem': isHiddenGem,
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
    'status': status,
    'is_premium': isPremium,
    'is_hidden_gem': isHiddenGem,
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
    String? status,
    int? viewCount,
    bool? isPremium,
    bool? isHiddenGem,
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
    status: status ?? this.status,
    viewCount: viewCount ?? this.viewCount,
    isPremium: isPremium ?? this.isPremium,
    isHiddenGem: isHiddenGem ?? this.isHiddenGem,
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
