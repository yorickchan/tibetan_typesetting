import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/html_export_service.dart';

void main() {
  test('generateHtml produces valid HTML', () {
    final project = Project(
      id: '1',
      name: 'Test Project',
      updatedAt: '',
      createdAt: '',
      blocks: [
        TextBlock(id: 'b1', tibetan: 'བཀྲ་ཤིས།', chineseTranslation: '吉祥'),
      ],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('<!DOCTYPE html>'));
    expect(html, contains('Test Project'));
    expect(html, contains('བཀྲ་ཤིས།'));
    expect(html, contains('吉祥'));
  });

  test('generateHtml escapes HTML entities', () {
    final project = Project(
      id: '1',
      name: '<Test>',
      updatedAt: '',
      createdAt: '',
      blocks: [
        TextBlock(id: 'b1', tibetan: 'a & b', chineseTranslation: ''),
      ],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('&lt;Test&gt;'));
    expect(html, contains('a &amp; b'));
  });

  test('generateHtml includes title page when enabled', () {
    final project = Project(
      id: '1',
      name: 'Test',
      updatedAt: '',
      createdAt: '',
      pageSetup: PageSetup(
        showTitlePage: true,
        titleTibetan: 'དཔེ་དེབ།',
        titleChinese: '書名',
      ),
      blocks: [],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('title-page'));
    expect(html, contains('དཔེ་དེབ།'));
    expect(html, contains('書名'));
  });

  test('generateHtml skips title page when disabled', () {
    final project = Project(
      id: '1',
      name: 'Test',
      updatedAt: '',
      createdAt: '',
      pageSetup: PageSetup(showTitlePage: false, titleTibetan: 'X'),
      blocks: [],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, isNot(contains('<div class="title-page"')));
  });

  test('generateHtml includes page break markers', () {
    final project = Project(
      id: '1',
      name: 'Test',
      updatedAt: '',
      createdAt: '',
      blocks: [
        TextBlock(id: 'b1', tibetan: 'one'),
        TextBlock(id: 'b2', tibetan: 'two', pageBreakBefore: true),
        TextBlock(id: 'b3', tibetan: 'three'),
      ],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('<div class="page-break">'));
  });
}
