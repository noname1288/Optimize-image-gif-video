import 'package:flutter/foundation.dart';

import '../../../../core/usecase/result.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_home_categories.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeController extends ChangeNotifier {
  HomeController(this._getHomeCategories);
  final GetHomeCategories _getHomeCategories;

  HomeStatus status = HomeStatus.initial;
  List<CategoryEntity> categories = const [];
  String? errorMessage;

  /// [refresh] keeps the current content on screen instead of showing the
  /// full-screen loader (used by pull-to-refresh).
  Future<void> load({bool refresh = false}) async {
    status = HomeStatus.loading;
    notifyListeners();

    await Future.delayed(Duration(seconds: 2));

    switch (await _getHomeCategories()) {
      case Success(:final value):
        categories = value;
        status = HomeStatus.success;
      case Error(:final failure):
        errorMessage = failure.message;
        status = HomeStatus.failure;
    }
    notifyListeners();
  }
}
