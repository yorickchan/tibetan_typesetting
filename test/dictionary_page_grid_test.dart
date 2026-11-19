import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/pages/dictionary_page.dart';

void main() {
  test('dictionary grid uses compact one-line cards', () {
    expect(kDictionaryCardMainAxisExtent, 36);
    expect(kDictionaryCardMaxCrossAxisExtent, 520);
    expect(kDictionaryCardCrossAxisSpacing, 8);
    expect(kDictionaryCardMainAxisSpacing, 6);
  });
}
