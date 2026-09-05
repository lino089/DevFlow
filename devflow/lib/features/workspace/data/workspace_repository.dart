import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../domain/workspace_model.dart';

abstract class WorkspaceRepository {
  Stream<List<Workspace>> watchWorkspaces(String userId);
  Future<void> createWorkspace(Workspace workspace);
  Future<void> updateWorkspaceName(String workspaceId, String newName);
  Future<void> deleteWorkspace(String workspaceId);
}

class FirestoreWorkspaceRepository implements WorkspaceRepository {
  final FirebaseFirestore _firestore;

  FirestoreWorkspaceRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _workspacesCol =>
      _firestore.collection(FirebaseConstants.colWorkspaces);

  @override
  Stream<List<Workspace>> watchWorkspaces(String userId) {
    return _workspacesCol
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Workspace.fromFirestore(doc)).toList());
  }

  @override
  Future<void> createWorkspace(Workspace workspace) async {
    await _workspacesCol.doc(workspace.workspaceId).set(workspace.toMap());
  }

  @override
  Future<void> updateWorkspaceName(String workspaceId, String newName) async {
    await _workspacesCol.doc(workspaceId).update({'name': newName});
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    await _workspacesCol.doc(workspaceId).delete();
  }
}
