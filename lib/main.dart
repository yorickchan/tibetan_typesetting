import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'models/app_settings.dart';
import 'pages/projects_page.dart';
import 'pages/settings_page.dart';
import 'services/database_service.dart';
import 'services/font_service.dart';
import 'services/settings_service.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService().database;

  // Pre-load app settings and register configured fonts for preview
  final settings = await SettingsService().getSettings();
  final fontService = FontService();
  for (final c in [
    settings.tibetanFont,
    settings.pronunciationFont,
    settings.translationFont,
  ]) {
    if (c != null) await fontService.loadFontForPreview(c);
  }

  runApp(TibetanTypesettingApp(initialSettings: settings));
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
        key: ValueKey('${_settings.theme}${_settings.locale}'),
        navigatorKey: rootNavigatorKey,
        title: 'Tibetan Typesetting',
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: _HomeWrapper(
          needsSetup: !_settings.hasFontsConfigured,
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
