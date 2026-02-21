class PronunciationEntry {
  final String tibetanSyllable;
  final String chinesePronunciation;
  final String createdAt;
  final String updatedAt;

  PronunciationEntry({
    required this.tibetanSyllable,
    required this.chinesePronunciation,
    required this.createdAt,
    required this.updatedAt,
  });

  PronunciationEntry copyWith({
    String? tibetanSyllable,
    String? chinesePronunciation,
    String? createdAt,
    String? updatedAt,
  }) {
    return PronunciationEntry(
      tibetanSyllable: tibetanSyllable ?? this.tibetanSyllable,
      chinesePronunciation: chinesePronunciation ?? this.chinesePronunciation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'tibetanSyllable': tibetanSyllable,
    'chinesePronunciation': chinesePronunciation,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory PronunciationEntry.fromJson(Map<String, dynamic> json) =>
      PronunciationEntry(
        tibetanSyllable: json['tibetanSyllable'] as String,
        chinesePronunciation: json['chinesePronunciation'] as String,
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}
