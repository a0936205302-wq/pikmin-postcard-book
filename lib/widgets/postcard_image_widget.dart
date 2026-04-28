import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class PostcardImageWidget extends StatelessWidget {
  const PostcardImageWidget({
    super.key,
    this.imageBytes,
    this.thumbnailBytes,
    this.preferThumbnail = false,
    this.fit = BoxFit.cover,
    this.expand = false,
  });

  final Object? imageBytes;
  final Object? thumbnailBytes;
  final bool preferThumbnail;
  final BoxFit fit;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primarySource = preferThumbnail ? thumbnailBytes : imageBytes;
    final fallbackSource = preferThumbnail ? imageBytes : thumbnailBytes;

    final primaryBytes = _decodeToBytes(primarySource);
    final fallbackBytes = _decodeToBytes(fallbackSource);
    final resolvedBytes = primaryBytes ?? fallbackBytes;

    Widget child;
    if (resolvedBytes != null && resolvedBytes.isNotEmpty) {
      child = Image.memory(
        resolvedBytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 36)),
      );
    } else {
      child = const Center(child: Icon(Icons.broken_image, size: 36));
    }

    if (!expand) {
      return child;
    }

    return SizedBox.expand(child: child);
  }

  Uint8List? _decodeToBytes(Object? source) {
    if (source == null) {
      return null;
    }
    if (source is Uint8List) {
      return source.isEmpty ? null : source;
    }
    if (source is List<int>) {
      return source.isEmpty ? null : Uint8List.fromList(source);
    }
    if (source is String) {
      final normalized = source.trim();
      if (normalized.isEmpty) {
        return null;
      }

      final withoutPrefix = normalized.replaceFirst(
        RegExp(r'^data:image\/[^;]+;base64,', caseSensitive: false),
        '',
      );

      try {
        final decoded = base64Decode(withoutPrefix);
        return decoded.isEmpty ? null : decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
