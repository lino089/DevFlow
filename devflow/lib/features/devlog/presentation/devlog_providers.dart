import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../data/devlog_repository.dart';
import '../domain/flow_entry_model.dart';

/// Provider for DevLogRepository
final devlogRepositoryProvider = Provider<DevLogRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreDevLogRepository(firestore);
});

/// Stream of all flow entries for the currently selected workspace
final flowEntriesStreamProvider = StreamProvider<List<FlowEntry>>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  if (workspace == null) return Stream.value([]);
  final repo = ref.watch(devlogRepositoryProvider);
  return repo.watchFlowEntries(workspace.workspaceId);
});

/// Stream of the most recent flow entry ("Last Dikerjakan")
final latestFlowEntryProvider = StreamProvider<FlowEntry?>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  if (workspace == null) return Stream.value(null);
  final repo = ref.watch(devlogRepositoryProvider);
  return repo.watchLatestFlowEntry(workspace.workspaceId);
});

/// Search query state for instant filter
final devlogSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered flow entries based on search query (FR-17)
final filteredFlowEntriesProvider = Provider<AsyncValue<List<FlowEntry>>>((ref) {
  final entriesAsync = ref.watch(flowEntriesStreamProvider);
  final query = ref.watch(devlogSearchQueryProvider).trim().toLowerCase();

  return entriesAsync.whenData((entries) {
    if (query.isEmpty) return entries;
    return entries.where((entry) {
      final matchesFeature = entry.featureName.toLowerCase().contains(query);
      final matchesSteps = entry.flowSteps.any((step) => step.toLowerCase().contains(query));
      final matchesFiles = entry.keyFiles.any((file) => file.toLowerCase().contains(query));
      final matchesTags = entry.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesNextTodo = entry.nextTodo.toLowerCase().contains(query);
      return matchesFeature || matchesSteps || matchesFiles || matchesTags || matchesNextTodo;
    }).toList();
  });
});
