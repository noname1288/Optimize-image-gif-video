import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../../home/domain/entities/template_entity.dart';

/// Keeps a small window of [VideoPlayerController]s around the focused page,
/// Facebook-Stories style:
/// - window is `current → next → prev` (only `current` on metered networks),
/// - controllers are initialized one at a time in that priority order so they
///   don't compete for bandwidth,
/// - controllers that leave the window are disposed; an init that finishes
///   after its index was swiped past is thrown away.
///
/// Only manages lifecycle; play/pause is up to the caller.
class VideoPreloader extends ChangeNotifier {
  VideoPreloader(this.templates, {Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initConnectivity();
  }

  final List<TemplateEntity> templates;
  final Connectivity _connectivity;

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, Future<void>> _pending = {};
  final Set<int> _ready = {};
  final Map<int, Object> _errors = {};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Until connectivity is known, behave as if on mobile data.
  bool _allowPreload = false;
  int _current = 0;
  int _generation = 0;
  List<int> _window = const [];
  bool _disposed = false;

  bool get allowPreload => _allowPreload;

  /// Controller for [index] if it finished initializing, otherwise `null`.
  VideoPlayerController? controllerOf(int index) =>
      _ready.contains(index) ? _controllers[index] : null;

  Object? errorOf(int index) => _errors[index];

  /// Called whenever the visible page changes.
  void focus(int index) {
    if (_disposed || templates.isEmpty) return;
    _current = index.clamp(0, templates.length - 1);
    final gen = ++_generation;

    _window = [
      _current,
      if (_allowPreload && _current + 1 < templates.length) _current + 1,
      if (_allowPreload && _current - 1 >= 0) _current - 1,
    ];

    // Drop everything outside the window. In-flight inits are left alone and
    // discarded by [_initOne] when they complete.
    for (final i in _controllers.keys.toList()) {
      if (!_window.contains(i) && !_pending.containsKey(i)) _disposeAt(i);
    }
    _errors.removeWhere((i, _) => !_window.contains(i));

    _run(gen);
  }

  /// Clears the error for [index] and tries again.
  void retry(int index) {
    if (_errors.remove(index) == null) return;
    notifyListeners();
    focus(_current);
  }

  Future<void> _run(int gen) async {
    for (final i in _window) {
      if (_disposed || gen != _generation) return;
      if (_ready.contains(i) || _errors.containsKey(i)) continue;
      await (_pending[i] ??= _initOne(i));
    }
  }

  Future<void> _initOne(int index) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(templates[index].videoUrl),
    );
    _controllers[index] = controller;
    final sw = Stopwatch()..start(); // TIMING
    debugPrint('[VideoPreloader] init start #$index'); // TIMING
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (_disposed || !_window.contains(index)) {
        _disposeAt(index);
        return;
      }
      _ready.add(index);
      debugPrint(
        '[VideoPreloader] ready #$index in ${sw.elapsedMilliseconds}ms '
        'buffered=${controller.value.buffered}',
      ); // TIMING
    } catch (e) {
      debugPrint('[VideoPreloader] error #$index: $e');
      _disposeAt(index);
      if (_disposed || !_window.contains(index)) return;
      _errors[index] = e;
    } finally {
      _pending.remove(index);
    }
    if (!_disposed) notifyListeners();
  }

  void _disposeAt(int index) {
    _ready.remove(index);
    final c = _controllers.remove(index);
    if (c == null) return;
    debugPrint('[VideoPreloader] dispose #$index');
    c.dispose();
  }

  Future<void> _initConnectivity() async {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivity,
    );
    try {
      _onConnectivity(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('[VideoPreloader] connectivity check failed: $e');
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    if (_disposed) return;
    final allow =
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    if (allow == _allowPreload) return;
    _allowPreload = allow;
    debugPrint('[VideoPreloader] allowPreload=$allow');
    focus(_current);
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    // In-flight controllers are disposed by [_initOne] once init returns.
    for (final i in _controllers.keys.toList()) {
      if (!_pending.containsKey(i)) _disposeAt(i);
    }
    super.dispose();
  }
}
