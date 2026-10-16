import 'template_entity.dart';

class CategoryEntity {
  const CategoryEntity({required this.name, required this.templates});

  final String name;
  final List<TemplateEntity> templates;
}
