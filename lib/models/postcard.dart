import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kBuiltInPostcardTags = <String>[
  '動物',
  '星空',
  '極光',
  '雪景',
  '壁畫',
  '藝人',
  '山景',
  '海景',
  '建築物',
  '日本',
  '櫻花',
  '夜景',
  '山丘',
  '韓國',
  '橋梁',
  '動漫',
  '吉祥物',
  '植物',
];

const Map<String, String> kPostcardTagAliases = <String, String>{
  '房子': '建築物',
  '畫作': '壁畫',
};

enum PostcardCategory {
  mushroom('mushroom', '菇點'),
  flower('flower', '花點'),
  unknown('unknown', '未分類');

  const PostcardCategory(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static PostcardCategory fromFirestoreValue(String? value) {
    for (final category in PostcardCategory.values) {
      if (category.firestoreValue == value) {
        return category;
      }
    }
    return PostcardCategory.unknown;
  }
}

class Postcard {
  const Postcard({
    required this.id,
    required this.name,
    required this.category,
    required this.owned,
    required this.lat,
    required this.lng,
    required this.imageBytes,
    required this.thumbnailBytes,
    required this.imageUrl,
    required this.createdAt,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final PostcardCategory category;
  final bool owned;
  final double lat;
  final double lng;
  final Object? imageBytes;
  final Object? thumbnailBytes;
  final String? imageUrl;
  final DateTime? createdAt;
  final List<String> tags;

  String get formattedLat => lat.toStringAsFixed(10);
  String get formattedLng => lng.toStringAsFixed(10);
  String get coordinatesText => '$formattedLat, $formattedLng';
  bool get hasInlineImage => _hasImageValue(imageBytes);
  bool get hasThumbnail => _hasImageValue(thumbnailBytes);
  bool get hasNetworkImage => (imageUrl ?? '').isNotEmpty;
  bool get hasImage => hasInlineImage || hasThumbnail || hasNetworkImage;

  Postcard copyWith({
    String? id,
    String? name,
    PostcardCategory? category,
    bool? owned,
    double? lat,
    double? lng,
    Object? imageBytes,
    Object? thumbnailBytes,
    String? imageUrl,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Postcard(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      owned: owned ?? this.owned,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageBytes: imageBytes ?? this.imageBytes,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  factory Postcard.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];

    return Postcard(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      category: PostcardCategory.fromFirestoreValue(
        data['category'] as String?,
      ),
      owned: (data['owned'] as bool?) ?? false,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      imageBytes: _normalizeImageValue(data['imageBytes']),
      thumbnailBytes: _normalizeImageValue(data['thumbnailBytes']),
      imageUrl: (data['imageUrl'] as String?)?.trim(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      tags: normalizeTags((data['tags'] as List<dynamic>?)?.cast<Object?>()),
    );
  }

  static Object? _normalizeImageValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Blob) {
      return value.bytes;
    }
    if (value is Uint8List) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }
    if (value is List<dynamic>) {
      final bytes = value.whereType<int>().toList(growable: false);
      if (bytes.isNotEmpty) {
        return Uint8List.fromList(bytes);
      }
    }
    return null;
  }

  static bool _hasImageValue(Object? value) {
    if (value is Uint8List) {
      return value.isNotEmpty;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List<int>) {
      return value.isNotEmpty;
    }
    return false;
  }

  static String normalizeTag(String input) {
    final normalized = input
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .replaceAll(' ', '');
    return kPostcardTagAliases[normalized] ?? normalized;
  }

  static String displayTag(String tag) {
    final normalized = normalizeTag(tag);
    return normalized.isEmpty ? '#' : '#$normalized';
  }

  static List<String> normalizeTags(Iterable<Object?>? rawTags) {
    final seen = <String>{};
    final normalizedTags = <String>[];

    for (final rawTag in rawTags ?? const <Object?>[]) {
      final normalized = normalizeTag(rawTag?.toString() ?? '');
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      normalizedTags.add(normalized);
    }

    return normalizedTags;
  }
}
