import '../models/project.dart';

class UndoService {
  static const int _maxStackSize = 50;

  final List<Project> _undoStack = [];
  final List<Project> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void pushState(Project project) {
    _undoStack.add(project);
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  Project? undo(Project current) {
    if (!canUndo) return null;
    _redoStack.add(current);
    return _undoStack.removeLast();
  }

  Project? redo(Project current) {
    if (!canRedo) return null;
    _undoStack.add(current);
    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
