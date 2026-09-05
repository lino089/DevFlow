import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../data/todo_repository.dart';
import '../domain/project_todo_model.dart';

enum TodoFilter { all, active, completed }

/// Provider for TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreTodoRepository(firestore);
});

/// Stream of todos for currently selected workspace
final todosStreamProvider = StreamProvider<List<ProjectTodo>>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  if (workspace == null) return Stream.value([]);
  final repo = ref.watch(todoRepositoryProvider);
  return repo.watchTodos(workspace.workspaceId);
});

/// Current filter state (all, active, completed)
final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

/// Filtered todos provider
final filteredTodosProvider = Provider<AsyncValue<List<ProjectTodo>>>((ref) {
  final todosAsync = ref.watch(todosStreamProvider);
  final filter = ref.watch(todoFilterProvider);

  return todosAsync.whenData((todos) {
    switch (filter) {
      case TodoFilter.active:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
      case TodoFilter.all:
        return todos;
    }
  });
});
