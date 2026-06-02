import 'dart:async';

import 'package:flutter/material.dart';

enum SaveState { idle, saving, saved, error }

mixin SaveStateMixin<T extends StatefulWidget> on State<T> {
  SaveState _saveState = SaveState.idle;
  SaveState get saveState => _saveState;
  Object? _saveError;
  Object? get saveError => _saveError;

  Timer? _idleTimer;

  Future<void> performSave(Future<void> Function() saveAction) async {
    if (!mounted) return;
    _idleTimer?.cancel();
    setState(() {
      _saveState = SaveState.saving;
      _saveError = null;
    });
    try {
      await saveAction();
      if (!mounted) return;
      setState(() => _saveState = SaveState.saved);
      _idleTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && _saveState == SaveState.saved) {
          setState(() => _saveState = SaveState.idle);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveState = SaveState.error;
        _saveError = e;
      });
    }
  }

  void disposeSaveStateTimer() {
    _idleTimer?.cancel();
  }
}
