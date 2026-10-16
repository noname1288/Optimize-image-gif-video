class TemplateEntity {
  const TemplateEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.coverUrl,
    required this.videoUrl,
    required this.previewGifUrl,
    required this.points,
  });

  final int id;
  final String name;
  final String type;
  final String coverUrl;
  final String videoUrl;
  final String previewGifUrl;
  final int points;

  bool get isVideo => videoUrl.isNotEmpty;
}
