import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../domain/code_annotation_model.dart';

abstract class AnnotationRepository {
  Stream<List<CodeAnnotation>> watchAnnotationsForFile(
      String workspaceId, String fileRelativePath);
  Stream<List<CodeAnnotation>> watchAllAnnotations(String workspaceId);
  Future<void> createAnnotation(CodeAnnotation annotation);
  Future<void> deleteAnnotation(String workspaceId, String annotationId);
}

class FirestoreAnnotationRepository implements AnnotationRepository {
  final FirebaseFirestore _firestore;

  FirestoreAnnotationRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _annotationsCol(
          String workspaceId) =>
      _firestore
          .collection(FirebaseConstants.colWorkspaces)
          .doc(workspaceId)
          .collection(FirebaseConstants.subColCodeAnnotations);

  @override
  Stream<List<CodeAnnotation>> watchAnnotationsForFile(
      String workspaceId, String fileRelativePath) {
    return _annotationsCol(workspaceId)
        .where('file_relative_path', isEqualTo: fileRelativePath)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => CodeAnnotation.fromFirestore(doc)).toList();
      // Urutkan berdasarkan line_number secara ascending
      list.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
      return list;
    });
  }

  @override
  Stream<List<CodeAnnotation>> watchAllAnnotations(String workspaceId) {
    return _annotationsCol(workspaceId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CodeAnnotation.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> createAnnotation(CodeAnnotation annotation) async {
    await _annotationsCol(annotation.workspaceId)
        .doc(annotation.id)
        .set(annotation.toMap());
  }

  @override
  Future<void> deleteAnnotation(String workspaceId, String annotationId) async {
    await _annotationsCol(workspaceId).doc(annotationId).delete();
  }
}
