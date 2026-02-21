class PronunciationEntry {
  final String tibetanSyllable;
  final String chinesePronunciation;
  final int wordCount;
  final String createdAt;
  final String updatedAt;

  PronunciationEntry({
    required this.tibetanSyllable,
    required this.chinesePronunciation,
    this.wordCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  PronunciationEntry copyWith({
    String? tibetanSyllable,
    String? chinesePronunciation,
    int? wordCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return PronunciationEntry(
      tibetanSyllable: tibetanSyllable ?? this.tibetanSyllable,
      chinesePronunciation: chinesePronunciation ?? this.chinesePronunciation,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'tibetanSyllable': tibetanSyllable,
    'chinesePronunciation': chinesePronunciation,
    'wordCount': wordCount,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory PronunciationEntry.fromJson(Map<String, dynamic> json) =>
      PronunciationEntry(
        tibetanSyllable: json['tibetanSyllable'] as String,
        chinesePronunciation: json['chinesePronunciation'] as String,
        wordCount: (json['wordCount'] as int?) ?? 1,
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}
