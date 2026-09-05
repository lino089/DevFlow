import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../data/annotation_repository.dart';
import '../domain/code_annotation_model.dart';

/// Provider for AnnotationRepository
final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreAnnotationRepository(firestore);
});

/// Relative path of currently viewed code file
final activeFileRelativePathProvider = StateProvider<String?>((ref) => null);

/// Stream of annotations for the currently active file in the active workspace
final activeFileAnnotationsStreamProvider =
    StreamProvider<List<CodeAnnotation>>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  final filePath = ref.watch(activeFileRelativePathProvider);

  if (workspace == null || filePath == null || filePath.isEmpty) {
    return Stream.value([]);
  }

  final repo = ref.watch(annotationRepositoryProvider);
  return repo.watchAnnotationsForFile(workspace.workspaceId, filePath);
});

/// Map of line number to annotations for the active file
final activeFileAnnotationsByLineProvider =
    Provider<AsyncValue<Map<int, List<CodeAnnotation>>>>((ref) {
  final annotationsAsync = ref.watch(activeFileAnnotationsStreamProvider);

  return annotationsAsync.whenData((annotations) {
    final map = <int, List<CodeAnnotation>>{};
    for (final a in annotations) {
      map.putIfAbsent(a.lineNumber, () => []).add(a);
    }
    return map;
  });
});
