import 'package:flutter/material.dart';

import '../models/postcard.dart';

class PostcardImage extends StatelessWidget {
  const PostcardImage({
    super.key,
    required this.postcard,
    this.fit = BoxFit.cover,
    this.expand = false,
    this.useThumbnail = false,
  });

  final Postcard postcard;
  final BoxFit fit;
  final bool expand;
  final bool useThumbnail;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (useThumbnail && postcard.hasThumbnail) {
      child = Image.memory(postcard.thumbnailBytes!, fit: fit);
    } else if (postcard.hasInlineImage) {
      child = Image.memory(postcard.imageBytes!, fit: fit);
    } else if (postcard.hasNetworkImage) {
      child = Image.network(postcard.imageUrl!, fit: fit);
    } else {
      child = DecoratedBox(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 36),
        ),
      );
    }

    if (!expand) {
      return child;
    }

    return SizedBox.expand(child: child);
  }
}
