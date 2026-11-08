import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';

/// Sets the native macOS window appearance so the title bar matches the
/// app's resolved theme instead of following the system appearance.
class WindowAppearanceService {
  WindowAppearanceService._();

  static const _channel = MethodChannel(
    'tibetan_typesetting/window_appearance',
  );

  static Future<void> set(AppTheme theme) async {
    final mode = switch (theme) {
      AppTheme.light => 'light',
      AppTheme.dark => 'dark',
      AppTheme.system => 'system',
    };
    try {
      await _channel.invokeMethod('set', mode);
    } on MissingPluginException {
      // Non-macOS platforms do not register this channel.
    } on Object catch (e) {
      debugPrint('Failed to set window appearance: $e');
    }
  }
}
