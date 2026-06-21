import 'dart:convert';

import 'font_config.dart';

enum AppTheme { system, light, dark }

class AppSettings {
  final FontConfig? tibetanFont;
  final FontConfig? pronunciationFont;
  final FontConfig? translationFont;
  final double? smallBlockFontSize;
  final double defaultPageWidthMm;
  final double defaultPageHeightMm;
  final String? locale;
  final AppTheme theme;

  const AppSettings({
    this.tibetanFont,
    this.pronunciationFont,
    this.translationFont,
    this.smallBlockFontSize,
    this.defaultPageWidthMm = 300,
    this.defaultPageHeightMm = 120,
    this.locale,
    this.theme = AppTheme.dark,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          tibetanFont == other.tibetanFont &&
          pronunciationFont == other.pronunciationFont &&
          translationFont == other.translationFont &&
          smallBlockFontSize == other.smallBlockFontSize &&
          defaultPageWidthMm == other.defaultPageWidthMm &&
          defaultPageHeightMm == other.defaultPageHeightMm &&
          locale == other.locale &&
          theme == other.theme;

  @override
  int get hashCode => Object.hash(
        tibetanFont,
        pronunciationFont,
        translationFont,
        smallBlockFontSize,
        defaultPageWidthMm,
        defaultPageHeightMm,
        locale,
        theme,
      );

  bool get hasAnyFontConfigured =>
      tibetanFont != null ||
      pronunciationFont != null ||
      translationFont != null;

  AppSettings copyWith({
    FontConfig? tibetanFont,
    FontConfig? pronunciationFont,
    FontConfig? translationFont,
    double? smallBlockFontSize,
    double? defaultPageWidthMm,
    double? defaultPageHeightMm,
    String? locale,
    AppTheme? theme,
    bool clearTibetanFont = false,
    bool clearPronunciationFont = false,
    bool clearTranslationFont = false,
    bool clearSmallBlockFontSize = false,
    bool clearLocale = false,
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
      smallBlockFontSize: clearSmallBlockFontSize
          ? null
          : (smallBlockFontSize ?? this.smallBlockFontSize),
      defaultPageWidthMm: defaultPageWidthMm ?? this.defaultPageWidthMm,
      defaultPageHeightMm: defaultPageHeightMm ?? this.defaultPageHeightMm,
      locale: clearLocale ? null : (locale ?? this.locale),
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'tibetanFont': tibetanFont?.toJson(),
        'pronunciationFont': pronunciationFont?.toJson(),
        'translationFont': translationFont?.toJson(),
        'defaultPageWidthMm': defaultPageWidthMm,
        'defaultPageHeightMm': defaultPageHeightMm,
        'locale': locale,
        'theme': theme.name,
        if (smallBlockFontSize != null) 'smallBlockFontSize': smallBlockFontSize,
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
        smallBlockFontSize: (json['smallBlockFontSize'] as num?)?.toDouble(),
        defaultPageWidthMm:
            (json['defaultPageWidthMm'] as num?)?.toDouble() ?? 300,
        defaultPageHeightMm:
            (json['defaultPageHeightMm'] as num?)?.toDouble() ?? 120,
        locale: json['locale'] as String?,
        theme: json['theme'] != null
            ? AppTheme.values.firstWhere(
                (e) => e.name == json['theme'],
                orElse: () => AppTheme.dark,
              )
            : AppTheme.dark,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AppSettings.fromJsonString(String jsonStr) =>
      AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
