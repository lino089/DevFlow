import 'package:cloud_firestore/cloud_firestore.dart';

class CodeAnnotation {
  final String id;
  final String workspaceId;
  final String fileRelativePath;
  final int lineNumber;
  final String codeSnippet;
  final String note;
  final DateTime createdAt;

  const CodeAnnotation({
    required this.id,
    required this.workspaceId,
    required this.fileRelativePath,
    required this.lineNumber,
    required this.codeSnippet,
    required this.note,
    required this.createdAt,
  });

  CodeAnnotation copyWith({
    String? id,
    String? workspaceId,
    String? fileRelativePath,
    int? lineNumber,
    String? codeSnippet,
    String? note,
    DateTime? createdAt,
  }) {
    return CodeAnnotation(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      fileRelativePath: fileRelativePath ?? this.fileRelativePath,
      lineNumber: lineNumber ?? this.lineNumber,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'file_relative_path': fileRelativePath,
      'line_number': lineNumber,
      'code_snippet': codeSnippet,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory CodeAnnotation.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CodeAnnotation(
      id: map['id'] as String? ?? documentId ?? '',
      workspaceId: map['workspace_id'] as String? ?? '',
      fileRelativePath: map['file_relative_path'] as String? ?? '',
      lineNumber: (map['line_number'] as num?)?.toInt() ?? 1,
      codeSnippet: map['code_snippet'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: parseDate(map['created_at']),
    );
  }

  factory CodeAnnotation.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CodeAnnotation.fromMap(doc.data() ?? {}, documentId: doc.id);
  }
}
