class TitlePageTemplate {
  final String id;
  final String name;
  final String svgContent;

  const TitlePageTemplate({
    required this.id,
    required this.name,
    required this.svgContent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'svgContent': svgContent,
  };

  factory TitlePageTemplate.fromJson(Map<String, dynamic> json) =>
      TitlePageTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        svgContent: json['svgContent'] as String,
      );
}
