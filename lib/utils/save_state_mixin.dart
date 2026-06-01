import 'package:flutter/material.dart';

mixin SaveStateMixin<T extends StatefulWidget> on State<T> {
  String _saveState = 'idle';
  String get saveState => _saveState;

  Future<void> performSave(Future<void> Function() saveAction) async {
    if (!mounted) return;
    setState(() => _saveState = 'saving');
    try {
      await saveAction();
      if (!mounted) return;
      setState(() => _saveState = 'saved');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _saveState == 'saved') {
          setState(() => _saveState = 'idle');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveState = 'error');
    }
  }
}
