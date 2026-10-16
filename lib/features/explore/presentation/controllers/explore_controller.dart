import 'package:flutter/foundation.dart';

import '../../../../core/usecase/result.dart';
import '../../../home/domain/entities/template_entity.dart';
import '../../../home/domain/usecases/get_home_categories.dart';

enum ExploreStatus { initial, loading, success, failure }

class ExploreController extends ChangeNotifier {
  ExploreController(this._getHomeCategories);
  final GetHomeCategories _getHomeCategories;

  ExploreStatus status = ExploreStatus.initial;
  List<TemplateEntity> templates = const [];
  String? errorMessage;

  Future<void> load() async {
    status = ExploreStatus.loading;
    notifyListeners();

    switch (await _getHomeCategories()) {
      case Success(:final value):
        // Flatten all categories, keep only templates that have a gif preview.
        final seen = <int>{};
        templates = [
          for (final c in value)
            for (final t in c.templates)
              if (t.previewGifUrl.isNotEmpty && seen.add(t.id)) t,
        ];
        status = ExploreStatus.success;
      case Error(:final failure):
        errorMessage = failure.message;
        status = ExploreStatus.failure;
    }
    notifyListeners();
  }
}
