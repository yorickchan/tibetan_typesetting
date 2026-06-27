import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'models/app_settings.dart';
import 'pages/database_recovery_page.dart';
import 'pages/projects_page.dart';
import 'pages/settings_page.dart';
import 'services/database_location_provider.dart';
import 'services/database_location_service.dart';
import 'services/database_service.dart';
import 'services/database_startup_controller.dart';
import 'services/font_service.dart';
import 'services/settings_service.dart';
import 'services/screen_dpi_service.dart';
import 'utils/colors.dart';
import 'utils/font_utils.dart' as font_utils;
import 'widgets/sample_page.dart' show kMmToPx;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenDpiService().init();
  kMmToPx = ScreenDpiService().mmToPx;
  font_utils.ptToPreviewPx = ScreenDpiService().ptToPx;

  runApp(const _DatabaseStartupGate());
}

class _DatabaseStartupGate extends StatefulWidget {
  const _DatabaseStartupGate();

  @override
  State<_DatabaseStartupGate> createState() => _DatabaseStartupGateState();
}

class _DatabaseStartupGateState extends State<_DatabaseStartupGate> {
  late final DatabaseLocationService _locationService;
  late final DatabaseStartupController _startupController;
  DatabaseStartupResult? _startupResult;
  AppSettings? _settings;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    _locationService = createDatabaseLocationService();
    _startupController = DatabaseStartupController(
      resolveLocation: _locationService.resolveForStartup,
      configureDatabase: databaseService.configurePath,
      openDatabase: () async {
        await databaseService.database;
      },
    );
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) setState(() => _busy = true);
    final result = await _startupController.initialize();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _startupResult = result;
        _busy = false;
      });
      return;
    }

    final settings = await SettingsService().getSettings();
    final fontService = FontService();
    for (final config in [
      settings.tibetanFont,
      settings.pronunciationFont,
      settings.translationFont,
    ]) {
      if (config != null) await fontService.loadFontForPreview(config);
    }
    if (!mounted) return;
    setState(() {
      _startupResult = result;
      _settings = settings;
      _busy = false;
    });
  }

  Future<bool> _confirmCloudUse() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cloudDatabaseConfirmationTitle),
            content: Text(l10n.cloudDatabaseConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _chooseAnotherDatabase() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db'],
      dialogTitle: l10n.chooseAnotherDatabase,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted || !await _confirmCloudUse()) return;
    String? bookmarkRootPath;
    if (Platform.isMacOS) {
      bookmarkRootPath = await FilePicker.getDirectoryPath(
        dialogTitle: l10n.authorizeDatabaseFolder,
        initialDirectory: File(path).parent.path,
      );
      if (bookmarkRootPath == null || !mounted) return;
    }
    setState(() => _busy = true);
    final selection = await _locationService.selectExisting(
      path,
      bookmarkRootPath: bookmarkRootPath,
    );
    if (!mounted) return;
    if (!selection.isValid) {
      setState(() {
        _startupResult = DatabaseStartupResult.failure(
          selection.issue,
          version: selection.version,
        );
        _busy = false;
      });
      return;
    }
    await _initialize();
  }

  Future<void> _useDefaultDatabase() async {
    setState(() => _busy = true);
    await _locationService.useDefault();
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings != null) {
      return TibetanTypesettingApp(initialSettings: settings);
    }
    AppColors.setBrightness(Brightness.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: AppColors.slate950,
        body: _startupResult == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.sky500),
              )
            : DatabaseRecoveryPage(
                issue: _startupResult!.issue,
                busy: _busy,
                onRetry: _initialize,
                onChooseAnother: _chooseAnotherDatabase,
                onUseDefault: _useDefaultDatabase,
              ),
      ),
    );
  }
}

/// Global key used to open the settings dialog from the platform menu.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class TibetanTypesettingApp extends StatefulWidget {
  final AppSettings initialSettings;

  const TibetanTypesettingApp({super.key, required this.initialSettings});

  @override
  State<TibetanTypesettingApp> createState() => _TibetanTypesettingAppState();
}

class _TibetanTypesettingAppState extends State<TibetanTypesettingApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  Locale? get _locale {
    final loc = _settings.locale;
    if (loc == null) return null;
    if (loc.contains('_')) {
      final parts = loc.split('_');
      return Locale(parts[0], parts[1]);
    }
    return Locale(loc);
  }

  Brightness get _brightness {
    switch (_settings.theme) {
      case AppTheme.light:
        return Brightness.light;
      case AppTheme.dark:
        return Brightness.dark;
      case AppTheme.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  ThemeData _buildTheme() {
    final isDark = _brightness == Brightness.dark;
    // Set semantic colors before building theme (must be called before
    // any widget reads AppColors statics during this build pass).
    AppColors.setBrightness(isDark ? Brightness.dark : Brightness.light);
    final bgColor = isDark ? AppColors.slate950 : AppColors.lightSlate50;

    const lightPrimary = Color(0xFF0284c7);
    const lightSecondary = Color(0xFF0ea5e9);
    const lightError = Color(0xFFdc2626);

    return ThemeData(
      brightness: _brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: isDark
          ? ColorScheme.dark(
              brightness: _brightness,
              primary: AppColors.sky500,
              secondary: AppColors.sky400,
              surface: AppColors.surface,
              error: AppColors.rose600,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors.textPrimary,
              onError: Colors.white,
            )
          : ColorScheme.light(
              brightness: _brightness,
              primary: lightPrimary,
              secondary: lightSecondary,
              surface: AppColors.surface,
              error: lightError,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors.textPrimary,
              onError: Colors.white,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.sky500,
        selectionColor: Color(0x400ea5e9),
        selectionHandleColor: AppColors.sky500,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettings({bool require = false}) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final result = await showDialog<AppSettings>(
      context: ctx,
      barrierDismissible: !require,
      builder: (_) => SettingsPage(requireFonts: require),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Tibetan Typesetting',
          menus: [
            PlatformMenuItemGroup(
              members: [
                const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.about,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Preferences…',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => _openSettings(),
                ),
              ],
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hide,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hideOtherApplications,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.showAllApplications,
                ),
              ],
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.quit,
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Undo',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: 'Redo',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: () {},
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Cut',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyX,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: 'Copy',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyC,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: 'Paste',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyV,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: 'Select All',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: [
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
          menus: [
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow,
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow,
            ),
          ],
        ),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Tibetan Typesetting',
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: _HomeWrapper(
          needsSetup: !_settings.hasAnyFontConfigured,
          onOpenSettings: () => _openSettings(require: true),
        ),
      ),
    );
  }
}

/// Wrapper that shows the first-launch settings dialog if no fonts are
/// configured yet.
class _HomeWrapper extends StatefulWidget {
  final bool needsSetup;
  final VoidCallback onOpenSettings;

  const _HomeWrapper({required this.needsSetup, required this.onOpenSettings});

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.needsSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOpenSettings();
      });
    }
  }

  @override
  Widget build(BuildContext context) => const ProjectsPage();
}
