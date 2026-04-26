import 'package:flutter/material.dart';

import '../models/postcard.dart';
import 'postcard_image.dart';

class PostcardGridItem extends StatelessWidget {
  const PostcardGridItem({
    super.key,
    required this.postcard,
    required this.onTap,
    required this.onLongPress,
    this.selected = false,
  });

  final Postcard postcard;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade200,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PostcardImage(
              postcard: postcard,
              fit: BoxFit.cover,
              expand: true,
              useThumbnail: true,
            ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.check_circle,
                        size: 24,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
