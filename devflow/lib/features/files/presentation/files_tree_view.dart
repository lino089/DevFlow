import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../app_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../code_viewer/presentation/annotation_providers.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../domain/file_node.dart';
import 'files_providers.dart';

class FilesTreeView extends ConsumerWidget {
  const FilesTreeView({super.key});

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.dart':
        return Icons.flutter_dash;
      case '.js':
      case '.ts':
      case '.jsx':
      case '.tsx':
        return Icons.javascript;
      case '.json':
      case '.yaml':
      case '.yml':
        return Icons.data_object;
      case '.md':
      case '.txt':
        return Icons.article_outlined;
      case '.html':
      case '.xml':
        return Icons.code;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.svg':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.dart':
        return AppColors.primary;
      case '.js':
      case '.ts':
        return AppColors.warning;
      case '.json':
      case '.yaml':
      case '.yml':
        return AppColors.accent;
      case '.md':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildNodeItem(
      BuildContext context, WidgetRef ref, FileNode node, int depth) {
    final selectedFile = ref.watch(selectedFileNodeProvider);
    final isSelected = selectedFile?.fullPath == node.fullPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (node.isDirectory) {
              ref.read(directoryTreeProvider.notifier).toggleFolder(node);
            } else {
              ref.read(selectedFileNodeProvider.notifier).state = node;
              ref.read(activeFileRelativePathProvider.notifier).state =
                  node.relativePath;
              // Beralih ke tab Code & Annotations (FR-05)
              ref.read(activeTabProvider.notifier).state = 1;
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 12.0 + (depth * 18.0),
              right: 12.0,
              top: 6.0,
              bottom: 6.0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceVariant
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                if (node.isDirectory)
                  Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: AppColors.textSecondary,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Icon(
                  node.isDirectory
                      ? (node.isExpanded
                          ? Icons.folder_open
                          : Icons.folder)
                      : _getFileIcon(node.name),
                  size: 16,
                  color: node.isDirectory
                      ? AppColors.primary
                      : _getFileColor(node.name),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : (node.isDirectory ? FontWeight.w600 : FontWeight.normal),
                      color: isSelected
                          ? AppColors.textPrimary
                          : (node.isDirectory
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children
              .map((child) => _buildNodeItem(context, ref, child, depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(selectedWorkspaceProvider);

    if (workspace == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Pilih atau Connect Workspace di panel kiri\nuntuk melihat struktur berkas',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final treeAsync = ref.watch(directoryTreeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Toolbar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'EXPLORER: ${workspace.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Muat Ulang Berkas',
                  onPressed: () {
                    ref.read(directoryTreeProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),

          // Tree List
          Expanded(
            child: treeAsync.when(
              data: (nodes) {
                if (nodes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Direktori kosong atau tidak ada berkas yang dapat dibaca.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    return _buildNodeItem(context, ref, nodes[index], 0);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Gagal memuat direktori: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
