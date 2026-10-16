import '../../../../core/error/failure.dart';
import '../../../../core/usecase/result.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._local);
  final HomeLocalDataSource _local;

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    try {
      return Success(await _local.fetchCategories());
    } on FormatException catch (e) {
      return Error(DataFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }
}
