import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PostcardImageWidget extends StatelessWidget {
  const PostcardImageWidget({
    super.key,
    required this.postcardId,
    required this.location,
    this.imageBytes,
    this.thumbnailBytes,
    this.preferThumbnail = false,
    this.fit = BoxFit.cover,
    this.expand = false,
  });

  final String postcardId;
  final String location;
  final Object? imageBytes;
  final Object? thumbnailBytes;
  final bool preferThumbnail;
  final BoxFit fit;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = preferThumbnail ? 'thumbnailBytes' : 'imageBytes';
    final fallbackLabel = preferThumbnail ? 'imageBytes' : 'thumbnailBytes';
    final primarySource = preferThumbnail ? thumbnailBytes : imageBytes;
    final fallbackSource = preferThumbnail ? imageBytes : thumbnailBytes;

    final primaryResult = _decodeToBytes(primaryLabel, primarySource);
    final fallbackResult = _decodeToBytes(fallbackLabel, fallbackSource);
    final resolvedResult = primaryResult.bytes != null
        ? primaryResult
        : fallbackResult;

    debugPrint(
      '[PostcardImageWidget] postcardId=$postcardId location=$location',
    );
    debugPrint(
      '[PostcardImageWidget] imageBytes=${_describePresence(imageBytes)} '
      'thumbnailBytes=${_describePresence(thumbnailBytes)}',
    );
    debugPrint(
      '[PostcardImageWidget] selectedSource='
      '${resolvedResult.sourceName ?? 'none'}',
    );
    _logSourceDetails(primaryResult);
    if (fallbackLabel != primaryLabel) {
      _logSourceDetails(fallbackResult);
    }

    Widget child;
    if (resolvedResult.bytes != null && resolvedResult.bytes!.isNotEmpty) {
      child = Image.memory(
        resolvedResult.bytes!,
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

  String _describePresence(Object? source) {
    if (source == null) {
      return 'null';
    }
    if (source is String) {
      return source.trim().isEmpty ? 'empty' : 'notEmpty';
    }
    if (source is Uint8List) {
      return source.isEmpty ? 'empty' : 'notEmpty';
    }
    if (source is List<int>) {
      return source.isEmpty ? 'empty' : 'notEmpty';
    }
    if (source is List<dynamic>) {
      return source.isEmpty ? 'empty' : 'notEmpty';
    }
    return 'type=${source.runtimeType}';
  }

  void _logSourceDetails(_DecodedSourceResult result) {
    debugPrint(
      '[PostcardImageWidget] ${result.sourceName}: '
      'base64Length=${result.base64Length ?? 'n/a'} '
      'base64Head=${result.base64Head ?? 'n/a'} '
      'strippedLength=${result.strippedLength ?? 'n/a'} '
      'bytesLength=${result.bytes?.length ?? 'null'}',
    );
    if (result.error != null) {
      debugPrint(
        '[PostcardImageWidget] ${result.sourceName} decodeError=${result.error}',
      );
    }
    if (result.stackTrace != null) {
      debugPrint(
        '[PostcardImageWidget] ${result.sourceName} stackTrace=${result.stackTrace}',
      );
    }
  }

  _DecodedSourceResult _decodeToBytes(String sourceName, Object? source) {
    if (source == null) {
      return _DecodedSourceResult(sourceName: sourceName);
    }
    if (source is Uint8List) {
      return _DecodedSourceResult(
        sourceName: sourceName,
        bytes: source.isEmpty ? null : source,
      );
    }
    if (source is List<int>) {
      return _DecodedSourceResult(
        sourceName: sourceName,
        bytes: source.isEmpty ? null : Uint8List.fromList(source),
      );
    }
    if (source is String) {
      final normalized = source.trim();
      if (normalized.isEmpty) {
        return _DecodedSourceResult(
          sourceName: sourceName,
          base64Length: 0,
          base64Head: '',
          strippedLength: 0,
        );
      }

      final withoutPrefix = normalized.replaceFirst(
        RegExp(r'^data:image\/[^;]+;base64,', caseSensitive: false),
        '',
      );

      try {
        final decoded = base64Decode(withoutPrefix);
        return _DecodedSourceResult(
          sourceName: sourceName,
          base64Length: normalized.length,
          base64Head: normalized.substring(0, normalized.length.clamp(0, 30)),
          strippedLength: withoutPrefix.length,
          bytes: decoded.isEmpty ? null : decoded,
        );
      } catch (error, stackTrace) {
        return _DecodedSourceResult(
          sourceName: sourceName,
          base64Length: normalized.length,
          base64Head: normalized.substring(0, normalized.length.clamp(0, 30)),
          strippedLength: withoutPrefix.length,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return _DecodedSourceResult(sourceName: sourceName);
  }
}

class _DecodedSourceResult {
  const _DecodedSourceResult({
    required this.sourceName,
    this.base64Length,
    this.base64Head,
    this.strippedLength,
    this.bytes,
    this.error,
    this.stackTrace,
  });

  final String? sourceName;
  final int? base64Length;
  final String? base64Head;
  final int? strippedLength;
  final Uint8List? bytes;
  final Object? error;
  final StackTrace? stackTrace;
}
