import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _postcardsCollection =>
      _firestore.collection('postcards');

  Stream<List<Postcard>> watchPostcards() {
    return _postcardsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Postcard.fromDocument).toList(growable: false),
        );
  }

  Future<void> addPostcard({
    required String name,
    required PostcardCategory category,
    required double lat,
    required double lng,
    required XFile imageFile,
  }) async {
    final doc = _postcardsCollection.doc();
    final prepared = await _prepareImages(imageFile);

    await doc.set({
      'name': name,
      'category': category.firestoreValue,
      'owned': false,
      'lat': lat,
      'lng': lng,
      'imageBytes': Blob(prepared.imageBytes),
      'thumbnailBytes': Blob(prepared.thumbnailBytes),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePostcard({
    required String id,
    required String name,
    required PostcardCategory category,
    required double lat,
    required double lng,
  }) async {
    await _postcardsCollection.doc(id).update({
      'name': name,
      'category': category.firestoreValue,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> setOwned({required String id, required bool owned}) async {
    await _postcardsCollection.doc(id).update({'owned': owned});
  }

  Future<void> deletePostcards(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_postcardsCollection.doc(id));
    }
    await batch.commit();
  }

  Future<({Uint8List imageBytes, Uint8List thumbnailBytes})> _prepareImages(
    XFile imageFile,
  ) async {
    final sourceBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(sourceBytes);

    if (decodedImage == null) {
      throw Exception('無法讀取圖片，請改選其他圖片。');
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
          throw Exception('圖片太大，請換一張較小的圖片。');
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
