import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/di/injector.dart';
import '../controllers/explore_controller.dart';
import '../widgets/explore_grid_item.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final ExploreController _controller = Injector.exploreController()
    ..load();

  static const _padding = 12.0;
  static const _spacing = 12.0;
  static const _columns = 3;
  // Covers of roughly the first two screens are warmed when data arrives.
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
      precacheExploreCover(context, t.coverUrl, width).ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGrid(BuildContext context) {
    _precacheFirstCovers(context);
    final cacheWidth = _cacheWidth(context);
    return GridView.builder(
      padding: const EdgeInsets.all(_padding),
      // Keep the off-screen build window small so gifs for tiles that are not
      // (nearly) visible are never started.
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.status) {
          ExploreStatus.initial || ExploreStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ExploreStatus.failure => Center(
            child: Text(_controller.errorMessage ?? 'Error'),
          ),
          ExploreStatus.success => _buildGrid(context),
        },
      ),
    );
  }
}
