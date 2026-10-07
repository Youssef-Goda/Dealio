import 'dart:io';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/review_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/review_provider.dart';
import 'package:dealio/data/services/image_upload_service.dart';
import 'package:dealio/features/products/widgets/star_rating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const int kMaxReviewImages = 5;
const int kMaxCommentLength = 500;

// ── Entry points (static show methods) ───────────────────────────────────────

/// Shows the Write Review bottom sheet.
///
/// [productId] and [orderItemId] are required for submission.
/// [existingReview] is provided when editing an existing review.
Future<void> showWriteReviewSheet({
  required BuildContext context,
  required String productId,
  required String orderItemId,
  ReviewModel? existingReview,
  required ReviewProvider reviewProvider,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: reviewProvider,
      child: WriteReviewSheet(
        productId: productId,
        orderItemId: orderItemId,
        existingReview: existingReview,
      ),
    ),
  );
}

// ── Main sheet widget ─────────────────────────────────────────────────────────

class WriteReviewSheet extends StatefulWidget {
  final String productId;
  final String orderItemId;
  final ReviewModel? existingReview;

  const WriteReviewSheet({
    super.key,
    required this.productId,
    required this.orderItemId,
    this.existingReview,
  });

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _rating = 0;
  List<String> _uploadedImageUrls = []; // Already uploaded URLs
  List<XFile> _pendingFiles = []; // Selected but not yet uploaded files
  bool _isUploadingImages = false;
  String? _imageUploadError;
  bool _submitted = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill for editing
    if (_isEditing) {
      final e = widget.existingReview!;
      _rating = e.rating;
      _commentController.text = e.comment ?? '';
      _uploadedImageUrls = List<String>.from(e.images);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final totalCurrent = _uploadedImageUrls.length + _pendingFiles.length;
    final remaining = kMaxReviewImages - totalCurrent;
    if (remaining <= 0) {
      _showSnack('Maximum $kMaxReviewImages images allowed.');
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      // Validate file sizes
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          _showSnack('Images must be under 5 MB each.');
          return;
        }
      }

      setState(() {
        _pendingFiles.addAll(picked.take(remaining));
        _imageUploadError = null;
      });
    } catch (e) {
      _showSnack('Could not open image picker. Please try again.');
    }
  }

  void _removePending(int idx) => setState(() => _pendingFiles.removeAt(idx));
  void _removeUploaded(int idx) => setState(() => _uploadedImageUrls.removeAt(idx));

  Future<List<String>> _uploadPendingFiles(String token) async {
    final urls = <String>[];
    for (final file in _pendingFiles) {
      if (kIsWeb) {
        // Web: use bytes
        final bytes = await file.readAsBytes();
        // Build a temp File-like object isn't available on web; use raw byte approach
        // ImageUploadService only accepts File (mobile) — for web, we skip images
        // (Web image upload would need a different multipart approach)
        // For now, skip silently on web
        continue;
      }
      final result = await ImageUploadService.uploadImage(
        file: File(file.path),
        token: token,
      );
      if (result is UploadSuccess) {
        urls.add(result.url);
      } else if (result is UploadFailure) {
        throw Exception(result.message);
      }
    }
    return urls;
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_rating == 0) {
      _showSnack('Please select a star rating before submitting.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitted) return;
    _submitted = true;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) {
      _showSnack('Session expired. Please log in again.');
      _submitted = false;
      return;
    }

    final reviewProvider = context.read<ReviewProvider>();

    // 1. Upload pending images
    if (_pendingFiles.isNotEmpty && !kIsWeb) {
      setState(() {
        _isUploadingImages = true;
        _imageUploadError = null;
      });
      try {
        final newUrls = await _uploadPendingFiles(token);
        _uploadedImageUrls.addAll(newUrls);
        _pendingFiles.clear();
      } catch (e) {
        setState(() {
          _isUploadingImages = false;
          _imageUploadError = e.toString().replaceFirst('Exception: ', '');
          _submitted = false;
        });
        return;
      }
      setState(() => _isUploadingImages = false);
    }

    // 2. Submit or update review
    bool success;
    if (_isEditing) {
      success = await reviewProvider.updateReview(
        reviewId: widget.existingReview!.id,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        images: _uploadedImageUrls,
        token: token,
      );
    } else {
      success = await reviewProvider.submitReview(
        productId: widget.productId,
        orderItemId: widget.orderItemId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        images: _uploadedImageUrls,
        token: token,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        // Success feedback handled by parent
      } else {
        _submitted = false;
        final errMsg = reviewProvider.submitError ?? 'Failed to submit review.';
        _showSnack(errMsg);
        reviewProvider.resetSubmitState();
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isSubmitting = context.watch<ReviewProvider>().isSubmitting;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Your Review' : 'Write a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            ),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star rating
                      _SectionLabel(
                        label: 'Your Rating *',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            StarRatingInput(
                              value: _rating,
                              onChanged: (v) => setState(() => _rating = v),
                              starSize: 42,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _ratingLabel(_rating),
                              style: TextStyle(
                                fontSize: 13,
                                color: _rating > 0
                                    ? AppColors.starAmber
                                    : (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textSecondary),
                                fontWeight: _rating > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Comment
                      _SectionLabel(label: 'Comment (optional)', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: kMaxCommentLength,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimaryDark,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your experience with this product...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkBackground
                              : AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          counterStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.length > kMaxCommentLength) {
                            return 'Comment must be under $kMaxCommentLength characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Images section (mobile only)
                      if (!kIsWeb) ...[
                        _SectionLabel(
                          label: 'Photos (optional, max $kMaxReviewImages)',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),

                        // Uploaded image previews
                        if (_uploadedImageUrls.isNotEmpty ||
                            _pendingFiles.isNotEmpty) ...[
                          _ImagePreviewStrip(
                            uploadedUrls: _uploadedImageUrls,
                            pendingFiles: _pendingFiles,
                            onRemoveUploaded: _removeUploaded,
                            onRemovePending: _removePending,
                            isUploading: _isUploadingImages,
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (_imageUploadError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _imageUploadError!,
                              style: const TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // Add image button
                        if (_uploadedImageUrls.length + _pendingFiles.length <
                            kMaxReviewImages)
                          GestureDetector(
                            onTap: _isUploadingImages ? null : _pickImages,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.primary.withOpacity(0.05),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (isSubmitting || _isUploadingImages)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black87,
                            disabledBackgroundColor:
                                AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: (isSubmitting || _isUploadingImages)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Update Review'
                                      : 'Submit Review',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
      ),
    );
  }
}

// ── Image preview strip ───────────────────────────────────────────────────────

class _ImagePreviewStrip extends StatelessWidget {
  final List<String> uploadedUrls;
  final List<XFile> pendingFiles;
  final ValueChanged<int> onRemoveUploaded;
  final ValueChanged<int> onRemovePending;
  final bool isUploading;

  const _ImagePreviewStrip({
    required this.uploadedUrls,
    required this.pendingFiles,
    required this.onRemoveUploaded,
    required this.onRemovePending,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Already uploaded
          ...uploadedUrls.asMap().entries.map((e) => _UploadedThumb(
                url: e.value,
                onRemove: () => onRemoveUploaded(e.key),
              )),
          // Pending (not yet uploaded)
          ...pendingFiles.asMap().entries.map((e) => _PendingThumb(
                file: e.value,
                onRemove: () => onRemovePending(e.key),
                uploading: isUploading,
              )),
        ],
      ),
    );
  }
}

class _UploadedThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _UploadedThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 70,
          height: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.darkBorder,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  final bool uploading;

  const _PendingThumb({
    required this.file,
    required this.onRemove,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 70,
          height: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? const SizedBox()
                : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (uploading)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            top: 2,
            right: 10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 10),
              ),
            ),
          ),
      ],
    );
  }
}
