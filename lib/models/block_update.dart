import 'project.dart';

class BlockUpdate {
  final String? tibetan;
  final String? chinesePronunciation;
  final String? chineseTranslation;
  final TextBlockFormat? format;
  final int? columnSpan;
  final bool clearColumnSpan;
  final bool? floatingImage;
  final double? imageWidthMm;
  final double? imageHeightMm;
  final double? imageXMm;
  final double? imageYMm;
  final String? redHighlightRange;
  final bool clearImageWidthMm;
  final bool clearImageHeightMm;
  final bool clearImageXMm;
  final bool clearImageYMm;

  const BlockUpdate({
    this.tibetan,
    this.chinesePronunciation,
    this.chineseTranslation,
    this.format,
    this.columnSpan,
    this.clearColumnSpan = false,
    this.floatingImage,
    this.imageWidthMm,
    this.imageHeightMm,
    this.imageXMm,
    this.imageYMm,
    this.redHighlightRange,
    this.clearImageWidthMm = false,
    this.clearImageHeightMm = false,
    this.clearImageXMm = false,
    this.clearImageYMm = false,
  });
}
