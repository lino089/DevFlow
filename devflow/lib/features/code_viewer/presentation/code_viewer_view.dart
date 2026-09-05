import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../files/presentation/files_providers.dart';
import '../../workspace/presentation/workspace_providers.dart';
import '../domain/code_annotation_model.dart';
import 'annotation_providers.dart';
import 'widgets/code_highlighter_helper.dart';
import 'widgets/code_line_widget.dart';

class CodeViewerView extends ConsumerStatefulWidget {
  const CodeViewerView({super.key});

  @override
  ConsumerState<CodeViewerView> createState() => _CodeViewerViewState();
}

class _CodeViewerViewState extends ConsumerState<CodeViewerView> {
// _openAddAnnotationDialog removed

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _deleteAnnotation(CodeAnnotation annotation) async {
    final workspace = ref.read(selectedWorkspaceProvider);
    if (workspace == null) return;
    await ref
        .read(annotationRepositoryProvider)
        .deleteAnnotation(workspace.workspaceId, annotation.id);
  }

  @override
  Widget build(BuildContext context) {
    final selectedFile = ref.watch(selectedFileNodeProvider);
    final fileContentAsync = ref.watch(selectedFileContentProvider);
    final annotationsMapAsync = ref.watch(activeFileAnnotationsByLineProvider);

    if (selectedFile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum ada berkas yang dibuka.\nPilih berkas dari tab Files untuk melihat kode sumber.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final language = CodeHighlighterHelper.detectLanguage(selectedFile.fullPath);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  selectedFile.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '(${selectedFile.relativePath})',
                  style: Theme.of(context).codeStyle.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Muat ulang berkas & anotasi (Refresh)',
                  color: AppColors.textSecondary,
                  hoverColor: AppColors.surfaceVariant,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    ref.invalidate(selectedFileContentProvider);
                    ref.invalidate(activeFileAnnotationsByLineProvider);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berkas berhasil dimuat ulang'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        width: 260,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (language != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 11, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        '100% READ-ONLY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Code Body (Virtualized)
          Expanded(
            child: fileContentAsync.when(
              data: (content) {
                final lineSpans = CodeHighlighterHelper.parseSourceToLineSpans(
                  content,
                  language: language,
                );
                final totalLines = lineSpans.length;
                final gutterDigits = totalLines.toString().length;
                final gutterWidth = (gutterDigits * 8.0 + 32.0).clamp(42.0, 75.0);

                final annotationsByLine = annotationsMapAsync.value ?? {};
                final rawLines = content.replaceAll('\r\n', '\n').split('\n');

                return Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notif) => notif.depth == 0,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1800, // Memberikan ruang lebar horizontal untuk baris kode panjang
                        child: ListView.builder(
                          controller: _verticalController,
                          itemCount: totalLines,
                        itemExtent: null, // Dinamis karena bisa memiliki inline annotation cards
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final lineNum = index + 1;
                          final spans = lineSpans[index];
                          final annotations = annotationsByLine[lineNum] ?? [];
                          final rawSnippet =
                              index < rawLines.length ? rawLines[index].trim() : '';

                          return CodeLineWidget(
                            lineNumber: lineNum,
                            spans: spans,
                            gutterWidth: gutterWidth,
                            annotations: annotations,
                            onSaveAnnotation: (note) async {
                              final workspace = ref.read(selectedWorkspaceProvider);
                              final relativePath = ref.read(activeFileRelativePathProvider);
                              if (workspace == null || relativePath == null) return;

                              final newAnnotation = CodeAnnotation(
                                id: const Uuid().v4(),
                                workspaceId: workspace.workspaceId,
                                fileRelativePath: relativePath,
                                lineNumber: lineNum,
                                codeSnippet: rawSnippet,
                                note: note,
                                createdAt: DateTime.now(),
                              );

                              await ref
                                  .read(annotationRepositoryProvider)
                                  .createAnnotation(newAnnotation);
                            },
                            onDeleteAnnotation: _deleteAnnotation,
                          );
                        },
                      ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal membaca berkas: $err',
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
