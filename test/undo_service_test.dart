import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/undo_service.dart';

void main() {
  test('canUndo returns false when stack is empty', () {
    final service = UndoService();
    expect(service.canUndo, false);
    expect(service.canRedo, false);
  });

  test('undo returns previous state', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    final result = service.undo(proj2);

    expect(result, isNotNull);
    expect(result!.name, 'A');
    expect(service.canUndo, false);
    expect(service.canRedo, true);
  });

  test('redo restores state', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    service.undo(proj2);
    final result = service.redo(proj1);

    expect(result, isNotNull);
    expect(result!.name, 'B');
    expect(service.canUndo, true);
    expect(service.canRedo, false);
  });

  test('pushState clears redo stack', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    service.undo(proj2);
    expect(service.canRedo, true);

    service.pushState(proj2);
    expect(service.canRedo, false);
  });

  test('stack capped at 50', () {
    final service = UndoService();
    for (int i = 0; i < 60; i++) {
      service.pushState(
        Project(id: '$i', name: '$i', updatedAt: '', createdAt: ''),
      );
    }
    expect(service.canUndo, true);
    int count = 0;
    var current = Project(id: 'x', name: 'x', updatedAt: '', createdAt: '');
    while (service.canUndo) {
      current = service.undo(current)!;
      count++;
    }
    expect(count, 50);
  });
}
