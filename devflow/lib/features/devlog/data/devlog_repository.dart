import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../domain/flow_entry_model.dart';

abstract class DevLogRepository {
  Stream<List<FlowEntry>> watchFlowEntries(String workspaceId);
  Stream<FlowEntry?> watchLatestFlowEntry(String workspaceId);
  Future<void> createFlowEntry(FlowEntry entry);
  Future<void> deleteFlowEntry(String workspaceId, String entryId);
}

class FirestoreDevLogRepository implements DevLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreDevLogRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _flowEntriesCol(
          String workspaceId) =>
      _firestore
          .collection(FirebaseConstants.colWorkspaces)
          .doc(workspaceId)
          .collection(FirebaseConstants.subColFlowEntries);

  @override
  Stream<List<FlowEntry>> watchFlowEntries(String workspaceId) {
    return _flowEntriesCol(workspaceId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FlowEntry.fromFirestore(doc)).toList());
  }

  @override
  Stream<FlowEntry?> watchLatestFlowEntry(String workspaceId) {
    return _flowEntriesCol(workspaceId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return FlowEntry.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<void> createFlowEntry(FlowEntry entry) async {
    await _flowEntriesCol(entry.workspaceId).doc(entry.id).set(entry.toMap());
  }

  @override
  Future<void> deleteFlowEntry(String workspaceId, String entryId) async {
    await _flowEntriesCol(workspaceId).doc(entryId).delete();
  }
}
