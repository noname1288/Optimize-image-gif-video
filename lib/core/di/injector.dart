import '../../features/explore/presentation/controllers/explore_controller.dart';
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_categories.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/video/presentation/controllers/video_controller.dart';

/// Manual composition root. Swap for get_it/riverpod later if needed.
abstract final class Injector {
  static final HomeRepository _homeRepository = HomeRepositoryImpl(
    HomeLocalDataSource(),
  );

  static GetHomeCategories get getHomeCategories =>
      GetHomeCategories(_homeRepository);

  static HomeController homeController() => HomeController(getHomeCategories);

  static ExploreController exploreController() =>
      ExploreController(getHomeCategories);

  static VideoController videoController() =>
      VideoController(getHomeCategories);
}
