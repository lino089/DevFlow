import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../domain/file_node.dart';

abstract class FileRepository {
  Future<List<FileNode>> listDirectory(String rootPath, {String? subPath});
  Future<String> readFileContent(String fullPath);
  Stream<io.FileSystemEvent>? watchDirectory(String rootPath);
  Stream<io.FileSystemEvent>? watchFile(String fullPath);
}

class LocalFileRepository implements FileRepository {
  // Folder yang diabaikan agar pohon berkas tetap bersih dan berkinerja tinggi
  static const Set<String> _ignoredFolders = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    'node_modules',
    '.gradle',
    'ios/Pods',
  };

  @override
  Stream<io.FileSystemEvent>? watchDirectory(String rootPath) {
    if (kIsWeb) return null;
    try {
      final dir = io.Directory(rootPath);
      if (!dir.existsSync()) return null;
      return dir.watch(recursive: true);
    } catch (e) {
      debugPrint('Error watching directory $rootPath: $e');
      return null;
    }
  }

  @override
  Stream<io.FileSystemEvent>? watchFile(String fullPath) {
    if (kIsWeb) return null;
    try {
      final file = io.File(fullPath);
      if (!file.existsSync()) return null;
      return file.watch(events: io.FileSystemEvent.modify);
    } catch (e) {
      debugPrint('Error watching file $fullPath: $e');
      return null;
    }
  }

  @override
  Future<List<FileNode>> listDirectory(String rootPath, {String? subPath}) async {
    if (kIsWeb) {
      return _getWebDemoNodes(rootPath);
    }

    final targetPath = subPath != null && subPath.isNotEmpty
        ? p.join(rootPath, subPath)
        : rootPath;

    final dir = io.Directory(targetPath);
    if (!dir.existsSync()) {
      return [];
    }

    try {
      final entities = dir.listSync(followLinks: false);
      final List<FileNode> folders = [];
      final List<FileNode> files = [];

      for (final entity in entities) {
        final baseName = p.basename(entity.path);

        // Abaikan file dan folder tersembunyi / build cache
        if (baseName.startsWith('.') && baseName != '.env') continue;
        if (_ignoredFolders.contains(baseName)) continue;

        final isDir = entity is io.Directory;
        final relPath = p.relative(entity.path, from: rootPath).replaceAll(r'\', '/');

        if (isDir) {
          folders.add(FileNode(
            name: baseName,
            fullPath: entity.path,
            relativePath: relPath,
            isDirectory: true,
            isExpanded: false,
          ));
        } else if (entity is io.File) {
          int? size;
          try {
            size = entity.lengthSync();
          } catch (_) {}

          files.add(FileNode(
            name: baseName,
            fullPath: entity.path,
            relativePath: relPath,
            isDirectory: false,
            sizeBytes: size,
          ));
        }
      }

      // Urutkan folder terlebih dahulu (A-Z), lalu berkas (A-Z)
      folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return [...folders, ...files];
    } catch (e) {
      debugPrint('Error listing directory $targetPath: $e');
      return [];
    }
  }

  /// Membaca berkas sumber secara ketat 100% Read-Only (Zero-Write Guarantee)
  @override
  Future<String> readFileContent(String fullPath) async {
    if (kIsWeb) {
      return '// [Web Demo Mode]\n// Konten simulasi untuk berkas: $fullPath\n'
          'void main() {\n  print("Halo dari DevFlow Web Demo!");\n}';
    }

    final file = io.File(fullPath);
    if (!file.existsSync()) {
      throw Exception('Berkas tidak ditemukan: $fullPath');
    }

    // Mekanisme retry hingga 3 kali jika berkas sedang dikunci sementara oleh editor (VS Code dll)
    for (var i = 0; i < 3; i++) {
      try {
        return await file.readAsString();
      } catch (e) {
        if (i == 2) {
          try {
            final bytes = await file.readAsBytes();
            return String.fromCharCodes(bytes);
          } catch (_) {
            rethrow;
          }
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    throw Exception('Gagal membaca berkas: $fullPath');
  }

  List<FileNode> _getWebDemoNodes(String rootPath) {
    return [
      const FileNode(
        name: 'lib',
        fullPath: 'demo/lib',
        relativePath: 'lib',
        isDirectory: true,
        isExpanded: true,
        children: [
          FileNode(
            name: 'main.dart',
            fullPath: 'demo/lib/main.dart',
            relativePath: 'lib/main.dart',
            isDirectory: false,
          ),
          FileNode(
            name: 'app.dart',
            fullPath: 'demo/lib/app.dart',
            relativePath: 'lib/app.dart',
            isDirectory: false,
          ),
        ],
      ),
      const FileNode(
        name: 'pubspec.yaml',
        fullPath: 'demo/pubspec.yaml',
        relativePath: 'pubspec.yaml',
        isDirectory: false,
      ),
      const FileNode(
        name: 'README.md',
        fullPath: 'demo/README.md',
        relativePath: 'README.md',
        isDirectory: false,
      ),
    ];
  }
}
