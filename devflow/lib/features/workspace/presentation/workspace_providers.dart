import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../data/workspace_repository.dart';
import '../domain/workspace_model.dart';

/// Provider for WorkspaceRepository
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreWorkspaceRepository(firestore);
});

/// Provider for currently signed-in user's UID
final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

/// Stream of workspaces for current user
final workspacesStreamProvider = StreamProvider<List<Workspace>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchWorkspaces(userId);
});

/// Currently selected workspace state
final selectedWorkspaceProvider = StateProvider<Workspace?>((ref) {
  return null;
});
