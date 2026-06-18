import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Typesetting'**
  String get appTitle;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get searchProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Create one to start.'**
  String get noProjectsYet;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This cannot be undone.'**
  String areYouSureDelete(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @projectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get projectCreated;

  /// No description provided for @projectUpdated.
  ///
  /// In en, this message translates to:
  /// **'Project updated'**
  String get projectUpdated;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get projectDeleted;

  /// No description provided for @projectDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Project duplicated'**
  String get projectDuplicated;

  /// No description provided for @projectExported.
  ///
  /// In en, this message translates to:
  /// **'Project exported'**
  String get projectExported;

  /// No description provided for @projectImported.
  ///
  /// In en, this message translates to:
  /// **'Project imported'**
  String get projectImported;

  /// No description provided for @failedToCreateProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to create project'**
  String get failedToCreateProject;

  /// No description provided for @failedToUpdateProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to update project'**
  String get failedToUpdateProject;

  /// No description provided for @failedToDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete project'**
  String get failedToDeleteProject;

  /// No description provided for @failedToDuplicateProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to duplicate project'**
  String get failedToDuplicateProject;

  /// No description provided for @failedToExportProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to export project'**
  String get failedToExportProject;

  /// No description provided for @failedToImportProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to import project'**
  String get failedToImportProject;

  /// No description provided for @renameProject.
  ///
  /// In en, this message translates to:
  /// **'Rename Project'**
  String get renameProject;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated tags'**
  String get tagsHint;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updated(String date);

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @addBlock.
  ///
  /// In en, this message translates to:
  /// **'Add Block'**
  String get addBlock;

  /// No description provided for @deleteBlock.
  ///
  /// In en, this message translates to:
  /// **'Delete Block'**
  String get deleteBlock;

  /// No description provided for @moveBlockUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveBlockUp;

  /// No description provided for @moveBlockDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveBlockDown;

  /// No description provided for @lineBreak.
  ///
  /// In en, this message translates to:
  /// **'Line break'**
  String get lineBreak;

  /// No description provided for @newPage.
  ///
  /// In en, this message translates to:
  /// **'New page'**
  String get newPage;

  /// No description provided for @smallText.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get smallText;

  /// No description provided for @freeText.
  ///
  /// In en, this message translates to:
  /// **'Free text'**
  String get freeText;

  /// No description provided for @freeTextContent.
  ///
  /// In en, this message translates to:
  /// **'Chinese or English text'**
  String get freeTextContent;

  /// No description provided for @openingMark.
  ///
  /// In en, this message translates to:
  /// **'Opening mark'**
  String get openingMark;

  /// No description provided for @tibetanText.
  ///
  /// In en, this message translates to:
  /// **'Tibetan text'**
  String get tibetanText;

  /// No description provided for @chinesePronunciation.
  ///
  /// In en, this message translates to:
  /// **'Chinese pronunciation'**
  String get chinesePronunciation;

  /// No description provided for @chineseTranslation.
  ///
  /// In en, this message translates to:
  /// **'Chinese translation'**
  String get chineseTranslation;

  /// No description provided for @selectBlockToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select a block above to start editing.'**
  String get selectBlockToEdit;

  /// No description provided for @blockNumber.
  ///
  /// In en, this message translates to:
  /// **'Block {current} of {total}'**
  String blockNumber(int current, int total);

  /// No description provided for @pageSetup.
  ///
  /// In en, this message translates to:
  /// **'Page Setup'**
  String get pageSetup;

  /// No description provided for @pageWidth.
  ///
  /// In en, this message translates to:
  /// **'Width (mm)'**
  String get pageWidth;

  /// No description provided for @pageHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (mm)'**
  String get pageHeight;

  /// No description provided for @margins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get margins;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @autoPerPage.
  ///
  /// In en, this message translates to:
  /// **'Auto per page'**
  String get autoPerPage;

  /// No description provided for @sentenceSpacing.
  ///
  /// In en, this message translates to:
  /// **'Sentence spacing'**
  String get sentenceSpacing;

  /// No description provided for @showFrame.
  ///
  /// In en, this message translates to:
  /// **'Show frame'**
  String get showFrame;

  /// No description provided for @showRowLines.
  ///
  /// In en, this message translates to:
  /// **'Show row lines'**
  String get showRowLines;

  /// No description provided for @leftVerticalTitle.
  ///
  /// In en, this message translates to:
  /// **'Left vertical title'**
  String get leftVerticalTitle;

  /// No description provided for @pageNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageNumberLabel;

  /// No description provided for @exportPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Use Export PDF to output. Zoom: Cmd +/−/0'**
  String get exportPdfHint;

  /// No description provided for @titlePage.
  ///
  /// In en, this message translates to:
  /// **'Title page'**
  String get titlePage;

  /// No description provided for @showTitlePage.
  ///
  /// In en, this message translates to:
  /// **'Show title page'**
  String get showTitlePage;

  /// No description provided for @titleTibetanLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (Tibetan)'**
  String get titleTibetanLabel;

  /// No description provided for @titleChineseLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (Chinese)'**
  String get titleChineseLabel;

  /// No description provided for @projectFonts.
  ///
  /// In en, this message translates to:
  /// **'Project fonts'**
  String get projectFonts;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @tibetanLabel.
  ///
  /// In en, this message translates to:
  /// **'Tibetan'**
  String get tibetanLabel;

  /// No description provided for @chineseLabel.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chineseLabel;

  /// No description provided for @titleTibetanFont.
  ///
  /// In en, this message translates to:
  /// **'Title Tibetan Font'**
  String get titleTibetanFont;

  /// No description provided for @titleChineseFont.
  ///
  /// In en, this message translates to:
  /// **'Title Chinese Font'**
  String get titleChineseFont;

  /// No description provided for @defaultValueWithName.
  ///
  /// In en, this message translates to:
  /// **'Default: {name}'**
  String defaultValueWithName(String name);

  /// No description provided for @dharmaWheel.
  ///
  /// In en, this message translates to:
  /// **'Dharma Wheel'**
  String get dharmaWheel;

  /// No description provided for @fonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get fonts;

  /// No description provided for @tibetanFont.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Font'**
  String get tibetanFont;

  /// No description provided for @pronunciationFont.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Font'**
  String get pronunciationFont;

  /// No description provided for @translationFont.
  ///
  /// In en, this message translates to:
  /// **'Translation Font'**
  String get translationFont;

  /// No description provided for @defaultValue.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultValue;

  /// No description provided for @defaultFont.
  ///
  /// In en, this message translates to:
  /// **'Default value: {name}'**
  String defaultFont(String name);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fontSize;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportSettings.
  ///
  /// In en, this message translates to:
  /// **'Export Settings'**
  String get exportSettings;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get printing;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveError;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Tibetan Typesetting'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @exportProjectJson.
  ///
  /// In en, this message translates to:
  /// **'Export Project JSON'**
  String get exportProjectJson;

  /// No description provided for @applicationSettings.
  ///
  /// In en, this message translates to:
  /// **'Application Settings'**
  String get applicationSettings;

  /// No description provided for @configureFonts.
  ///
  /// In en, this message translates to:
  /// **'Please configure your default fonts to get started.'**
  String get configureFonts;

  /// No description provided for @defaultFonts.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT FONTS'**
  String get defaultFonts;

  /// No description provided for @defaultPageSize.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT PAGE SIZE'**
  String get defaultPageSize;

  /// No description provided for @tibetan.
  ///
  /// In en, this message translates to:
  /// **'Tibetan'**
  String get tibetan;

  /// No description provided for @pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pronunciation;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @pronunciationDictionary.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Dictionary'**
  String get pronunciationDictionary;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{syllable}\"?'**
  String deleteEntry(String syllable);

  /// No description provided for @charactersInPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Characters in pronunciation:'**
  String get charactersInPronunciation;

  /// No description provided for @syllableMapsToChars.
  ///
  /// In en, this message translates to:
  /// **'This syllable maps to {count} Chinese characters when auto-filling.'**
  String syllableMapsToChars(int count);

  /// No description provided for @exportDictionary.
  ///
  /// In en, this message translates to:
  /// **'Export Dictionary'**
  String get exportDictionary;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Search entries'**
  String get searchEntries;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Type Tibetan and pronunciation in the editor to auto-save.'**
  String get noEntriesYet;

  /// No description provided for @noMatchingEntries.
  ///
  /// In en, this message translates to:
  /// **'No matching entries.'**
  String get noMatchingEntries;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} entries'**
  String importedCount(int count);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @tibetanLabelShort.
  ///
  /// In en, this message translates to:
  /// **'TIBETAN'**
  String get tibetanLabelShort;

  /// No description provided for @pronunciationLabelShort.
  ///
  /// In en, this message translates to:
  /// **'PRONUNCIATION'**
  String get pronunciationLabelShort;

  /// No description provided for @translationLabelShort.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION'**
  String get translationLabelShort;

  /// No description provided for @titlePageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Title Page Templates'**
  String get titlePageTemplates;

  /// No description provided for @titlePageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get titlePageTemplate;

  /// No description provided for @addTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add Template'**
  String get addTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @templateInset.
  ///
  /// In en, this message translates to:
  /// **'Template margin (mm)'**
  String get templateInset;

  /// No description provided for @templateInsetHint.
  ///
  /// In en, this message translates to:
  /// **'Margin around custom template'**
  String get templateInsetHint;

  /// No description provided for @titleTextInset.
  ///
  /// In en, this message translates to:
  /// **'Title text box margin (mm)'**
  String get titleTextInset;

  /// No description provided for @titleTextInsetHint.
  ///
  /// In en, this message translates to:
  /// **'Margin around title text box'**
  String get titleTextInsetHint;

  /// No description provided for @invalidSvgFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid SVG file'**
  String get invalidSvgFile;

  /// No description provided for @defaultLayout.
  ///
  /// In en, this message translates to:
  /// **'Default layout'**
  String get defaultLayout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
