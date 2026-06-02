class PronunciationEntry {
  final String tibetanSyllable;
  final String chinesePronunciation;
  final int wordCount;
  final String createdAt;
  final String updatedAt;

  const PronunciationEntry({
    required this.tibetanSyllable,
    required this.chinesePronunciation,
    this.wordCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PronunciationEntry &&
          tibetanSyllable == other.tibetanSyllable &&
          chinesePronunciation == other.chinesePronunciation &&
          wordCount == other.wordCount;

  @override
  int get hashCode => Object.hash(tibetanSyllable, chinesePronunciation, wordCount);

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
