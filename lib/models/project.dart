import 'dart:convert';

import 'chinese_script.dart';
import 'font_config.dart';

const String kDefaultOpeningMark = '༄༅།།';

class MarginMm {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const MarginMm({
    this.top = 10,
    this.right = 10,
    this.bottom = 10,
    this.left = 10,
  });

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

class TemplateInset {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const TemplateInset({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  TemplateInset copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    return TemplateInset(
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

  factory TemplateInset.fromJson(Map<String, dynamic> json) => TemplateInset(
    top: (json['top'] as num?)?.toDouble() ?? 0,
    right: (json['right'] as num?)?.toDouble() ?? 0,
    bottom: (json['bottom'] as num?)?.toDouble() ?? 0,
    left: (json['left'] as num?)?.toDouble() ?? 0,
  );
}

class PageSetup {
  final double pageWidthMm;
  final double pageHeightMm;
  final MarginMm marginMm;
  final int columnCount;
  final bool showFrame;
  final bool showRowLines;
  final String leftVerticalTitle;
  final String pageNumber;
  final double flowGap;
  final TemplateInset templateInset;
  final TemplateInset titleTextInset;
  final bool showTitlePage;
  final String titleTibetan;
  final String titleChinese;
  final FontConfig? tibetanFont;
  final FontConfig? pronunciationFont;
  final FontConfig? translationFont;
  final FontConfig? titleTibetanFont;
  final FontConfig? titleChineseFont;
  final TranslationLanguage translationLang;
  final HeaderFooterField headerLeft;
  final HeaderFooterField headerCenter;
  final HeaderFooterField headerRight;
  final HeaderFooterField footerLeft;
  final HeaderFooterField footerCenter;
  final HeaderFooterField footerRight;
  final String headerCustomText;
  final String footerCustomText;
  final double headerFontSize;
  final double footerFontSize;
  final String defaultOpeningMark;
  final double? smallBlockFontSize;
  final String? titlePageTemplateId;
  final String? contentFirstPageTemplateId;
  final TemplateInset contentFirstPageTemplateInset;
  final MarginMm contentFirstPageMargin;
  final String? contentSubsequentPageTemplateId;
  final TemplateInset contentSubsequentPageTemplateInset;
  final MarginMm contentSubsequentPageMargin;

  PageSetup({
    this.pageWidthMm = 300,
    this.pageHeightMm = 120,
    MarginMm? marginMm,
    this.columnCount = 5,
    this.showFrame = true,
    this.showRowLines = true,
    this.leftVerticalTitle = '',
    this.pageNumber = '',
    this.flowGap = 0.01,
    TemplateInset? templateInset,
    TemplateInset? titleTextInset,
    this.showTitlePage = true,
    this.titleTibetan = '',
    this.titleChinese = '',
    this.tibetanFont,
    this.pronunciationFont,
    this.translationFont,
    this.titleTibetanFont,
    this.titleChineseFont,
    this.translationLang = TranslationLanguage.chinese,
    this.headerLeft = HeaderFooterField.none,
    this.headerCenter = HeaderFooterField.none,
    this.headerRight = HeaderFooterField.none,
    this.footerLeft = HeaderFooterField.none,
    this.footerCenter = HeaderFooterField.none,
    this.footerRight = HeaderFooterField.none,
    this.headerCustomText = '',
    this.footerCustomText = '',
    this.headerFontSize = 9,
    this.footerFontSize = 9,
    this.smallBlockFontSize,
    this.titlePageTemplateId,
    this.defaultOpeningMark = kDefaultOpeningMark,
    this.contentFirstPageTemplateId,
    TemplateInset? contentFirstPageTemplateInset,
    MarginMm? contentFirstPageMargin,
    this.contentSubsequentPageTemplateId,
    TemplateInset? contentSubsequentPageTemplateInset,
    MarginMm? contentSubsequentPageMargin,
  }) : marginMm = marginMm ?? const MarginMm(),
       templateInset = templateInset ?? const TemplateInset(),
       titleTextInset =
           titleTextInset ??
           const TemplateInset(top: 20, right: 56, bottom: 20, left: 56),
       contentFirstPageTemplateInset =
           contentFirstPageTemplateInset ?? const TemplateInset(),
       contentFirstPageMargin = contentFirstPageMargin ?? const MarginMm(),
       contentSubsequentPageTemplateInset =
           contentSubsequentPageTemplateInset ?? const TemplateInset(),
       contentSubsequentPageMargin =
           contentSubsequentPageMargin ?? const MarginMm();
  PageSetup copyWith({
    double? pageWidthMm,
    double? pageHeightMm,
    MarginMm? marginMm,
    int? columnCount,
    bool? showFrame,
    bool? showRowLines,
    String? leftVerticalTitle,
    String? pageNumber,
    double? flowGap,
    TemplateInset? templateInset,
    TemplateInset? titleTextInset,
    bool? showTitlePage,
    String? titleTibetan,
    String? titleChinese,
    FontConfig? tibetanFont,
    FontConfig? pronunciationFont,
    FontConfig? translationFont,
    FontConfig? titleTibetanFont,
    FontConfig? titleChineseFont,
    TranslationLanguage? translationLang,
    HeaderFooterField? headerLeft,
    HeaderFooterField? headerCenter,
    HeaderFooterField? headerRight,
    HeaderFooterField? footerLeft,
    HeaderFooterField? footerCenter,
    HeaderFooterField? footerRight,
    String? headerCustomText,
    String? footerCustomText,
    double? headerFontSize,
    double? footerFontSize,
    String? defaultOpeningMark,
    String? titlePageTemplateId,
    double? smallBlockFontSize,
    String? contentFirstPageTemplateId,
    TemplateInset? contentFirstPageTemplateInset,
    MarginMm? contentFirstPageMargin,
    String? contentSubsequentPageTemplateId,
    TemplateInset? contentSubsequentPageTemplateInset,
    MarginMm? contentSubsequentPageMargin,
    bool clearTibetanFont = false,
    bool clearPronunciationFont = false,
    bool clearTranslationFont = false,
    bool clearTitleTibetanFont = false,
    bool clearTitleChineseFont = false,
    bool clearTitlePageTemplateId = false,
    bool clearSmallBlockFontSize = false,
    bool clearContentFirstPageTemplateId = false,
    bool clearContentSubsequentPageTemplateId = false,
  }) {
    return PageSetup(
      pageWidthMm: pageWidthMm ?? this.pageWidthMm,
      pageHeightMm: pageHeightMm ?? this.pageHeightMm,
      marginMm: marginMm ?? this.marginMm,
      columnCount: columnCount ?? this.columnCount,
      showFrame: showFrame ?? this.showFrame,
      showRowLines: showRowLines ?? this.showRowLines,
      leftVerticalTitle: leftVerticalTitle ?? this.leftVerticalTitle,
      pageNumber: pageNumber ?? this.pageNumber,
      flowGap: flowGap ?? this.flowGap,
      templateInset: templateInset ?? this.templateInset,
      titleTextInset: titleTextInset ?? this.titleTextInset,
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
      headerLeft: headerLeft ?? this.headerLeft,
      headerCenter: headerCenter ?? this.headerCenter,
      headerRight: headerRight ?? this.headerRight,
      footerLeft: footerLeft ?? this.footerLeft,
      footerCenter: footerCenter ?? this.footerCenter,
      footerRight: footerRight ?? this.footerRight,
      headerCustomText: headerCustomText ?? this.headerCustomText,
      footerCustomText: footerCustomText ?? this.footerCustomText,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      footerFontSize: footerFontSize ?? this.footerFontSize,
      defaultOpeningMark: defaultOpeningMark ?? this.defaultOpeningMark,
      titlePageTemplateId: clearTitlePageTemplateId
          ? null
          : (titlePageTemplateId ?? this.titlePageTemplateId),
      smallBlockFontSize: clearSmallBlockFontSize
          ? null
          : (smallBlockFontSize ?? this.smallBlockFontSize),
      contentFirstPageTemplateId: clearContentFirstPageTemplateId
          ? null
          : (contentFirstPageTemplateId ?? this.contentFirstPageTemplateId),
      contentFirstPageTemplateInset:
          contentFirstPageTemplateInset ?? this.contentFirstPageTemplateInset,
      contentFirstPageMargin:
          contentFirstPageMargin ?? this.contentFirstPageMargin,
      contentSubsequentPageTemplateId: clearContentSubsequentPageTemplateId
          ? null
          : (contentSubsequentPageTemplateId ??
              this.contentSubsequentPageTemplateId),
      contentSubsequentPageTemplateInset:
          contentSubsequentPageTemplateInset ??
              this.contentSubsequentPageTemplateInset,
      contentSubsequentPageMargin:
          contentSubsequentPageMargin ?? this.contentSubsequentPageMargin,
    );
  }

  Map<String, dynamic> toJson() => {
    'pageWidthMm': pageWidthMm,
    'pageHeightMm': pageHeightMm,
    'marginMm': marginMm.toJson(),
    'columnCount': columnCount,
    'showFrame': showFrame,
    'showRowLines': showRowLines,
    'leftVerticalTitle': leftVerticalTitle,
    'pageNumber': pageNumber,
    'flowGap': flowGap,
    'showTitlePage': showTitlePage,
    'titleTibetan': titleTibetan,
    'templateInset': templateInset.toJson(),
    'titleTextInset': titleTextInset.toJson(),
    'titleChinese': titleChinese,
    'translationLang': translationLang.name,
    'headerLeft': headerLeft.name,
    'headerCenter': headerCenter.name,
    'headerRight': headerRight.name,
    'footerLeft': footerLeft.name,
    'footerCenter': footerCenter.name,
    'footerRight': footerRight.name,
    'headerCustomText': headerCustomText,
    'footerCustomText': footerCustomText,
    'headerFontSize': headerFontSize,
    'footerFontSize': footerFontSize,
    'defaultOpeningMark': defaultOpeningMark,
    if (tibetanFont != null) 'tibetanFont': tibetanFont!.toJson(),
    if (pronunciationFont != null)
      'pronunciationFont': pronunciationFont!.toJson(),
    if (translationFont != null) 'translationFont': translationFont!.toJson(),
    if (titleTibetanFont != null)
      'titleTibetanFont': titleTibetanFont!.toJson(),
    if (titleChineseFont != null)
      'titleChineseFont': titleChineseFont!.toJson(),
    if (titlePageTemplateId != null) 'titlePageTemplateId': titlePageTemplateId,
    if (smallBlockFontSize != null) 'smallBlockFontSize': smallBlockFontSize,
    if (contentFirstPageTemplateId != null)
      'contentFirstPageTemplateId': contentFirstPageTemplateId,
    'contentFirstPageTemplateInset': contentFirstPageTemplateInset.toJson(),
    'contentFirstPageMargin': contentFirstPageMargin.toJson(),
    if (contentSubsequentPageTemplateId != null)
      'contentSubsequentPageTemplateId': contentSubsequentPageTemplateId,
    'contentSubsequentPageTemplateInset':
        contentSubsequentPageTemplateInset.toJson(),
    'contentSubsequentPageMargin': contentSubsequentPageMargin.toJson(),
  };

  factory PageSetup.fromJson(Map<String, dynamic> json) => PageSetup(
    pageWidthMm: (json['pageWidthMm'] as num?)?.toDouble() ?? 300,
    pageHeightMm: (json['pageHeightMm'] as num?)?.toDouble() ?? 120,
    marginMm: json['marginMm'] != null
        ? MarginMm.fromJson(json['marginMm'] as Map<String, dynamic>)
        : const MarginMm(),
    columnCount: (json['columnCount'] as num?)?.toInt() ?? 5,
    showFrame: json['showFrame'] as bool? ?? true,
    showRowLines: json['showRowLines'] as bool? ?? true,
    leftVerticalTitle: json['leftVerticalTitle'] as String? ?? '',
    pageNumber: json['pageNumber'] as String? ?? '',
    flowGap: (json['flowGap'] as num?)?.toDouble() ?? 0.01,
    templateInset: json['templateInset'] != null
        ? TemplateInset.fromJson(json['templateInset'] as Map<String, dynamic>)
        : const TemplateInset(),
    titleTextInset: json['titleTextInset'] != null
        ? TemplateInset.fromJson(json['titleTextInset'] as Map<String, dynamic>)
        : const TemplateInset(top: 20, right: 56, bottom: 20, left: 56),
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
      json['translationLang'] as String?,
    ),
    headerLeft: HeaderFooterField.fromJson(json['headerLeft'] as String?),
    headerCenter: HeaderFooterField.fromJson(json['headerCenter'] as String?),
    headerRight: HeaderFooterField.fromJson(json['headerRight'] as String?),
    footerLeft: HeaderFooterField.fromJson(json['footerLeft'] as String?),
    footerCenter: HeaderFooterField.fromJson(json['footerCenter'] as String?),
    footerRight: HeaderFooterField.fromJson(json['footerRight'] as String?),
    headerCustomText: json['headerCustomText'] as String? ?? '',
    footerCustomText: json['footerCustomText'] as String? ?? '',
    headerFontSize: (json['headerFontSize'] as num?)?.toDouble() ?? 9,
    footerFontSize: (json['footerFontSize'] as num?)?.toDouble() ?? 9,
    defaultOpeningMark:
        json['defaultOpeningMark'] as String? ?? kDefaultOpeningMark,
    titlePageTemplateId: json['titlePageTemplateId'] as String?,
    smallBlockFontSize: (json['smallBlockFontSize'] as num?)?.toDouble(),
    contentFirstPageTemplateId:
        json['contentFirstPageTemplateId'] as String?,
    contentFirstPageTemplateInset:
        json['contentFirstPageTemplateInset'] != null
            ? TemplateInset.fromJson(
                json['contentFirstPageTemplateInset'] as Map<String, dynamic>)
            : const TemplateInset(),
    contentFirstPageMargin: json['contentFirstPageMargin'] != null
        ? MarginMm.fromJson(
            json['contentFirstPageMargin'] as Map<String, dynamic>)
        : const MarginMm(),
    contentSubsequentPageTemplateId:
        json['contentSubsequentPageTemplateId'] as String?,
    contentSubsequentPageTemplateInset:
        json['contentSubsequentPageTemplateInset'] != null
            ? TemplateInset.fromJson(
                json['contentSubsequentPageTemplateInset']
                    as Map<String, dynamic>)
            : const TemplateInset(),
    contentSubsequentPageMargin: json['contentSubsequentPageMargin'] != null
        ? MarginMm.fromJson(
            json['contentSubsequentPageMargin'] as Map<String, dynamic>)
        : const MarginMm(),
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

enum HeaderFooterField {
  none,
  fileName,
  pageNumber,
  date,
  custom;

  static HeaderFooterField fromJson(String? value) {
    return switch (value) {
      'fileName' => HeaderFooterField.fileName,
      'pageNumber' => HeaderFooterField.pageNumber,
      'date' => HeaderFooterField.date,
      'custom' => HeaderFooterField.custom,
      _ => HeaderFooterField.none,
    };
  }
}

enum TextBlockFormat {
  normal,
  freeText,
  openingMark;

  static TextBlockFormat fromJson(String? value) {
    return switch (value) {
      'freeText' => TextBlockFormat.freeText,
      'openingMark' => TextBlockFormat.openingMark,
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
  final String? imagePath;
  final bool floatingImage;
  final double? imageWidthMm;
  final double? imageHeightMm;
  final double? imageXMm;
  final double? imageYMm;
  final String redHighlightRange;
  const TextBlock({
    required this.id,
    this.tibetan = '',
    this.chinesePronunciation = '',
    this.chineseTranslation = '',
    this.pageBreakBefore = false,
    this.columnBreakBefore = false,
    this.smallText = false,
    this.format = TextBlockFormat.normal,
    this.columnSpan,
    this.imagePath,
    this.floatingImage = false,
    this.imageWidthMm,
    this.imageHeightMm,
    this.imageXMm,
    this.imageYMm,
    this.redHighlightRange = '',
  });

  bool get isFreeText => format == TextBlockFormat.freeText;
  bool get isOpeningMark => format == TextBlockFormat.openingMark;
  bool get isImageBlock => imagePath != null && imagePath!.isNotEmpty;

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
    String? imagePath,
    bool? floatingImage,
    double? imageWidthMm,
    double? imageHeightMm,
    double? imageXMm,
    double? imageYMm,
    String? redHighlightRange,
    bool clearColumnSpan = false,
    bool clearImagePath = false,
    bool clearImageWidthMm = false,
    bool clearImageHeightMm = false,
    bool clearImageXMm = false,
    bool clearImageYMm = false,
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
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      floatingImage: floatingImage ?? this.floatingImage,
      imageWidthMm: clearImageWidthMm
          ? null
          : (imageWidthMm ?? this.imageWidthMm),
      imageHeightMm: clearImageHeightMm
          ? null
          : (imageHeightMm ?? this.imageHeightMm),
      imageXMm: clearImageXMm ? null : (imageXMm ?? this.imageXMm),
      imageYMm: clearImageYMm ? null : (imageYMm ?? this.imageYMm),
      redHighlightRange: redHighlightRange ?? this.redHighlightRange,
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
    if (imagePath != null) 'imagePath': imagePath,
    'floatingImage': floatingImage,
    if (imageWidthMm != null) 'imageWidthMm': imageWidthMm,
    if (imageHeightMm != null) 'imageHeightMm': imageHeightMm,
    if (imageXMm != null) 'imageXMm': imageXMm,
    if (imageYMm != null) 'imageYMm': imageYMm,
    if (redHighlightRange.isNotEmpty) 'redHighlightRange': redHighlightRange,
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
    imagePath: json['imagePath'] as String?,
    floatingImage: json['floatingImage'] as bool? ?? false,
    imageWidthMm: (json['imageWidthMm'] as num?)?.toDouble(),
    imageHeightMm: (json['imageHeightMm'] as num?)?.toDouble(),
    imageXMm: (json['imageXMm'] as num?)?.toDouble(),
    imageYMm: (json['imageYMm'] as num?)?.toDouble(),
    redHighlightRange: _migrateRedHighlightRange(json),
  );

  static String _migrateRedHighlightRange(Map<String, dynamic> json) {
    final range = json['redHighlightRange'] as String?;
    if (range != null && range.isNotEmpty) return range;
    final count = (json['redHighlightCount'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      final start = (json['redHighlightStart'] as num?)?.toInt() ?? 1;
      return '${start}-${start + count - 1}';
    }
    return '';
  }
}


class Project {
  final String id;
  final String name;
  final ChineseScript chineseScript;
  final List<String> tags;
  final List<TextBlock> blocks;
  final PageSetup pageSetup;
  final String updatedAt;
  final String createdAt;

  Project({
    required this.id,
    required this.name,
    this.chineseScript = ChineseScript.unknown,
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
    ChineseScript? chineseScript,
    List<String>? tags,
    List<TextBlock>? blocks,
    PageSetup? pageSetup,
    String? updatedAt,
    String? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      chineseScript: chineseScript ?? this.chineseScript,
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
    'chineseScript': chineseScript.name,
    'tags': tags,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'pageSetup': pageSetup.toJson(),
    'updatedAt': updatedAt,
    'createdAt': createdAt,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    chineseScript: ChineseScript.fromJson(json['chineseScript']),
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
