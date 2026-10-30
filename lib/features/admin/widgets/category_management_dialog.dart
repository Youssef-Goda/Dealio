import 'dart:typed_data';

import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/category_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:dealio/features/admin/widgets/drag_drop_zone.dart';
import 'package:dealio/features/admin/widgets/uploading_images.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// category_management_dialog.dart
//
// Public API:
//   showCategoryDialog(context, {existing})     — create / edit
//   showDeleteCategoryConfirm(context, cat)     — confirm + delete
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showCategoryDialog(
  BuildContext context, {
  CategoryModel? existing,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CategoryDialog(existing: existing),
  );
}

Future<void> showDeleteCategoryConfirm(
  BuildContext context,
  CategoryModel cat,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Category'),
      content: Text(
        'Delete "${cat.name}"?\n\n'
        'Categories that still have products assigned to them cannot be deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final token = context.read<AuthProvider>().token ?? '';
  final error = await context.read<CategoryProvider>().deleteCategory(
    token,
    cat.id,
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error ?? '"${cat.name}" deleted.'),
      backgroundColor: error == null ? AppColors.primary : AppColors.errorRed,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? existing;
  const _CategoryDialog({this.existing});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _imageUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _imageUrl = widget.existing!.iconUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final token = context.read<AuthProvider>().token ?? '';
    final catProv = context.read<CategoryProvider>();
    final name = _nameCtrl.text.trim();

    final String? error;
    if (_isEdit) {
      error = await catProv.updateCategory(
        token,
        widget.existing!.id,
        name,
        imageUrl: _imageUrl,
      );
    } else {
      error = await catProv.createCategory(token, name, imageUrl: _imageUrl);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Category updated.' : 'Category created.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.errorRed),
      );
    }
  }

  Future<String> _getToken() async {
    // First try AuthProvider (fastest); fallback to SharedPreferences
    // (needed for DragDropZone callbacks that run outside the widget tree).
    if (!mounted) return '';
    final fromProvider = context.read<AuthProvider>().token;
    if (fromProvider != null && fromProvider.isNotEmpty) return fromProvider;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') ?? prefs.getString('token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ────────────────────────────────────────────────
                Text(
                  _isEdit ? 'Edit Category' : 'New Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Name ─────────────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Category name *',
                    prefixIcon: const Icon(
                      LucideIcons.tag,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Image ─────────────────────────────────────────────────
                Text(
                  'Category image (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),

                if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.imageOff,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () => setState(() => _imageUrl = null),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DragDropZone(
                    onImagesDropped: (files) async {
                      if (files.isEmpty) return;
                      setState(() => _isUploading = true);
                      try {
                        final token = await _getToken();
                        final file = files.first;
                        final Uint8List bytes = await file.readAsBytes();
                        final url = await UploadingImages.uploadImageToImgBB(
                          bytes,
                          file.name,
                          token,
                        );
                        if (url != null && mounted) {
                          setState(() => _imageUrl = url);
                        }
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    },
                    onImageUploaded: (url) {
                      if (mounted) setState(() => _imageUrl = url);
                    },
                  ),

                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Save changes' : 'Create',
                              style: const TextStyle(color: Colors.white),
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

