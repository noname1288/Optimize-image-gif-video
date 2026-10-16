import 'package:flutter/foundation.dart';

import '../../../../core/usecase/result.dart';
import '../../../home/domain/entities/template_entity.dart';
import '../../../home/domain/usecases/get_home_categories.dart';

enum VideoStatus { initial, loading, success, failure }

class VideoController extends ChangeNotifier {
  VideoController(this._getHomeCategories);
  final GetHomeCategories _getHomeCategories;

  VideoStatus status = VideoStatus.initial;
  List<TemplateEntity> templates = const [];
  String? errorMessage;

  Future<void> load() async {
    status = VideoStatus.loading;
    notifyListeners();

    switch (await _getHomeCategories()) {
      case Success(:final value):
        // Keep templates that have a video and something to cover it with
        // (static image or gif).
        final seen = <int>{};
        templates = [
          for (final c in value)
            for (final t in c.templates)
              if (t.isVideo &&
                  (t.coverUrl.isNotEmpty || t.previewGifUrl.isNotEmpty) &&
                  seen.add(t.id))
                t,
        ];
        status = VideoStatus.success;
      case Error(:final failure):
        errorMessage = failure.message;
        status = VideoStatus.failure;
    }
    notifyListeners();
  }
}
