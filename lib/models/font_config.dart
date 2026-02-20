class FontConfig {
  final String fontFamily;
  final String fontPath;
  final double fontSize;

  const FontConfig({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
  });

  FontConfig copyWith({
    String? fontFamily,
    String? fontPath,
    double? fontSize,
  }) {
    return FontConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontPath: fontPath ?? this.fontPath,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontPath': fontPath,
        'fontSize': fontSize,
      };

  factory FontConfig.fromJson(Map<String, dynamic> json) => FontConfig(
        fontFamily: json['fontFamily'] as String,
        fontPath: json['fontPath'] as String,
        fontSize: (json['fontSize'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontConfig &&
          fontFamily == other.fontFamily &&
          fontPath == other.fontPath &&
          fontSize == other.fontSize;

  @override
  int get hashCode => Object.hash(fontFamily, fontPath, fontSize);

  @override
  String toString() =>
      'FontConfig(fontFamily: $fontFamily, fontPath: $fontPath, fontSize: $fontSize)';
}
