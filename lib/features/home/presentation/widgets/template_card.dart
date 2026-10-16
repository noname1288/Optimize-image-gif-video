import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/template_entity.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template});
  final TemplateEntity template;

  static const double _width = 130;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (_width * dpr).round();

    return SizedBox(
      width: _width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: template.coverUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: cacheW,
                  maxWidthDiskCache: cacheW,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, _) =>
                      const ColoredBox(color: Colors.black12),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
