import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../domain/project_todo_model.dart';

abstract class TodoRepository {
  Stream<List<ProjectTodo>> watchTodos(String workspaceId);
  Future<void> createTodo(ProjectTodo todo);
  Future<void> toggleTodoStatus(String workspaceId, String todoId, bool isCompleted);
  Future<void> updateTodoPriority(String workspaceId, String todoId, TodoPriority priority);
  Future<void> deleteTodo(String workspaceId, String todoId);
}

class FirestoreTodoRepository implements TodoRepository {
  final FirebaseFirestore _firestore;

  FirestoreTodoRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _todosCol(String workspaceId) =>
      _firestore
          .collection(FirebaseConstants.colWorkspaces)
          .doc(workspaceId)
          .collection(FirebaseConstants.subColProjectTodos);

  @override
  Stream<List<ProjectTodo>> watchTodos(String workspaceId) {
    return _todosCol(workspaceId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProjectTodo.fromFirestore(doc)).toList());
  }

  @override
  Future<void> createTodo(ProjectTodo todo) async {
    await _todosCol(todo.workspaceId).doc(todo.id).set(todo.toMap());
  }

  @override
  Future<void> toggleTodoStatus(
      String workspaceId, String todoId, bool isCompleted) async {
    await _todosCol(workspaceId).doc(todoId).update({'is_completed': isCompleted});
  }

  @override
  Future<void> updateTodoPriority(
      String workspaceId, String todoId, TodoPriority priority) async {
    await _todosCol(workspaceId)
        .doc(todoId)
        .update({'priority': priority.value});
  }

  @override
  Future<void> deleteTodo(String workspaceId, String todoId) async {
    await _todosCol(workspaceId).doc(todoId).delete();
  }
}
