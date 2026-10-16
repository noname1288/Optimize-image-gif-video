import '../../../../core/usecase/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/home_repository.dart';

class GetHomeCategories implements UseCase<List<CategoryEntity>, NoParams> {
  const GetHomeCategories(this._repository);
  final HomeRepository _repository;

  @override
  Future<Result<List<CategoryEntity>>> call([
    NoParams params = const NoParams(),
  ]) => _repository.getCategories();
}
