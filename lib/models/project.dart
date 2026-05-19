import 'dart:convert';

import 'font_config.dart';

class MarginMm {
  double top;
  double right;
  double bottom;
  double left;

  MarginMm({this.top = 10, this.right = 10, this.bottom = 10, this.left = 10});

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
  double pageWidthMm;
  double pageHeightMm;
  MarginMm marginMm;
  int columnCount;
  bool showFrame;
  String leftVerticalTitle;
  String pageNumber;
  double flowGap;
  bool showTitlePage;
  String titleTibetan;
  String titleChinese;
  FontConfig? tibetanFont;
  FontConfig? pronunciationFont;
  FontConfig? translationFont;
  FontConfig? titleTibetanFont;
  FontConfig? titleChineseFont;

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
  );
}

class TextBlock {
  String id;
  String tibetan;
  String chinesePronunciation;
  String chineseTranslation;
  bool pageBreakBefore;
  bool columnBreakBefore;
  bool smallText;
  int? columnSpan;

  TextBlock({
    required this.id,
    this.tibetan = '',
    this.chinesePronunciation = '',
    this.chineseTranslation = '',
    this.pageBreakBefore = false,
    this.columnBreakBefore = false,
    this.smallText = false,
    this.columnSpan,
  });

  TextBlock copyWith({
    String? id,
    String? tibetan,
    String? chinesePronunciation,
    String? chineseTranslation,
    bool? pageBreakBefore,
    bool? columnBreakBefore,
    bool? smallText,
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
    columnSpan: (json['columnSpan'] as num?)?.toInt(),
  );
}

class Project {
  String id;
  String name;
  List<String> tags;
  List<TextBlock> blocks;
  PageSetup pageSetup;
  String updatedAt;
  String createdAt;

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
      tags: tags ?? List.from(this.tags),
      blocks: blocks ?? this.blocks.map((b) => b.copyWith()).toList(),
      pageSetup: pageSetup ?? this.pageSetup.copyWith(),
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

  ProjectListItem({
    required this.id,
    required this.name,
    required this.tags,
    required this.updatedAt,
  });
}

String nowIso() {
  return DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'\.\d+'),
    '',
  );
}
