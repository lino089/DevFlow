import 'package:cloud_firestore/cloud_firestore.dart';

class Workspace {
  final String workspaceId;
  final String userId;
  final String name;
  final String localPath;
  final DateTime createdAt;

  const Workspace({
    required this.workspaceId,
    required this.userId,
    required this.name,
    required this.localPath,
    required this.createdAt,
  });

  Workspace copyWith({
    String? workspaceId,
    String? userId,
    String? name,
    String? localPath,
    DateTime? createdAt,
  }) {
    return Workspace(
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspace_id': workspaceId,
      'user_id': userId,
      'name': name,
      'local_path': localPath,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory Workspace.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Workspace(
      workspaceId: map['workspace_id'] as String? ?? documentId ?? '',
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      localPath: map['local_path'] as String? ?? '',
      createdAt: parseDate(map['created_at']),
    );
  }

  factory Workspace.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Workspace.fromMap(doc.data() ?? {}, documentId: doc.id);
  }
}
