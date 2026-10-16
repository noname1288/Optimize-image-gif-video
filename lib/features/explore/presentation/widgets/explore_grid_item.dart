import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../home/domain/entities/template_entity.dart';

/// Static cover is always shown; the animated gif is layered on top only after
/// the item has stayed built for [_gifDelay]. GridView disposes items that
/// scroll away, so this means gifs only load/decode/animate for tiles the user
/// actually pauses on, not for tiles flung past.
class ExploreGridItem extends StatefulWidget {
  const ExploreGridItem({
    super.key,
    required this.template,
    required this.cacheWidth,
    this.onTap,
  });
  final TemplateEntity template;

  /// Decode width in physical pixels for both cover and gif.
  final int cacheWidth;
  final VoidCallback? onTap;

  @override
  State<ExploreGridItem> createState() => _ExploreGridItemState();
}

class _ExploreGridItemState extends State<ExploreGridItem> {
  static const _gifDelay = Duration(milliseconds: 300);

  Timer? _timer;
  bool _showGif = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_gifDelay, () {
      if (mounted) setState(() => _showGif = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(url: t.coverUrl, cacheWidth: widget.cacheWidth),
            if (_showGif)
              CachedNetworkImage(
                imageUrl: t.previewGifUrl,
                fit: BoxFit.cover,
                memCacheWidth: widget.cacheWidth,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: Duration.zero,
                // Cover stays visible underneath while loading or on failure.
                placeholder: null,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.cacheWidth});
  final String url;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    memCacheWidth: cacheWidth,
    // Cover is the base layer: no fade, so nothing animates under the gif.
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    placeholder: (_, _) => const ColoredBox(color: Colors.black12),
    errorWidget: (_, _, _) => const ColoredBox(
      color: Colors.black12,
      child: Icon(Icons.broken_image_outlined),
    ),
  );
}

/// Warms the image cache with the cover at the exact decoded size the grid
/// uses, so [ExploreGridItem]'s cover renders on its first frame.
Future<void> precacheExploreCover(
  BuildContext context,
  String url,
  int cacheWidth,
) => precacheImage(
  ResizeImage.resizeIfNeeded(
    cacheWidth,
    null,
    CachedNetworkImageProvider(url),
  ),
  context,
);
