import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../domain/flow_entry_model.dart';
import 'devlog_providers.dart';
import 'widgets/add_flow_entry_dialog.dart';
import 'widgets/last_worked_card.dart';

class DevLogView extends ConsumerWidget {
  const DevLogView({super.key});

  void _openAddDialog(BuildContext context, String workspaceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddFlowEntryDialog(workspaceId: workspaceId),
    );
  }

  void _openEditDialog(BuildContext context, FlowEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddFlowEntryDialog(
        workspaceId: entry.workspaceId,
        initialEntry: entry,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FlowEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Catatan Alur Ini?'),
        content: Text('Alur "${entry.featureName}" akan dihapus dari Firestore.'),
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
                  .read(devlogRepositoryProvider)
                  .deleteFlowEntry(entry.workspaceId, entry.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
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
              'Pilih atau Connect Workspace di panel kiri\nuntuk melihat Jurnal Alur Logika (DevLog)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final latestEntryAsync = ref.watch(latestFlowEntryProvider);
    final filteredEntriesAsync = ref.watch(filteredFlowEntriesProvider);
    final searchQuery = ref.watch(devlogSearchQueryProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Toolbar: Search + Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Search Input (FR-17)
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Cari alur logika, nama fitur, berkas, atau tags...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => ref
                                  .read(devlogSearchQueryProvider.notifier)
                                  .state = '',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      ref.read(devlogSearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Button [+ Catat Alur Baru]
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _openAddDialog(context, workspace.workspaceId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Catat Alur Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: filteredEntriesAsync.when(
              data: (entries) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Kartu "Last Dikerjakan" (hanya muncul jika tidak sedang search)
                    if (searchQuery.isEmpty)
                      latestEntryAsync.when(
                        data: (latest) {
                          if (latest == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: LastWorkedCard(
                              entry: latest,
                              onEdit: () => _openEditDialog(context, latest),
                              onDelete: () => _confirmDelete(context, ref, latest),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),

                    // Section Title
                    Row(
                      children: [
                        Text(
                          searchQuery.isEmpty
                              ? 'RIWAYAT ALUR LOGIKA'
                              : 'HASIL PENCARIAN (${entries.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (entries.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.history_edu_outlined,
                                  size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 10),
                              Text(
                                searchQuery.isEmpty
                                    ? 'Belum ada alur logika yang dicatat.\nKlik [+ Catat Alur Baru] untuk mulai mendokumentasikan mikro-alur.'
                                    : 'Tidak ditemukan alur yang sesuai dengan "$searchQuery".',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Timeline List of Entries
                      ...entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.surfaceBorder, width: 1),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                child: const Icon(Icons.alt_route,
                                    size: 16, color: AppColors.primary),
                              ),
                              title: Text(
                                entry.featureName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.flowSteps.length} langkah • ${dateFormat.format(entry.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (entry.stateNotes.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Catatan: ${entry.stateNotes}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.textSecondary),
                                    tooltip: 'Edit Alur',
                                    splashRadius: 18,
                                    onPressed: () =>
                                        _openEditDialog(context, entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.textMuted),
                                    tooltip: 'Hapus Alur',
                                    splashRadius: 18,
                                    onPressed: () =>
                                        _confirmDelete(context, ref, entry),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(
                                          color: AppColors.surfaceBorder),
                                      const SizedBox(height: 8),

                                      // Ordered Steps
                                      const Text(
                                        'Langkah-Langkah Eksekusi:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...entry.flowSteps.asMap().entries.map((s) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${s.key + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  s.value,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                      // Key Files
                                      if (entry.keyFiles.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Key Files:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          children: entry.keyFiles.map((f) {
                                            return Chip(
                                              label: Text(f,
                                                  style: Theme.of(context).codeStyle.copyWith(fontSize: 11)),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              backgroundColor:
                                                  AppColors.surfaceVariant,
                                            );
                                          }).toList(),
                                        ),
                                      ],

                                      // State Notes
                                      if (entry.stateNotes.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Catatan State:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          entry.stateNotes,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],

                                      // Next Todo
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.warning.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
                                              color: AppColors.warning,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Next Todo: ${entry.nextTodo}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Gagal memuat devlog: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
