import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/di/injector.dart';
import '../../../explore/presentation/widgets/explore_grid_item.dart';
import '../controllers/video_controller.dart';
import 'video_viewer_page.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final VideoController _controller = Injector.videoController()..load();

  static const _padding = 12.0;
  static const _spacing = 12.0;
  static const _columns = 3;
  static const _precacheCount = 8;

  bool _precached = false;

  int _cacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    final itemWidth =
        (mq.size.width - _padding * 2 - _spacing * (_columns - 1)) / _columns;
    return (itemWidth * mq.devicePixelRatio).round();
  }

  void _precacheFirstCovers(BuildContext context) {
    if (_precached) return;
    _precached = true;
    final width = _cacheWidth(context);
    for (final t in _controller.templates.take(_precacheCount)) {
      if (t.coverUrl.isEmpty) continue;
      precacheExploreCover(context, t.coverUrl, width).ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index, int cacheWidth) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoViewerPage(
          templates: _controller.templates,
          initialIndex: index,
          coverCacheWidth: cacheWidth,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    _precacheFirstCovers(context);
    final cacheWidth = _cacheWidth(context);
    return GridView.builder(
      padding: const EdgeInsets.all(_padding),
      scrollCacheExtent: const ScrollCacheExtent.pixels(200),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
        childAspectRatio: 3 / 4,
      ),
      itemCount: _controller.templates.length,
      itemBuilder: (_, i) => ExploreGridItem(
        template: _controller.templates[i],
        cacheWidth: cacheWidth,
        onTap: () => _openViewer(i, cacheWidth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.status) {
          VideoStatus.initial || VideoStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          VideoStatus.failure => Center(
            child: Text(_controller.errorMessage ?? 'Error'),
          ),
          VideoStatus.success => _buildGrid(context),
        },
      ),
    );
  }
}
