import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../domain/project_todo_model.dart';
import 'todo_providers.dart';

class TodosView extends ConsumerStatefulWidget {
  const TodosView({super.key});

  @override
  ConsumerState<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends ConsumerState<TodosView> {
  final _quickAddController = TextEditingController();

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _quickAddTodo(String workspaceId) async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    final newTodo = ProjectTodo(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      title: title,
      priority: TodoPriority.medium,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    _quickAddController.clear();
    await ref.read(todoRepositoryProvider).createTodo(newTodo);
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Pilih atau Connect Workspace di panel kiri\nuntuk mengelola Project Todo List',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final todosAsync = ref.watch(filteredTodosProvider);
    final currentFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Toolbar: Quick Add Input (FR-19)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickAddController,
                        decoration: InputDecoration(
                          hintText:
                              'Quick Add: Ketik tugas baru lalu tekan Enter...',
                          prefixIcon: const Icon(Icons.add_task, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.keyboard_return, size: 18),
                            tooltip: 'Tekan Enter untuk menyimpan',
                            onPressed: () =>
                                _quickAddTodo(workspace.workspaceId),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.surfaceBorder),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          isDense: true,
                        ),
                        onSubmitted: (_) =>
                            _quickAddTodo(workspace.workspaceId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Buttons (FR-21: All, Active, Completed)
                Row(
                  children: [
                    const Text(
                      'Filter: ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Semua',
                      isSelected: currentFilter == TodoFilter.all,
                      onTap: () => ref.read(todoFilterProvider.notifier).state =
                          TodoFilter.all,
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Pending / Aktif',
                      isSelected: currentFilter == TodoFilter.active,
                      onTap: () => ref.read(todoFilterProvider.notifier).state =
                          TodoFilter.active,
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Selesai',
                      isSelected: currentFilter == TodoFilter.completed,
                      onTap: () => ref.read(todoFilterProvider.notifier).state =
                          TodoFilter.completed,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Todos
          Expanded(
            child: todosAsync.when(
              data: (todos) {
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checklist,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          currentFilter == TodoFilter.all
                              ? 'Belum ada tugas di workspace ini.\nKetik di kolom Quick Add di atas.'
                              : 'Tidak ada tugas yang sesuai dengan filter.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        leading: Checkbox(
                          value: todo.isCompleted,
                          activeColor: AppColors.success,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(todoRepositoryProvider)
                                  .toggleTodoStatus(
                                      todo.workspaceId, todo.id, val);
                            }
                          },
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isCompleted
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Priority Dropdown
                            DropdownButton<TodoPriority>(
                              value: todo.priority,
                              underline: const SizedBox.shrink(),
                              dropdownColor: AppColors.surfaceVariant,
                              icon: const Icon(Icons.arrow_drop_down,
                                  size: 16, color: AppColors.textSecondary),
                              onChanged: (newPriority) {
                                if (newPriority != null) {
                                  ref
                                      .read(todoRepositoryProvider)
                                      .updateTodoPriority(todo.workspaceId,
                                          todo.id, newPriority);
                                }
                              },
                              items: TodoPriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(p)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getPriorityColor(p),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(width: 6),

                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.textMuted),
                              tooltip: 'Hapus Tugas',
                              onPressed: () {
                                ref
                                    .read(todoRepositoryProvider)
                                    .deleteTodo(todo.workspaceId, todo.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Gagal memuat todos: $err',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
