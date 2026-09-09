import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/flow_entry_model.dart';
import '../devlog_providers.dart';

class AddFlowEntryDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final FlowEntry? initialEntry;

  const AddFlowEntryDialog({
    super.key,
    required this.workspaceId,
    this.initialEntry,
  });

  bool get isEditing => initialEntry != null;

  @override
  ConsumerState<AddFlowEntryDialog> createState() => _AddFlowEntryDialogState();
}

class _AddFlowEntryDialogState extends ConsumerState<AddFlowEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _featureNameController = TextEditingController();
  final _stateNotesController = TextEditingController();
  final _nextTodoController = TextEditingController();
  final _keyFilesController = TextEditingController();
  final _tagsController = TextEditingController();

  // Dynamic step controllers
  final List<TextEditingController> _stepControllers = [];
  final List<FocusNode> _stepFocusNodes = [];

  bool _isSubmitting = false;
  bool _isOptionsExpanded = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    if (entry != null) {
      _featureNameController.text = entry.featureName;
      _stateNotesController.text = entry.stateNotes;
      _nextTodoController.text = entry.nextTodo;
      _keyFilesController.text = entry.keyFiles.join(', ');
      _tagsController.text = entry.tags.join(', ');
      if (entry.keyFiles.isNotEmpty ||
          entry.stateNotes.isNotEmpty ||
          entry.tags.isNotEmpty) {
        _isOptionsExpanded = true;
      }
      if (entry.flowSteps.isNotEmpty) {
        for (final s in entry.flowSteps) {
          _stepControllers.add(TextEditingController(text: s));
          _stepFocusNodes.add(FocusNode());
        }
      } else {
        _stepControllers.add(TextEditingController());
        _stepFocusNodes.add(FocusNode());
      }
    } else {
      // Inisialisasi minimal 1 langkah kosong
      _stepControllers.add(TextEditingController());
      _stepFocusNodes.add(FocusNode());
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
      final fn = FocusNode();
      _stepFocusNodes.add(fn);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) fn.requestFocus();
      });
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepFocusNodes[index].dispose();
        _stepControllers.removeAt(index);
        _stepFocusNodes.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _featureNameController.dispose();
    _stateNotesController.dispose();
    _nextTodoController.dispose();
    _keyFilesController.dispose();
    _tagsController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final f in _stepFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 langkah alur logika!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final keyFiles = _keyFilesController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.isEditing) {
        final updatedEntry = widget.initialEntry!.copyWith(
          featureName: _featureNameController.text.trim(),
          flowSteps: steps,
          keyFiles: keyFiles,
          stateNotes: _stateNotesController.text.trim(),
          nextTodo: _nextTodoController.text.trim(),
          tags: tags,
        );

        await ref.read(devlogRepositoryProvider).updateFlowEntry(updatedEntry);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alur logika berhasil diperbarui!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final newEntry = FlowEntry(
          id: const Uuid().v4(),
          workspaceId: widget.workspaceId,
          featureName: _featureNameController.text.trim(),
          flowSteps: steps,
          keyFiles: keyFiles,
          stateNotes: _stateNotesController.text.trim(),
          nextTodo: _nextTodoController.text.trim(),
          tags: tags,
          createdAt: DateTime.now(),
        );

        await ref.read(devlogRepositoryProvider).createFlowEntry(newEntry);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alur logika berhasil dicatat!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Gagal memperbarui alur: $e'
                : 'Gagal menyimpan alur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _softInputDecoration(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      widget.isEditing
                          ? Icons.edit_note_outlined
                          : Icons.note_add_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEditing
                          ? 'Edit Alur Logika'
                          : 'Catat Alur Logika Baru',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Form Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Fitur (Clean Title Input)
                        TextFormField(
                          controller: _featureNameController,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ketik Nama Fitur...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Nama fitur wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Dynamic Steps Header
                        Row(
                          children: [
                            const Text(
                              'Langkah Alur Logika (Step-by-Step)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addStep,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Tambah Langkah'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Dynamic Step TextFields (FR-14)
                        ..._stepControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          final focusNode = _stepFocusNodes[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Focus(
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.enter &&
                                          (HardwareKeyboard.instance.isControlPressed ||
                                              HardwareKeyboard.instance.isMetaPressed)) {
                                        _addStep();
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      minLines: 1,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Langkah ${index + 1}: Apa yang dieksekusi kode...',
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant
                                            .withValues(alpha: 0.3),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_stepControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Hapus langkah',
                                      splashRadius: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 28, minHeight: 28),
                                      onPressed: () => _removeStep(index),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Next Todo (Handover Message - Required)
                        TextFormField(
                          controller: _nextTodoController,
                          maxLines: 2,
                          decoration: _softInputDecoration(
                            'Langkah Serah Terima Berikutnya (Next Todo) *',
                            'Misal: Sesi besok: Hubungkan Auth Interceptor ke Dio...',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Catatan serah terima (Next Todo) wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Collapsible Section for Secondary Fields
                        InkWell(
                          onTap: () => setState(() => _isOptionsExpanded = !_isOptionsExpanded),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _isOptionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Opsi Tambahan (Files, State, Tags)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        if (_isOptionsExpanded) ...[
                          const SizedBox(height: 12),
                          // State Notes
                          TextFormField(
                            controller: _stateNotesController,
                            maxLines: 2,
                            decoration: _softInputDecoration(
                              'Catatan State / Payload Penting',
                              'Misal: State disimpan di SecureStorage...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Key Files & Tags (2 Columns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _keyFilesController,
                                  decoration: _softInputDecoration(
                                    'Key Files (pisahkan koma)',
                                    'auth_service.dart, ...',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _tagsController,
                                  decoration: _softInputDecoration(
                                    'Tags (pisahkan koma)',
                                    'auth, api, ...',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(
                              widget.isEditing
                                  ? Icons.check_circle_outline
                                  : Icons.save_outlined,
                              size: 18,
                            ),
                      label: Text(
                        widget.isEditing ? 'Perbarui Alur' : 'Simpan Alur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
