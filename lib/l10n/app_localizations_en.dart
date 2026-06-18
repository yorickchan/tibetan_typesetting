// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tibetan Typesetting';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New Project';

  @override
  String get searchProjects => 'Search projects';

  @override
  String get noProjectsYet => 'No projects yet. Create one to start.';

  @override
  String get open => 'Open';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportJson => 'JSON';

  @override
  String get importJson => 'Import JSON';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String areYouSureDelete(String name) {
    return 'Are you sure you want to delete $name? This cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get projectCreated => 'Project created';

  @override
  String get projectUpdated => 'Project updated';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get projectDuplicated => 'Project duplicated';

  @override
  String get projectExported => 'Project exported';

  @override
  String get projectImported => 'Project imported';

  @override
  String get failedToCreateProject => 'Failed to create project';

  @override
  String get failedToUpdateProject => 'Failed to update project';

  @override
  String get failedToDeleteProject => 'Failed to delete project';

  @override
  String get failedToDuplicateProject => 'Failed to duplicate project';

  @override
  String get failedToExportProject => 'Failed to export project';

  @override
  String get failedToImportProject => 'Failed to import project';

  @override
  String get renameProject => 'Rename Project';

  @override
  String get name => 'Name';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Comma-separated tags';

  @override
  String get projectName => 'Project name';

  @override
  String updated(String date) {
    return 'Updated $date';
  }

  @override
  String get editor => 'Editor';

  @override
  String get addBlock => 'Add Block';

  @override
  String get deleteBlock => 'Delete Block';

  @override
  String get moveBlockUp => 'Move Up';

  @override
  String get moveBlockDown => 'Move Down';

  @override
  String get lineBreak => 'Line break';

  @override
  String get newPage => 'New page';

  @override
  String get smallText => 'Small';

  @override
  String get freeText => 'Free text';

  @override
  String get freeTextContent => 'Chinese or English text';

  @override
  String get openingMark => 'Opening mark';

  @override
  String get tibetanText => 'Tibetan text';

  @override
  String get chinesePronunciation => 'Chinese pronunciation';

  @override
  String get chineseTranslation => 'Chinese translation';

  @override
  String get selectBlockToEdit => 'Select a block above to start editing.';

  @override
  String blockNumber(int current, int total) {
    return 'Block $current of $total';
  }

  @override
  String get pageSetup => 'Page Setup';

  @override
  String get pageWidth => 'Width (mm)';

  @override
  String get pageHeight => 'Height (mm)';

  @override
  String get margins => 'Margins';

  @override
  String get top => 'Top';

  @override
  String get bottom => 'Bottom';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get columns => 'Columns';

  @override
  String get autoPerPage => 'Auto per page';

  @override
  String get sentenceSpacing => 'Sentence spacing';

  @override
  String get showFrame => 'Show frame';

  @override
  String get showRowLines => 'Show row lines';

  @override
  String get leftVerticalTitle => 'Left vertical title';

  @override
  String get pageNumberLabel => 'Page number';

  @override
  String get exportPdfHint => 'Use Export PDF to output. Zoom: Cmd +/−/0';

  @override
  String get titlePage => 'Title page';

  @override
  String get showTitlePage => 'Show title page';

  @override
  String get titleTibetanLabel => 'Title (Tibetan)';

  @override
  String get titleChineseLabel => 'Title (Chinese)';

  @override
  String get projectFonts => 'Project fonts';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get tibetanLabel => 'Tibetan';

  @override
  String get chineseLabel => 'Chinese';

  @override
  String get titleTibetanFont => 'Title Tibetan Font';

  @override
  String get titleChineseFont => 'Title Chinese Font';

  @override
  String defaultValueWithName(String name) {
    return 'Default: $name';
  }

  @override
  String get dharmaWheel => 'Dharma Wheel';

  @override
  String get fonts => 'Fonts';

  @override
  String get tibetanFont => 'Tibetan Font';

  @override
  String get pronunciationFont => 'Pronunciation Font';

  @override
  String get translationFont => 'Translation Font';

  @override
  String get defaultValue => 'Default';

  @override
  String defaultFont(String name) {
    return 'Default value: $name';
  }

  @override
  String get reset => 'Reset';

  @override
  String get fontSize => 'Size';

  @override
  String get preferences => 'Preferences';

  @override
  String get settings => 'Settings';

  @override
  String get export => 'Export';

  @override
  String get exportSettings => 'Export Settings';

  @override
  String get preview => 'Preview';

  @override
  String get printing => 'Printing';

  @override
  String get print => 'Print';

  @override
  String get savePdf => 'Save PDF';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get projectNotFound => 'Project not found';

  @override
  String get saving => 'Saving...';

  @override
  String get saved => 'Saved';

  @override
  String get saveError => 'Save failed';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get selectAll => 'Select All';

  @override
  String get about => 'About Tibetan Typesetting';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get systemDefault => 'System Default';

  @override
  String get untitled => 'Untitled';

  @override
  String get exportProjectJson => 'Export Project JSON';

  @override
  String get applicationSettings => 'Application Settings';

  @override
  String get configureFonts =>
      'Please configure your default fonts to get started.';

  @override
  String get defaultFonts => 'DEFAULT FONTS';

  @override
  String get defaultPageSize => 'DEFAULT PAGE SIZE';

  @override
  String get tibetan => 'Tibetan';

  @override
  String get pronunciation => 'Pronunciation';

  @override
  String get translation => 'Translation';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get size => 'Size';

  @override
  String get pronunciationDictionary => 'Pronunciation Dictionary';

  @override
  String deleteEntry(String syllable) {
    return 'Delete \"$syllable\"?';
  }

  @override
  String get charactersInPronunciation => 'Characters in pronunciation:';

  @override
  String syllableMapsToChars(int count) {
    return 'This syllable maps to $count Chinese characters when auto-filling.';
  }

  @override
  String get exportDictionary => 'Export Dictionary';

  @override
  String get import => 'Import';

  @override
  String get searchEntries => 'Search entries';

  @override
  String get noEntriesYet =>
      'No entries yet. Type Tibetan and pronunciation in the editor to auto-save.';

  @override
  String get noMatchingEntries => 'No matching entries.';

  @override
  String get edit => 'Edit';

  @override
  String importedCount(int count) {
    return 'Imported $count entries';
  }

  @override
  String get block => 'Block';

  @override
  String get move => 'Move';

  @override
  String get tibetanLabelShort => 'TIBETAN';

  @override
  String get pronunciationLabelShort => 'PRONUNCIATION';

  @override
  String get translationLabelShort => 'TRANSLATION';

  @override
  String get titlePageTemplates => 'Title Page Templates';

  @override
  String get titlePageTemplate => 'Template';

  @override
  String get addTemplate => 'Add Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateInset => 'Template margin (mm)';

  @override
  String get templateInsetHint => 'Margin around custom template';

  @override
  String get titleTextInset => 'Title text box margin (mm)';

  @override
  String get titleTextInsetHint => 'Margin around title text box';

  @override
  String get invalidSvgFile => 'Invalid SVG file';

  @override
  String get defaultLayout => 'Default layout';
}
