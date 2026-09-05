import 'package:cloud_firestore/cloud_firestore.dart';

class FlowEntry {
  final String id;
  final String workspaceId;
  final String featureName;
  final List<String> flowSteps;
  final List<String> keyFiles;
  final String stateNotes;
  final String nextTodo;
  final List<String> tags;
  final DateTime createdAt;

  const FlowEntry({
    required this.id,
    required this.workspaceId,
    required this.featureName,
    required this.flowSteps,
    this.keyFiles = const [],
    this.stateNotes = '',
    required this.nextTodo,
    this.tags = const [],
    required this.createdAt,
  });

  FlowEntry copyWith({
    String? id,
    String? workspaceId,
    String? featureName,
    List<String>? flowSteps,
    List<String>? keyFiles,
    String? stateNotes,
    String? nextTodo,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return FlowEntry(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      featureName: featureName ?? this.featureName,
      flowSteps: flowSteps ?? this.flowSteps,
      keyFiles: keyFiles ?? this.keyFiles,
      stateNotes: stateNotes ?? this.stateNotes,
      nextTodo: nextTodo ?? this.nextTodo,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'feature_name': featureName,
      'flow_steps': flowSteps,
      'key_files': keyFiles,
      'state_notes': stateNotes,
      'next_todo': nextTodo,
      'tags': tags,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory FlowEntry.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return FlowEntry(
      id: map['id'] as String? ?? documentId ?? '',
      workspaceId: map['workspace_id'] as String? ?? '',
      featureName: map['feature_name'] as String? ?? '',
      flowSteps: parseList(map['flow_steps']),
      keyFiles: parseList(map['key_files']),
      stateNotes: map['state_notes'] as String? ?? '',
      nextTodo: map['next_todo'] as String? ?? '',
      tags: parseList(map['tags']),
      createdAt: parseDate(map['created_at']),
    );
  }

  factory FlowEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return FlowEntry.fromMap(doc.data() ?? {}, documentId: doc.id);
  }
}
