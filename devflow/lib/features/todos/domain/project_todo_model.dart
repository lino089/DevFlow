import 'package:cloud_firestore/cloud_firestore.dart';

enum TodoPriority {
  low,
  medium,
  high;

  static TodoPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
        return TodoPriority.high;
      case 'low':
        return TodoPriority.low;
      case 'medium':
      default:
        return TodoPriority.medium;
    }
  }

  String get value => name;
}

class ProjectTodo {
  final String id;
  final String workspaceId;
  final String title;
  final TodoPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  const ProjectTodo({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.priority = TodoPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
  });

  ProjectTodo copyWith({
    String? id,
    String? workspaceId,
    String? title,
    TodoPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ProjectTodo(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'title': title,
      'priority': priority.value,
      'is_completed': isCompleted,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ProjectTodo.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ProjectTodo(
      id: map['id'] as String? ?? documentId ?? '',
      workspaceId: map['workspace_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      priority: TodoPriority.fromString(map['priority'] as String?),
      isCompleted: map['is_completed'] as bool? ?? false,
      createdAt: parseDate(map['created_at']),
    );
  }

  factory ProjectTodo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProjectTodo.fromMap(doc.data() ?? {}, documentId: doc.id);
  }
}
