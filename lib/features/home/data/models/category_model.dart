import '../../domain/entities/category_entity.dart';
import 'template_model.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.name, required super.templates});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    name: json['name'] as String? ?? '',
    templates: (json['templates'] as List? ?? const [])
        .map((e) => TemplateModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
