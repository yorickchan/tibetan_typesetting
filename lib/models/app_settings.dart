import 'dart:convert';

import 'font_config.dart';

class AppSettings {
  FontConfig? tibetanFont;
  FontConfig? pronunciationFont;
  FontConfig? translationFont;
  double defaultPageWidthMm;
  double defaultPageHeightMm;

  AppSettings({
    this.tibetanFont,
    this.pronunciationFont,
    this.translationFont,
    this.defaultPageWidthMm = 300,
    this.defaultPageHeightMm = 120,
  });

  bool get hasFontsConfigured =>
      tibetanFont != null ||
      pronunciationFont != null ||
      translationFont != null;

  AppSettings copyWith({
    FontConfig? tibetanFont,
    FontConfig? pronunciationFont,
    FontConfig? translationFont,
    double? defaultPageWidthMm,
    double? defaultPageHeightMm,
    bool clearTibetanFont = false,
    bool clearPronunciationFont = false,
    bool clearTranslationFont = false,
  }) {
    return AppSettings(
      tibetanFont:
          clearTibetanFont ? null : (tibetanFont ?? this.tibetanFont),
      pronunciationFont: clearPronunciationFont
          ? null
          : (pronunciationFont ?? this.pronunciationFont),
      translationFont: clearTranslationFont
          ? null
          : (translationFont ?? this.translationFont),
      defaultPageWidthMm: defaultPageWidthMm ?? this.defaultPageWidthMm,
      defaultPageHeightMm: defaultPageHeightMm ?? this.defaultPageHeightMm,
    );
  }

  Map<String, dynamic> toJson() => {
        'tibetanFont': tibetanFont?.toJson(),
        'pronunciationFont': pronunciationFont?.toJson(),
        'translationFont': translationFont?.toJson(),
        'defaultPageWidthMm': defaultPageWidthMm,
        'defaultPageHeightMm': defaultPageHeightMm,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        tibetanFont: json['tibetanFont'] != null
            ? FontConfig.fromJson(json['tibetanFont'] as Map<String, dynamic>)
            : null,
        pronunciationFont: json['pronunciationFont'] != null
            ? FontConfig.fromJson(
                json['pronunciationFont'] as Map<String, dynamic>)
            : null,
        translationFont: json['translationFont'] != null
            ? FontConfig.fromJson(
                json['translationFont'] as Map<String, dynamic>)
            : null,
        defaultPageWidthMm:
            (json['defaultPageWidthMm'] as num?)?.toDouble() ?? 300,
        defaultPageHeightMm:
            (json['defaultPageHeightMm'] as num?)?.toDouble() ?? 120,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AppSettings.fromJsonString(String jsonStr) =>
      AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
