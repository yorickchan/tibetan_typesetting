import 'dart:convert';

import 'font_config.dart';

class MarginMm {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const MarginMm({this.top = 10, this.right = 10, this.bottom = 10, this.left = 10});

  MarginMm copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    return MarginMm(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }

  Map<String, dynamic> toJson() => {
    'top': top,
    'right': right,
    'bottom': bottom,
    'left': left,
  };

  factory MarginMm.fromJson(Map<String, dynamic> json) => MarginMm(
    top: (json['top'] as num?)?.toDouble() ?? 10,
    right: (json['right'] as num?)?.toDouble() ?? 10,
    bottom: (json['bottom'] as num?)?.toDouble() ?? 10,
    left: (json['left'] as num?)?.toDouble() ?? 10,
  );
}

class PageSetup {
  final double pageWidthMm;
  final double pageHeightMm;
  final MarginMm marginMm;
  final int columnCount;
  final bool showFrame;
  final String leftVerticalTitle;
  final String pageNumber;
  final double flowGap;
  final bool showTitlePage;
  final String titleTibetan;
  final String titleChinese;
  final FontConfig? tibetanFont;
  final FontConfig? pronunciationFont;
  final FontConfig? translationFont;
  final FontConfig? titleTibetanFont;
  final FontConfig? titleChineseFont;
  final TranslationLanguage translationLang;

  PageSetup({
    this.pageWidthMm = 300,
    this.pageHeightMm = 120,
    MarginMm? marginMm,
    this.columnCount = 5,
    this.showFrame = true,
    this.leftVerticalTitle = '',
    this.pageNumber = '',
    this.flowGap = 0.01,
    this.showTitlePage = true,
    this.titleTibetan = '',
    this.titleChinese = '',
    this.tibetanFont,
    this.pronunciationFont,
    this.translationFont,
    this.titleTibetanFont,
    this.titleChineseFont,
    this.translationLang = TranslationLanguage.chinese,
  }) : marginMm = marginMm ?? MarginMm();

  PageSetup copyWith({
    double? pageWidthMm,
    double? pageHeightMm,
    MarginMm? marginMm,
    int? columnCount,
    bool? showFrame,
    String? leftVerticalTitle,
    String? pageNumber,
    double? flowGap,
    bool? showTitlePage,
    String? titleTibetan,
    String? titleChinese,
    FontConfig? tibetanFont,
    FontConfig? pronunciationFont,
    FontConfig? translationFont,
    FontConfig? titleTibetanFont,
    FontConfig? titleChineseFont,
    TranslationLanguage? translationLang,
    bool clearTibetanFont = false,
    bool clearPronunciationFont = false,
    bool clearTranslationFont = false,
    bool clearTitleTibetanFont = false,
    bool clearTitleChineseFont = false,
  }) {
    return PageSetup(
      pageWidthMm: pageWidthMm ?? this.pageWidthMm,
      pageHeightMm: pageHeightMm ?? this.pageHeightMm,
      marginMm: marginMm ?? this.marginMm,
      columnCount: columnCount ?? this.columnCount,
      showFrame: showFrame ?? this.showFrame,
      leftVerticalTitle: leftVerticalTitle ?? this.leftVerticalTitle,
      pageNumber: pageNumber ?? this.pageNumber,
      flowGap: flowGap ?? this.flowGap,
      showTitlePage: showTitlePage ?? this.showTitlePage,
      titleTibetan: titleTibetan ?? this.titleTibetan,
      titleChinese: titleChinese ?? this.titleChinese,
      tibetanFont: clearTibetanFont ? null : (tibetanFont ?? this.tibetanFont),
      pronunciationFont: clearPronunciationFont
          ? null
          : (pronunciationFont ?? this.pronunciationFont),
      translationFont: clearTranslationFont
          ? null
          : (translationFont ?? this.translationFont),
      titleTibetanFont: clearTitleTibetanFont
          ? null
          : (titleTibetanFont ?? this.titleTibetanFont),
      titleChineseFont: clearTitleChineseFont
          ? null
          : (titleChineseFont ?? this.titleChineseFont),
      translationLang: translationLang ?? this.translationLang,
    );
  }

  Map<String, dynamic> toJson() => {
    'pageWidthMm': pageWidthMm,
    'pageHeightMm': pageHeightMm,
    'marginMm': marginMm.toJson(),
    'columnCount': columnCount,
    'showFrame': showFrame,
    'leftVerticalTitle': leftVerticalTitle,
    'pageNumber': pageNumber,
    'flowGap': flowGap,
    'showTitlePage': showTitlePage,
    'titleTibetan': titleTibetan,
    'titleChinese': titleChinese,
    'translationLang': translationLang.name,
    if (tibetanFont != null) 'tibetanFont': tibetanFont!.toJson(),
    if (pronunciationFont != null)
      'pronunciationFont': pronunciationFont!.toJson(),
    if (translationFont != null) 'translationFont': translationFont!.toJson(),
    if (titleTibetanFont != null)
      'titleTibetanFont': titleTibetanFont!.toJson(),
    if (titleChineseFont != null)
      'titleChineseFont': titleChineseFont!.toJson(),
  };

  factory PageSetup.fromJson(Map<String, dynamic> json) => PageSetup(
    pageWidthMm: (json['pageWidthMm'] as num?)?.toDouble() ?? 300,
    pageHeightMm: (json['pageHeightMm'] as num?)?.toDouble() ?? 120,
    marginMm: json['marginMm'] != null
        ? MarginMm.fromJson(json['marginMm'] as Map<String, dynamic>)
        : MarginMm(),
    columnCount: (json['columnCount'] as num?)?.toInt() ?? 5,
    showFrame: json['showFrame'] as bool? ?? true,
    leftVerticalTitle: json['leftVerticalTitle'] as String? ?? '',
    pageNumber: json['pageNumber'] as String? ?? '',
    flowGap: (json['flowGap'] as num?)?.toDouble() ?? 0.01,
    showTitlePage: json['showTitlePage'] as bool? ?? true,
    titleTibetan: json['titleTibetan'] as String? ?? '',
    titleChinese: json['titleChinese'] as String? ?? '',
    tibetanFont: json['tibetanFont'] != null
        ? FontConfig.fromJson(json['tibetanFont'] as Map<String, dynamic>)
        : null,
    pronunciationFont: json['pronunciationFont'] != null
        ? FontConfig.fromJson(json['pronunciationFont'] as Map<String, dynamic>)
        : null,
    translationFont: json['translationFont'] != null
        ? FontConfig.fromJson(json['translationFont'] as Map<String, dynamic>)
        : null,
    titleTibetanFont: json['titleTibetanFont'] != null
        ? FontConfig.fromJson(json['titleTibetanFont'] as Map<String, dynamic>)
        : null,
    titleChineseFont: json['titleChineseFont'] != null
        ? FontConfig.fromJson(json['titleChineseFont'] as Map<String, dynamic>)
        : null,
    translationLang: TranslationLanguage.fromJson(
        json['translationLang'] as String?),
  );
}

enum TranslationLanguage {
  chinese,
  english,
  japanese,
  custom;

  String get label {
    return switch (this) {
      TranslationLanguage.chinese => '中文',
      TranslationLanguage.english => 'English',
      TranslationLanguage.japanese => '日本語',
      TranslationLanguage.custom => 'Custom',
    };
  }

  static TranslationLanguage fromJson(String? value) {
    return switch (value) {
      'english' => TranslationLanguage.english,
      'japanese' => TranslationLanguage.japanese,
      'custom' => TranslationLanguage.custom,
      _ => TranslationLanguage.chinese,
    };
  }
}

enum TextBlockFormat {
  normal,
  freeText;

  static TextBlockFormat fromJson(String? value) {
    return switch (value) {
      'freeText' => TextBlockFormat.freeText,
      _ => TextBlockFormat.normal,
    };
  }
}

class TextBlock {
  final String id;
  final String tibetan;
  final String chinesePronunciation;
  final String chineseTranslation;
  final bool pageBreakBefore;
  final bool columnBreakBefore;
  final bool smallText;
  final TextBlockFormat format;
  final int? columnSpan;

  TextBlock({
    required this.id,
    this.tibetan = '',
    this.chinesePronunciation = '',
    this.chineseTranslation = '',
    this.pageBreakBefore = false,
    this.columnBreakBefore = false,
    this.smallText = false,
    this.format = TextBlockFormat.normal,
    this.columnSpan,
  });

  bool get isFreeText => format == TextBlockFormat.freeText;

  TextBlock copyWith({
    String? id,
    String? tibetan,
    String? chinesePronunciation,
    String? chineseTranslation,
    bool? pageBreakBefore,
    bool? columnBreakBefore,
    bool? smallText,
    TextBlockFormat? format,
    int? columnSpan,
    bool clearColumnSpan = false,
  }) {
    return TextBlock(
      id: id ?? this.id,
      tibetan: tibetan ?? this.tibetan,
      chinesePronunciation: chinesePronunciation ?? this.chinesePronunciation,
      chineseTranslation: chineseTranslation ?? this.chineseTranslation,
      pageBreakBefore: pageBreakBefore ?? this.pageBreakBefore,
      columnBreakBefore: columnBreakBefore ?? this.columnBreakBefore,
      smallText: smallText ?? this.smallText,
      format: format ?? this.format,
      columnSpan: clearColumnSpan ? null : (columnSpan ?? this.columnSpan),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tibetan': tibetan,
    'chinesePronunciation': chinesePronunciation,
    'chineseTranslation': chineseTranslation,
    'pageBreakBefore': pageBreakBefore,
    'columnBreakBefore': columnBreakBefore,
    'smallText': smallText,
    'format': format.name,
    if (columnSpan != null) 'columnSpan': columnSpan,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    id: json['id'] as String,
    tibetan: json['tibetan'] as String? ?? '',
    chinesePronunciation: json['chinesePronunciation'] as String? ?? '',
    chineseTranslation: json['chineseTranslation'] as String? ?? '',
    pageBreakBefore: json['pageBreakBefore'] as bool? ?? false,
    columnBreakBefore: json['columnBreakBefore'] as bool? ?? false,
    smallText: json['smallText'] as bool? ?? false,
    format: TextBlockFormat.fromJson(json['format'] as String?),
    columnSpan: (json['columnSpan'] as num?)?.toInt(),
  );
}

class Project {
  final String id;
  final String name;
  final List<String> tags;
  final List<TextBlock> blocks;
  final PageSetup pageSetup;
  final String updatedAt;
  final String createdAt;

  Project({
    required this.id,
    required this.name,
    List<String>? tags,
    List<TextBlock>? blocks,
    PageSetup? pageSetup,
    required this.updatedAt,
    required this.createdAt,
  }) : tags = tags ?? [],
       blocks = blocks ?? [],
       pageSetup = pageSetup ?? PageSetup();

  Project copyWith({
    String? id,
    String? name,
    List<String>? tags,
    List<TextBlock>? blocks,
    PageSetup? pageSetup,
    String? updatedAt,
    String? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      blocks: blocks ?? this.blocks,
      pageSetup: pageSetup ?? this.pageSetup,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tags': tags,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'pageSetup': pageSetup.toJson(),
    'updatedAt': updatedAt,
    'createdAt': createdAt,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    blocks:
        (json['blocks'] as List<dynamic>?)
            ?.map((b) => TextBlock.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [],
    pageSetup: json['pageSetup'] != null
        ? PageSetup.fromJson(json['pageSetup'] as Map<String, dynamic>)
        : PageSetup(),
    updatedAt: json['updatedAt'] as String,
    createdAt: json['createdAt'] as String,
  );

  factory Project.fromJsonString(String jsonStr) =>
      Project.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}

class ProjectListItem {
  final String id;
  final String name;
  final List<String> tags;
  final String updatedAt;

  const ProjectListItem({
    required this.id,
    required this.name,
    required this.tags,
    required this.updatedAt,
  });
}

final _fractionalSecondsRe = RegExp(r'\.\d+');

String nowIso() {
  return DateTime.now().toUtc().toIso8601String().replaceAll(
    _fractionalSecondsRe,
    '',
  );
}
