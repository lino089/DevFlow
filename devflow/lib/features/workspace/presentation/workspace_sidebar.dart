import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/workspace_model.dart';
import 'workspace_providers.dart';

class WorkspaceSidebar extends ConsumerWidget {
  final bool isDrawer;

  const WorkspaceSidebar({
    super.key,
    this.isDrawer = false,
  });

  Future<void> _pickAndAddWorkspace(BuildContext context, WidgetRef ref) async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Project Directory to Connect',
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menghubungkan sesi pengguna Firebase...')),
            );
          }
          return;
        }

        final folderName = selectedDirectory.split(RegExp(r'[/\\]')).last;
        final newWorkspace = Workspace(
          workspaceId: const Uuid().v4(),
          userId: userId,
          name: folderName.isEmpty ? 'Project' : folderName,
          localPath: selectedDirectory,
          createdAt: DateTime.now(),
        );

        await ref.read(workspaceRepositoryProvider).createWorkspace(newWorkspace);
        ref.read(selectedWorkspaceProvider.notifier).state = newWorkspace;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace "$folderName" berhasil ditautkan!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih folder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Workspace workspace) {
    final controller = TextEditingController(text: workspace.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Ganti Nama Alias Workspace'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Workspace',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref
                    .read(workspaceRepositoryProvider)
                    .updateWorkspaceName(workspace.workspaceId, newName);
                if (ref.read(selectedWorkspaceProvider)?.workspaceId ==
                    workspace.workspaceId) {
                  ref.read(selectedWorkspaceProvider.notifier).state =
                      workspace.copyWith(name: newName);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(
      BuildContext context, WidgetRef ref, Workspace workspace) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Putuskan Tautan Workspace?'),
        content: Text(
          'Workspace "${workspace.name}" akan dilepas dari DevFlow.\n\n'
          'Perhatian: Berkas asli di komputer Anda sama sekali TIDAK akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(workspaceRepositoryProvider)
                  .deleteWorkspace(workspace.workspaceId);
              if (ref.read(selectedWorkspaceProvider)?.workspaceId ==
                  workspace.workspaceId) {
                ref.read(selectedWorkspaceProvider.notifier).state = null;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspacesStreamProvider);
    final selectedWorkspace = ref.watch(selectedWorkspaceProvider);

    return Container(
      width: isDrawer ? null : 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'DevFlow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                  tooltip: 'Connect Folder Baru',
                  color: AppColors.primary,
                  onPressed: () => _pickAndAddWorkspace(context, ref),
                ),
              ],
            ),
          ),

          // Connect Folder Button Banner
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: AppColors.surfaceBorder),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => _pickAndAddWorkspace(context, ref),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text(
                'Connect Folder',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'WORKSPACES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Workspace List
          Expanded(
            child: workspacesAsync.when(
              data: (workspaces) {
                if (workspaces.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada folder yang ditautkan.\nKlik [+ Connect Folder] di atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                // Otomatis pilih workspace pertama jika belum ada yang terpilih
                if (selectedWorkspace == null && workspaces.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedWorkspaceProvider.notifier).state =
                        workspaces.first;
                  });
                }

                return ListView.builder(
                  itemCount: workspaces.length,
                  itemBuilder: (context, index) {
                    final ws = workspaces[index];
                    final isSelected =
                        selectedWorkspace?.workspaceId == ws.workspaceId;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceVariant
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        leading: Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          ws.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          ws.localPath,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              size: 16, color: AppColors.textSecondary),
                          color: AppColors.surface,
                          onSelected: (action) {
                            if (action == 'rename') {
                              _showRenameDialog(context, ref, ws);
                            } else if (action == 'disconnect') {
                              _showDisconnectDialog(context, ref, ws);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Ganti Nama Alias'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'disconnect',
                              child: Row(
                                children: [
                                  Icon(Icons.link_off,
                                      size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Putuskan Tautan',
                                      style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(selectedWorkspaceProvider.notifier).state =
                              ws;
                          if (isDrawer) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat workspace: $err',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ),
          ),

          // User profile / Logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ref.watch(authStateChangesProvider).value?.email ?? 'User',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  color: AppColors.error,
                  tooltip: 'Keluar',
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
