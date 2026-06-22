import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides the physical screen DPI so the preview can match the real
/// physical size of the exported PDF.
///
/// Flutter logical pixels always assume 96 DPI, but Retina displays have a
/// higher logical DPI (e.g. ~120 on a 16" MacBook Pro). Using 96 DPI makes
/// the preview ~80% of real size, so a 10pt font appears as 8pt — 2pt smaller.
///
/// This service fetches the actual screen DPI via a platform channel and
/// exposes [mmToPx] and [ptToPx] that replace the hardcoded [kMmToPx] = 3.78
/// and [ptToPreviewPx] = 1.333 constants.
class ScreenDpiService {
  ScreenDpiService._();
  static final ScreenDpiService _instance = ScreenDpiService._();
  factory ScreenDpiService() => _instance;

  static const _channel = MethodChannel('tibetan_typesetting/system_fonts');

  double _dpi = 96.0;
  bool _initialized = false;

  double get dpi {
    assert(_initialized, 'Call init() before accessing dpi');
    return _dpi;
  }

  double get mmToPx => _dpi / 25.4;
  double get ptToPx => _dpi / 72.0;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final result = await _channel.invokeMethod<double>('getScreenDpi');
      if (result != null && result > 0) {
        _dpi = result;
      }
    } on MissingPluginException {
      // Platform doesn't implement getScreenDpi (e.g. test environment).
    } on PlatformException catch (e) {
      debugPrint('Failed to get screen DPI: ${e.message}');
    }
    _initialized = true;
  }
}
