enum ChineseScript {
  unknown,
  simplified,
  traditional;

  static ChineseScript fromJson(Object? value) {
    return switch (value) {
      'simplified' => ChineseScript.simplified,
      'traditional' => ChineseScript.traditional,
      _ => ChineseScript.unknown,
    };
  }
}
