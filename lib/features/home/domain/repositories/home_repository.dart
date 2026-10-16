import '../../../../core/usecase/result.dart';
import '../entities/category_entity.dart';

abstract interface class HomeRepository {
  Future<Result<List<CategoryEntity>>> getCategories();
}
