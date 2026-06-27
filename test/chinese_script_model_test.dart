import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/chinese_script.dart';
import 'package:tibetan_typesetting/models/project.dart';

void main() {
  Project project({ChineseScript chineseScript = ChineseScript.unknown}) {
    return Project(
      id: 'project-1',
      name: 'Project',
      chineseScript: chineseScript,
      updatedAt: '2026-06-28T00:00:00Z',
      createdAt: '2026-06-28T00:00:00Z',
    );
  }

  test('project serializes its Chinese script', () {
    final original = project(chineseScript: ChineseScript.traditional);

    final restored = Project.fromJson(original.toJson());

    expect(restored.chineseScript, ChineseScript.traditional);
    expect(original.toJson()['chineseScript'], 'traditional');
  });

  test('legacy and malformed Chinese script values remain unknown', () {
    final legacyJson = project().toJson()..remove('chineseScript');
    final malformedJson = project().toJson()..['chineseScript'] = 'invalid';

    expect(Project.fromJson(legacyJson).chineseScript, ChineseScript.unknown);
    expect(
      Project.fromJson(malformedJson).chineseScript,
      ChineseScript.unknown,
    );
  });

  test('copyWith updates the Chinese script without mutating the project', () {
    final original = project();

    final updated = original.copyWith(chineseScript: ChineseScript.simplified);

    expect(original.chineseScript, ChineseScript.unknown);
    expect(updated.chineseScript, ChineseScript.simplified);
  });
}
