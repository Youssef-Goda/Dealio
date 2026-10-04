import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dealio/core/constants/colors.dart';

class DragDropZone extends StatefulWidget {
  final Function(List<XFile>) onImagesDropped;
  final Function(String) onImageUploaded;

  const DragDropZone({
    Key? key,
    required this.onImagesDropped,
    required this.onImageUploaded,
  }) : super(key: key);

  @override
  State<DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends State<DragDropZone> {
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      widget.onImagesDropped(images);
    }
  } 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

    return SizedBox(
      height: 240,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Select product images",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? primaryColor.withOpacity(0.1)
                    : Colors.white,
                foregroundColor: primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text(
                "Browse Files",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
