import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../home/domain/entities/template_entity.dart';
import '../controllers/video_preloader.dart';

/// Full-screen, vertically swiped video viewer. Neighbouring videos are
/// preloaded by [VideoPreloader] so swiping to them starts playback at once.
class VideoViewerPage extends StatefulWidget {
  const VideoViewerPage({
    super.key,
    required this.templates,
    required this.initialIndex,
    this.coverCacheWidth,
  });

  final List<TemplateEntity> templates;
  final int initialIndex;

  /// Decode width the grid used for covers. When given, that already-decoded
  /// image is shown first so the cover appears on the very first frame.
  final int? coverCacheWidth;

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage>
    with WidgetsBindingObserver {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late final VideoPreloader _preloader = VideoPreloader(widget.templates)
    ..addListener(_syncPlayback)
    ..focus(widget.initialIndex);

  late int _current = widget.initialIndex;
  bool _userPaused = false;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _preloader
      ..removeListener(_syncPlayback)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  /// Only the current page plays, and only while the app is in the
  /// foreground and the user hasn't paused it.
  void _syncPlayback() {
    final c = _preloader.controllerOf(_current);
    if (c == null) return;
    final shouldPlay = _appActive && !_userPaused;
    if (shouldPlay && !c.value.isPlaying) {
      c.play();
    } else if (!shouldPlay && c.value.isPlaying) {
      c.pause();
    }
  }

  void _onPageChanged(int index) {
    // Leave the previous page paused at its start, like Stories.
    final prev = _preloader.controllerOf(_current);
    if (prev != null) {
      prev.pause();
      prev.seekTo(Duration.zero);
    }
    setState(() {
      _current = index;
      _userPaused = false;
    });
    _preloader.focus(index);
    _syncPlayback();
    _logStartup(index); // TIMING
  }

  // TIMING: swipe → video position actually advancing.
  void _logStartup(int index) {
    final sw = Stopwatch()..start();
    final readyAtSwipe = _preloader.controllerOf(index) != null;
    void tick() {
      if (!mounted || _current != index) return;
      final c = _preloader.controllerOf(index);
      if (c != null && c.value.position > Duration.zero) {
        debugPrint(
          '[Viewer] #$index playing after ${sw.elapsedMilliseconds}ms '
          '(readyAtSwipe=$readyAtSwipe, buffered=${c.value.buffered})',
        );
        return;
      }
      Future.delayed(const Duration(milliseconds: 16), tick);
    }

    tick();
  }

  void _togglePause() {
    if (_preloader.controllerOf(_current) == null) return;
    setState(() => _userPaused = !_userPaused);
    _syncPlayback();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            ListenableBuilder(
              listenable: _preloader,
              builder: (context, _) => PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: widget.templates.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => _VideoPage(
                  template: widget.templates[i],
                  controller: _preloader.controllerOf(i),
                  coverCacheWidth: widget.coverCacheWidth,
                  isCurrent: i == _current,
                  paused: i == _current && _userPaused,
                  hasError: _preloader.errorOf(i) != null,
                  onTap: _togglePause,
                  onRetry: () => _preloader.retry(i),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPage extends StatelessWidget {
  const _VideoPage({
    required this.template,
    required this.controller,
    required this.coverCacheWidth,
    required this.isCurrent,
    required this.paused,
    required this.hasError,
    required this.onTap,
    required this.onRetry,
  });

  final TemplateEntity template;
  final VideoPlayerController? controller;
  final int? coverCacheWidth;
  final bool isCurrent;
  final bool paused;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Cover(template: template, gridCacheWidth: coverCacheWidth),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: c == null
                ? const SizedBox.shrink()
                : Center(
                    key: ValueKey(c),
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                  ),
          ),
          if (isCurrent && hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (isCurrent && c == null)
            const Center(
              child: SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            )
          else if (paused)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white70,
                size: 72,
              ),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.template, required this.gridCacheWidth});
  final TemplateEntity template;
  final int? gridCacheWidth;

  @override
  Widget build(BuildContext context) {
    final url = template.coverUrl.isNotEmpty
        ? template.coverUrl
        : template.previewGifUrl;
    if (url.isEmpty) return const SizedBox.shrink();

    final w = gridCacheWidth;
    // The grid-sized decode is already in the memory cache, so it paints on
    // the first frame; the full-size cover replaces it once decoded.
    final placeholder = w == null
        ? null
        : Image(
            image: ResizeImage.resizeIfNeeded(
              w,
              null,
              CachedNetworkImageProvider(url),
            ),
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: Duration.zero,
      placeholder: placeholder == null ? null : (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder ?? const SizedBox.shrink(),
    );
  }
}
