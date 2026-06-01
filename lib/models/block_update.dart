import 'project.dart';

class BlockUpdate {
  final String? tibetan;
  final String? chinesePronunciation;
  final String? chineseTranslation;
  final TextBlockFormat? format;
  final int? columnSpan;
  final bool clearColumnSpan;

  const BlockUpdate({
    this.tibetan,
    this.chinesePronunciation,
    this.chineseTranslation,
    this.format,
    this.columnSpan,
    this.clearColumnSpan = false,
  });
}
