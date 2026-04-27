import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/postcard.dart';

class PostcardService {
  PostcardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _maxImageBytes = 650 * 1024;
  static const int _maxThumbnailBytes = 120 * 1024;
  static const int _initialMaxDimension = 1400;
  static const int _minimumDimension = 400;
  static const int _thumbnailSize = 600;
  static const String _metadataDocId = 'app_metadata';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _postcardsCollection =>
      _firestore.collection('postcards');

  DocumentReference<Map<String, dynamic>> get _globalTagsDoc =>
      _postcardsCollection
          .doc(_metadataDocId)
          .collection('app')
          .doc('global_tags');

  String get _platformKey {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  CollectionReference<Map<String, dynamic>> get _ownedItemsCollection =>
      _firestore
          .collection('owned_status')
          .doc(_platformKey)
          .collection('items');

  DocumentReference<Map<String, dynamic>> _ownedItemDoc(String postcardId) {
    return _ownedItemsCollection.doc(postcardId);
  }

  DocumentReference<Map<String, dynamic>> _ownedItemDocForPlatform(
    String platform,
    String postcardId,
  ) {
    return _firestore
        .collection('owned_status')
        .doc(platform)
        .collection('items')
        .doc(postcardId);
  }

  Stream<List<String>> watchAvailableTags() {
    return _globalTagsDoc.snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final rawTags = (data['tags'] as List<dynamic>?)?.cast<Object?>();
      final merged = <String>[
        ...kBuiltInPostcardTags,
        ...Postcard.normalizeTags(rawTags),
      ];
      return Postcard.normalizeTags(merged);
    });
  }

  Future<void> _writeGlobalTags(List<String> incomingTags) async {
    final normalizedIncoming = Postcard.normalizeTags(incomingTags);
    if (normalizedIncoming.isEmpty) {
      return;
    }

    final snapshot = await _globalTagsDoc.get();
    final existingData = snapshot.data() ?? <String, dynamic>{};
    final existingTags = Postcard.normalizeTags(
      (existingData['tags'] as List<dynamic>?)?.cast<Object?>(),
    );

    final mergedTags = Postcard.normalizeTags([
      ...existingTags,
      ...normalizedIncoming,
    ]);

    await _globalTagsDoc.set({
      'tags': mergedTags,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addGlobalTag(String tag) async {
    final normalized = Postcard.normalizeTag(tag);
    if (normalized.isEmpty) {
      return;
    }

    await _writeGlobalTags([normalized]);
  }

  Future<void> _syncGlobalTags(List<String> tags) async {
    await _writeGlobalTags(tags);
  }

  Stream<List<Postcard>> watchPostcards() {
    final postcardsStream = _postcardsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.id != _metadataDocId)
              .map(Postcard.fromDocument)
              .toList(growable: false),
        );

    final ownedStream = _ownedItemsCollection.snapshots().map((snapshot) {
      final ownedIds = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final owned = (data['owned'] as bool?) ?? true;
        if (owned) {
          ownedIds.add(doc.id);
        }
      }
      return ownedIds;
    });

    late final StreamSubscription<List<Postcard>> postcardsSubscription;
    late final StreamSubscription<Set<String>> ownedSubscription;

    var latestPostcards = const <Postcard>[];
    var latestOwnedIds = <String>{};

    late final StreamController<List<Postcard>> controller;

    void emitMerged() {
      final merged = latestPostcards
          .map(
            (postcard) =>
                postcard.copyWith(owned: latestOwnedIds.contains(postcard.id)),
          )
          .toList(growable: false);
      controller.add(merged);
    }

    controller = StreamController<List<Postcard>>(
      onListen: () {
        postcardsSubscription = postcardsStream.listen((postcards) {
          latestPostcards = postcards;
          emitMerged();
        }, onError: controller.addError);

        ownedSubscription = ownedStream.listen((ownedIds) {
          latestOwnedIds = ownedIds;
          emitMerged();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await postcardsSubscription.cancel();
        await ownedSubscription.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> addPostcard({
    required String name,
    required PostcardCategory category,
    required double lat,
    required double lng,
    required List<String> tags,
    required XFile imageFile,
  }) async {
    final doc = _postcardsCollection.doc();
    final prepared = await _prepareImages(imageFile);
    final normalizedTags = Postcard.normalizeTags(tags);

    await doc.set({
      'name': name,
      'category': category.firestoreValue,
      'lat': lat,
      'lng': lng,
      'tags': normalizedTags,
      'imageBytes': Blob(prepared.imageBytes),
      'thumbnailBytes': Blob(prepared.thumbnailBytes),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _syncGlobalTags(normalizedTags);
  }

  Future<void> updatePostcard({
    required String id,
    required String name,
    required PostcardCategory category,
    required double lat,
    required double lng,
    required List<String> tags,
  }) async {
    final normalizedTags = Postcard.normalizeTags(tags);

    await _postcardsCollection.doc(id).update({
      'name': name,
      'category': category.firestoreValue,
      'lat': lat,
      'lng': lng,
      'tags': normalizedTags,
    });

    await _syncGlobalTags(normalizedTags);
  }

  Future<void> setOwned({required String id, required bool owned}) async {
    if (owned) {
      await _ownedItemDoc(id).set({
        'owned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await _ownedItemDoc(id).delete();
  }

  Future<void> deletePostcards(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    const platforms = <String>['android', 'ios', 'web'];

    for (final id in ids) {
      batch.delete(_postcardsCollection.doc(id));
      for (final platform in platforms) {
        batch.delete(_ownedItemDocForPlatform(platform, id));
      }
    }

    await batch.commit();
  }

  Future<({Uint8List imageBytes, Uint8List thumbnailBytes})> _prepareImages(
    XFile imageFile,
  ) async {
    final sourceBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(sourceBytes);

    if (decodedImage == null) {
      throw Exception('無法讀取圖片，請重新選擇。');
    }

    final oriented = img.bakeOrientation(decodedImage);
    final preparedImage = _prepareMainImage(oriented);
    final preparedThumbnail = _prepareThumbnail(oriented);

    return (imageBytes: preparedImage, thumbnailBytes: preparedThumbnail);
  }

  Uint8List _prepareMainImage(img.Image source) {
    var workingImage = source;
    if (_longestSide(workingImage) > _initialMaxDimension) {
      workingImage = _resizeToLongestSide(workingImage, _initialMaxDimension);
    }

    var quality = 85;
    var encodedBytes = _encodeJpg(workingImage, quality);

    while (encodedBytes.lengthInBytes > _maxImageBytes) {
      if (quality > 45) {
        quality -= 10;
      } else {
        final nextLongestSide = (_longestSide(workingImage) * 0.85).round();
        if (nextLongestSide < _minimumDimension) {
          throw Exception('圖片壓縮後仍過大，請換一張較小的圖片。');
        }

        workingImage = _resizeToLongestSide(workingImage, nextLongestSide);
        quality = 75;
      }

      encodedBytes = _encodeJpg(workingImage, quality);
    }

    return encodedBytes;
  }

  Uint8List _prepareThumbnail(img.Image source) {
    final cropped = _cropThumbnailRegion(source);
    final resized = img.copyResizeCropSquare(cropped, size: _thumbnailSize);

    var quality = 88;
    var encodedBytes = _encodeJpg(resized, quality);

    while (encodedBytes.lengthInBytes > _maxThumbnailBytes && quality > 50) {
      quality -= 8;
      encodedBytes = _encodeJpg(resized, quality);
    }

    return encodedBytes;
  }

  img.Image _cropThumbnailRegion(img.Image source) {
    if (source.height > source.width * 1.2) {
      final size = math.min(source.width, (source.width * 0.68).round());
      final x = math.max(0, ((source.width - size) / 2).round());
      final y = math.min(
        math.max(0, (source.height * 0.07).round()),
        math.max(0, source.height - size),
      );

      return img.copyCrop(source, x: x, y: y, width: size, height: size);
    }

    if (source.width > source.height * 1.2) {
      final size = math.min(source.height, (source.height * 0.94).round());
      final x = math.min(
        math.max(0, (source.width * 0.02).round()),
        math.max(0, source.width - size),
      );
      final y = math.max(0, ((source.height - size) / 2).round());

      return img.copyCrop(source, x: x, y: y, width: size, height: size);
    }

    final size = math.min(source.width, source.height);
    final x = ((source.width - size) / 2).round();
    final y = ((source.height - size) / 2).round();
    return img.copyCrop(source, x: x, y: y, width: size, height: size);
  }

  Uint8List _encodeJpg(img.Image image, int quality) {
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  int _longestSide(img.Image image) {
    return math.max(image.width, image.height);
  }

  img.Image _resizeToLongestSide(img.Image source, int maxLongestSide) {
    if (_longestSide(source) <= maxLongestSide) {
      return source;
    }

    if (source.width >= source.height) {
      return img.copyResize(source, width: maxLongestSide);
    }

    return img.copyResize(source, height: maxLongestSide);
  }
}
