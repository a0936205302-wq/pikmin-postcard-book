import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String id;
  final String name;
  final PostcardCategory category;
  final bool owned;
  final double lat;
  final double lng;
  final Uint8List? imageBytes;
  final Uint8List? thumbnailBytes;
  final String? imageUrl;
  final DateTime? createdAt;

  String get formattedLat => lat.toStringAsFixed(10);
  String get formattedLng => lng.toStringAsFixed(10);
  String get coordinatesText => '$formattedLat, $formattedLng';
  bool get hasInlineImage => imageBytes != null && imageBytes!.isNotEmpty;
  bool get hasThumbnail => thumbnailBytes != null && thumbnailBytes!.isNotEmpty;
  bool get hasNetworkImage => (imageUrl ?? '').isNotEmpty;
  bool get hasImage => hasInlineImage || hasNetworkImage;

  Postcard copyWith({
    String? id,
    String? name,
    PostcardCategory? category,
    bool? owned,
    double? lat,
    double? lng,
    Uint8List? imageBytes,
    Uint8List? thumbnailBytes,
    String? imageUrl,
    DateTime? createdAt,
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
      imageBytes: _blobToBytes(data['imageBytes']),
      thumbnailBytes: _blobToBytes(data['thumbnailBytes']),
      imageUrl: (data['imageUrl'] as String?)?.trim(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  static Uint8List? _blobToBytes(Object? value) {
    if (value is Blob) {
      return value.bytes;
    }
    if (value is Uint8List) {
      return value;
    }
    return null;
  }
}
