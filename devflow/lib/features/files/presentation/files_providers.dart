import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../data/file_repository.dart';
import '../domain/file_node.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return LocalFileRepository();
});

/// Currently selected file node in the explorer
final selectedFileNodeProvider = StateProvider<FileNode?>((ref) => null);

/// Loads and streams the content of the currently selected file in real-time (100% Read-Only)
final selectedFileContentProvider = StreamProvider.autoDispose<String>((ref) async* {
  final selectedFile = ref.watch(selectedFileNodeProvider);
  if (selectedFile == null || selectedFile.isDirectory) {
    yield '';
    return;
  }

  final repo = ref.watch(fileRepositoryProvider);

  // Yield konten awal berkas saat pertama kali dipilih
  final initialContent = await repo.readFileContent(selectedFile.fullPath);
  yield initialContent;

  if (kIsWeb) return;

  // Pasang watcher pada berkas fisik (mendengarkan event modifikasi seperti saat di-save di VS Code)
  final fileStream = repo.watchFile(selectedFile.fullPath);
  if (fileStream == null) return;

  // Dengarkan perubahan dan yield konten terbaru
  await for (final _ in fileStream) {
    // Beri jeda 120ms agar proses penulisan oleh editor luar (seperti VS Code) selesai sepenuhnya
    await Future.delayed(const Duration(milliseconds: 120));
    try {
      final updatedContent = await repo.readFileContent(selectedFile.fullPath);
      yield updatedContent;
    } catch (_) {
      // Abaikan error sementara saat file masih di-lock oleh editor
    }
  }
});

/// StateNotifier for managing the expandable directory tree with real-time file system watching
class DirectoryTreeNotifier extends StateNotifier<AsyncValue<List<FileNode>>> {
  final FileRepository _repo;
  final String? _rootPath;

  StreamSubscription? _watcherSubscription;
  Timer? _debounceTimer;

  static const Set<String> _ignoredNames = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    'node_modules',
    '.gradle',
    'Pods',
  };

  DirectoryTreeNotifier(this._repo, this._rootPath)
      : super(const AsyncValue.loading()) {
    _loadRoot();
    _startWatching();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _watcherSubscription?.cancel();
    super.dispose();
  }

  void _startWatching() {
    final root = _rootPath;
    if (root == null || root.isEmpty || kIsWeb) return;

    final stream = _repo.watchDirectory(root);
    if (stream == null) return;

    _watcherSubscription = stream.listen((event) {
      if (_isIgnoredPath(event.path)) return;

      // Debounce pembaruan tree (300ms) agar jika ada banyak file dibuat sekaligus tidak spam refresh
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _refreshPreservingExpansion();
      });
    });
  }

  bool _isIgnoredPath(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final segments = normalized.split('/');
    for (final segment in segments) {
      if (_ignoredNames.contains(segment)) return true;
      if (segment.startsWith('.') && segment != '.env') return true;
    }
    return false;
  }

  Future<void> _loadRoot() async {
    final root = _rootPath;
    if (root == null || root.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final nodes = await _repo.listDirectory(root);
      state = AsyncValue.data(nodes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Set<String> _collectExpandedPaths(List<FileNode> nodes) {
    final expanded = <String>{};
    for (final node in nodes) {
      if (node.isDirectory && node.isExpanded) {
        expanded.add(node.relativePath);
        if (node.children.isNotEmpty) {
          expanded.addAll(_collectExpandedPaths(node.children));
        }
      }
    }
    return expanded;
  }

  Future<List<FileNode>> _rebuildTreePreservingExpansion(
      String root, Set<String> expandedPaths, {String? subPath}) async {
    final nodes = await _repo.listDirectory(root, subPath: subPath);
    final List<FileNode> result = [];

    for (final node in nodes) {
      if (node.isDirectory && expandedPaths.contains(node.relativePath)) {
        final children = await _rebuildTreePreservingExpansion(
          root,
          expandedPaths,
          subPath: node.relativePath,
        );
        result.add(node.copyWith(isExpanded: true, children: children));
      } else {
        result.add(node);
      }
    }

    return result;
  }

  Future<void> _refreshPreservingExpansion() async {
    final root = _rootPath;
    if (root == null || root.isEmpty) return;

    final currentNodes = state.value ?? [];
    final expandedPaths = _collectExpandedPaths(currentNodes);

    try {
      final newNodes = await _rebuildTreePreservingExpansion(root, expandedPaths);
      state = AsyncValue.data(newNodes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFolder(FileNode targetNode) async {
    final currentList = state.value;
    if (currentList == null || !targetNode.isDirectory) return;

    List<FileNode> updateRecursive(List<FileNode> list) {
      return list.map((node) {
        if (node.fullPath == targetNode.fullPath) {
          final isExpanded = !node.isExpanded;
          return node.copyWith(isExpanded: isExpanded);
        }
        if (node.isDirectory && node.children.isNotEmpty) {
          return node.copyWith(children: updateRecursive(node.children));
        }
        return node;
      }).toList();
    }

    // Jika belum memiliki children dan akan dibuka, muat children dari disk
    if (!targetNode.isExpanded && targetNode.children.isEmpty) {
      final root = _rootPath;
      if (root == null) return;
      try {
        final children = await _repo.listDirectory(root,
            subPath: targetNode.relativePath);

        List<FileNode> attachChildren(List<FileNode> list) {
          return list.map((node) {
            if (node.fullPath == targetNode.fullPath) {
              return node.copyWith(isExpanded: true, children: children);
            }
            if (node.isDirectory && node.children.isNotEmpty) {
              return node.copyWith(children: attachChildren(node.children));
            }
            return node;
          }).toList();
        }

        state = AsyncValue.data(attachChildren(currentList));
        return;
      } catch (e, st) {
        state = AsyncValue.error(e, st);
        return;
      }
    }

    state = AsyncValue.data(updateRecursive(currentList));
  }

  void refresh() {
    _refreshPreservingExpansion();
  }
}

final directoryTreeProvider = StateNotifierProvider.autoDispose<
    DirectoryTreeNotifier, AsyncValue<List<FileNode>>>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  final repo = ref.watch(fileRepositoryProvider);
  return DirectoryTreeNotifier(repo, workspace?.localPath);
});
