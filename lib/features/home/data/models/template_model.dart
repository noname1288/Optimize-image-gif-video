import '../../domain/entities/template_entity.dart';

class TemplateModel extends TemplateEntity {
  const TemplateModel({
    required super.id,
    required super.name,
    required super.type,
    required super.coverUrl,
    required super.videoUrl,
    required super.previewGifUrl,
    required super.points,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    type: json['template_type'] as String? ?? '',
    coverUrl: json['cover_url'] as String? ?? '',
    videoUrl: json['mp4_url'] as String? ?? '',
    previewGifUrl: json['preview_gif_url'] as String? ?? '',
    points: json['points'] as int? ?? 0,
  );
}
