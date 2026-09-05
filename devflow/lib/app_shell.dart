import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/responsive_layout.dart';
import 'features/workspace/presentation/workspace_providers.dart';
import 'features/workspace/presentation/workspace_sidebar.dart';
import 'features/devlog/presentation/devlog_view.dart';
import 'features/todos/presentation/todos_view.dart';
import 'features/files/presentation/files_tree_view.dart';
import 'features/code_viewer/presentation/code_viewer_view.dart';

/// State provider for the currently selected active navigation tab
/// 0: Files, 1: Code & Annotations, 2: Jurnal / DevLog, 3: TodoList
final activeTabProvider = StateProvider<int>((ref) => 2); // Default to Jurnal

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final selectedWorkspace = ref.watch(selectedWorkspaceProvider);
    final workspacesAsync = ref.watch(workspacesStreamProvider);

    final tabs = [
      const FilesTreeView(),
      const CodeViewerView(),
      const DevLogView(),
      const TodosView(),
    ];

    return ResponsiveLayout(
      // A. Desktop & Web Expanded (>= 1024px): Dual-Pane Split View
      expanded: (ctx) => Scaffold(
        body: Row(
          children: [
            // Left Workspace Sidebar (250px)
            const WorkspaceSidebar(),

            // Main Active Work Area
            Expanded(
              child: Column(
                children: [
                  // Top Navigation Bar for 4 instruments
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        bottom: BorderSide(
                            color: AppColors.surfaceBorder, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (selectedWorkspace != null) ...[
                          const Icon(Icons.folder,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            selectedWorkspace.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          const VerticalDivider(
                            color: AppColors.surfaceBorder,
                            indent: 12,
                            endIndent: 12,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _TabHeaderButton(
                          title: 'Files',
                          icon: Icons.folder_outlined,
                          isSelected: activeTab == 0,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 0,
                        ),
                        _TabHeaderButton(
                          title: 'Code & Annotations',
                          icon: Icons.code,
                          isSelected: activeTab == 1,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 1,
                        ),
                        _TabHeaderButton(
                          title: 'Jurnal / DevLog',
                          icon: Icons.alt_route,
                          isSelected: activeTab == 2,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 2,
                        ),
                        _TabHeaderButton(
                          title: 'TodoList',
                          icon: Icons.checklist,
                          isSelected: activeTab == 3,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 3,
                        ),
                      ],
                    ),
                  ),

                  // Active Tab Content
                  Expanded(child: tabs[activeTab]),
                ],
              ),
            ),
          ],
        ),
      ),

      // B. Tablet / Medium Window (600px - 1023px): Collapsible Drawer
      medium: (ctx) => Scaffold(
        appBar: AppBar(
          title: Text(selectedWorkspace?.name ?? 'DevFlow'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TabHeaderButton(
                    title: 'Files',
                    icon: Icons.folder_outlined,
                    isSelected: activeTab == 0,
                    onTap: () => ref.read(activeTabProvider.notifier).state = 0,
                  ),
                  _TabHeaderButton(
                    title: 'Code',
                    icon: Icons.code,
                    isSelected: activeTab == 1,
                    onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                  ),
                  _TabHeaderButton(
                    title: 'Jurnal',
                    icon: Icons.alt_route,
                    isSelected: activeTab == 2,
                    onTap: () => ref.read(activeTabProvider.notifier).state = 2,
                  ),
                  _TabHeaderButton(
                    title: 'Todos',
                    icon: Icons.checklist,
                    isSelected: activeTab == 3,
                    onTap: () => ref.read(activeTabProvider.notifier).state = 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: const Drawer(
          child: WorkspaceSidebar(isDrawer: true),
        ),
        body: tabs[activeTab],
      ),

      // C. Mobile Viewport (< 600px): Single Column Stack with Bottom Navigation Bar
      compact: (ctx) => Scaffold(
        appBar: AppBar(
          title: workspacesAsync.when(
            data: (workspaces) {
              if (workspaces.isEmpty) {
                return const Text('DevFlow (Belum ada Workspace)');
              }
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWorkspace?.workspaceId,
                  dropdownColor: AppColors.surfaceVariant,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppColors.primary),
                  items: workspaces.map((ws) {
                    return DropdownMenuItem(
                      value: ws.workspaceId,
                      child: Text(
                        ws.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final ws =
                          workspaces.firstWhere((w) => w.workspaceId == id);
                      ref.read(selectedWorkspaceProvider.notifier).state = ws;
                    }
                  },
                ),
              );
            },
            loading: () => const Text('Memuat workspaces...'),
            error: (err, stack) => const Text('DevFlow'),
          ),
        ),
        body: tabs[activeTab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: activeTab,
          onDestinationSelected: (idx) {
            ref.read(activeTabProvider.notifier).state = idx;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.code_outlined),
              selectedIcon: Icon(Icons.code),
              label: 'Code',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route),
              selectedIcon: Icon(Icons.alt_route),
              label: 'Jurnal',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Todos',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabHeaderButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabHeaderButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
