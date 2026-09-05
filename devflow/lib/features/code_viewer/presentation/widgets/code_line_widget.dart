import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/code_annotation_model.dart';

class CodeLineWidget extends StatefulWidget {
  final int lineNumber;
  final List<InlineSpan> spans;
  final double gutterWidth;
  final List<CodeAnnotation> annotations;
  final void Function(String note)? onSaveAnnotation;
  final void Function(CodeAnnotation annotation)? onDeleteAnnotation;

  const CodeLineWidget({
    super.key,
    required this.lineNumber,
    required this.spans,
    required this.gutterWidth,
    this.annotations = const [],
    this.onSaveAnnotation,
    this.onDeleteAnnotation,
  });

  @override
  State<CodeLineWidget> createState() => _CodeLineWidgetState();
}

class _CodeLineWidgetState extends State<CodeLineWidget> {
  bool _isHovered = false;
  bool _isAddingAnnotation = false;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _saveAnnotation() {
    final note = _noteController.text.trim();
    if (note.isNotEmpty) {
      widget.onSaveAnnotation?.call(note);
    }
    setState(() {
      _isAddingAnnotation = false;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAnnotations = widget.annotations.isNotEmpty;
    final showInlineForm = _isAddingAnnotation;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered || showInlineForm
              ? AppColors.surfaceVariant.withValues(alpha: 0.5)
              : (hasAnnotations
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent),
          border: hasAnnotations || showInlineForm
              ? const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Number Gutter
                Container(
                  width: widget.gutterWidth,
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Hover [+] button (FR-08)
                      if (_isHovered && !showInlineForm)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAddingAnnotation = true;
                            });
                            Future.delayed(const Duration(milliseconds: 50), () {
                              _noteFocusNode.requestFocus();
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 14),
                      const SizedBox(width: 4),
                      // Line Number Text (FR-07)
                      Text(
                        '${widget.lineNumber}',
                        style: Theme.of(context).codeStyle.copyWith(
                          fontSize: 12,
                          color: _isHovered || showInlineForm
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Code Text (Strict Read-Only, FR-06)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget.spans.isEmpty
                        ? const Text(' ', style: TextStyle(fontSize: 13))
                        : SelectableText.rich(
                            TextSpan(
                              children: widget.spans,
                              style: Theme.of(context).codeStyle.copyWith(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // Inline Annotations Card (FR-11)
            if (hasAnnotations)
              Padding(
                padding: EdgeInsets.only(
                    left: widget.gutterWidth + 12, top: 4, bottom: 6, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.annotations.map((ann) {
                        return Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ann.note,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.onDeleteAnnotation != null)
                                InkWell(
                                  onTap: () => widget.onDeleteAnnotation!(ann),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
            // Inline Form to Add New Annotation (FR-09)
            if (showInlineForm)
              Padding(
                padding: EdgeInsets.only(
                    left: widget.gutterWidth + 12, top: 4, bottom: 8, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _noteController,
                            focusNode: _noteFocusNode,
                            maxLines: null,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Tambahkan alasan / penjelasan logika di baris ini...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _saveAnnotation(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isAddingAnnotation = false;
                                    _noteController.clear();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Batal', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _saveAnnotation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
