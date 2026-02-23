import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/models/product_model.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/features/admin/widgets/uploading_images.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';

void showAddProductDialog(BuildContext context, {Product? product}) {
  final isEdit = product != null;

  final nameController = TextEditingController(text: product?.name);
  final descController = TextEditingController(text: product?.description);
  final priceController = TextEditingController(
    text: product?.price.toString(),
  );
  final oldPriceController = TextEditingController(
    text: product?.oldPrice?.toString(),
  );
  final ratingController = TextEditingController(
    text: product?.rating.toString(),
  );
  final stockController = TextEditingController(
    text: product?.countInStock.toString() ?? "0",
  );

  List<String> uploadedImageUrls = product?.imageUrls.toList() ?? [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEdit
                              ? Icons.edit_rounded
                              : Icons.add_circle_outline,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? "Edit Product" : "Add New Product",
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          "Product Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: nameController,
                          label: "Product Name",
                          hint: "Enter product name",
                          icon: Icons.shopping_bag_outlined,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        _buildTextField(
                          controller: descController,
                          label: "Description",
                          hint: "Describe your product...",
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),

                        // Price & Old Price
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: priceController,
                                label: "Price",
                                hint: "0.00",
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                prefix: "EGP ",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: oldPriceController,
                                label: "Old Price (Optional)",
                                hint: "0.00",
                                icon: Icons.money_off_outlined,
                                keyboardType: TextInputType.number,
                                prefix: "EGP ",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stock & Rating
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: stockController,
                                label: "Stock Quantity",
                                hint: "0",
                                icon: Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: ratingController,
                                label: "Rating (0-5)",
                                hint: "4.5",
                                icon: Icons.star_outline,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Images Section
                        Text(
                          "Product Images",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Upload at least one high-quality image",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (uploadedImageUrls.isNotEmpty) ...[
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: uploadedImageUrls.map((url) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setDialogState(
                                          () => uploadedImageUrls.remove(url),
                                        ),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade500,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Drag & Drop Zone
                        DragDropZone(
                          onImagesDropped: (files) async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.secondary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "📤 Uploading ${files.length} image(s)...",
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );

                            int successCount = 0;
                            int failCount = 0;

                            for (var file in files) {
                              try {
                                final reader = html.FileReader();
                                reader.readAsArrayBuffer(file);
                                await reader.onLoadEnd.first;
                                final Uint8List bytes =
                                    reader.result as Uint8List;
                                String? url =
                                    await UploadingImages.uploadImageToImgBB(
                                      bytes,
                                      file.name,
                                    );

                                if (url != null) {
                                  setDialogState(() {
                                    uploadedImageUrls.add(url);
                                  });
                                  successCount++;
                                } else {
                                  failCount++;
                                }
                              } catch (e) {
                                debugPrint(
                                  "❌ Error uploading ${file.name}: $e",
                                );
                                failCount++;
                              }
                            }

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            if (successCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "✅ Uploaded $successCount image(s) successfully!" +
                                              (failCount > 0
                                                  ? "\n⚠️ $failCount failed"
                                                  : ""),
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "❌ Failed to upload images",
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onImageUploaded: (url) {
                            setDialogState(() {
                              uploadedImageUrls.add(url);
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: /*isEdit
                                ? Colors.green
                                :*/
                                AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: AppColors.primary.withOpacity(0.3),
                          ),
                          onPressed: () async {
                            if (uploadedImageUrls.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "⚠️ Please upload at least one image",
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            final provider = context.read<ProductProvider>();
                            final productData = Product(
                              id: isEdit ? product.id : "",
                              serialId: isEdit ? product.serialId : 0,
                              code: isEdit ? product.code : "",
                              name: nameController.text,
                              description: descController.text,
                              price:
                                  double.tryParse(priceController.text) ?? 0.0,
                              imageUrls: uploadedImageUrls,
                              oldPrice: double.tryParse(
                                oldPriceController.text,
                              ),
                              rating:
                                  double.tryParse(ratingController.text) ?? 0.0,
                              countInStock:
                                  int.tryParse(stockController.text) ?? 0,
                              createdAt: isEdit
                                  ? product.createdAt
                                  : DateTime.now(),
                            );

                            bool success = isEdit
                                ? await provider.updateProduct(productData)
                                : await provider.addProduct(
                                    name: productData.name,
                                    description: productData.description,
                                    price: productData.price,
                                    imageUrls: uploadedImageUrls,
                                    // imageUrls: productData.imageUrls,
                                    oldPrice: productData.oldPrice,
                                    rating: productData.rating,
                                    countInStock: productData.countInStock,
                                  );

                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isEdit
                                            ? "✅ Product updated!"
                                            : "✅ Product added!",
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.check_circle_outline
                                    : Icons.save_outlined,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit ? "Update Product" : "Save Product",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Drag & Drop Zone Widget
class DragDropZone extends StatefulWidget {
  final Function(List<html.File>) onImagesDropped;
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
  bool isDragging = false;
  final String viewId = 'drop-zone-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerDropZone();
  }

  void _registerDropZone() {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final div = html.DivElement()
        ..id = 'drop-zone-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.background = 'transparent';

      div.onDragOver.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        if (!isDragging) {
          setState(() => isDragging = true);
        }
      });

      div.onDragEnter.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        setState(() => isDragging = true);
      });

      div.onDragLeave.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        final rect = div.getBoundingClientRect();
        if (event.client.x < rect.left ||
            event.client.x > rect.right ||
            event.client.y < rect.top ||
            event.client.y > rect.bottom) {
          setState(() => isDragging = false);
        }
      });

      div.onDrop.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        setState(() => isDragging = false);

        final files = event.dataTransfer.files;
        if (files != null && files.isNotEmpty) {
          print("✅ Files dropped: ${files.length}");
          final imageFiles = files
              .where((f) => f.type.startsWith('image/'))
              .toList();
          if (imageFiles.isNotEmpty) {
            widget.onImagesDropped(imageFiles);
          }
        }
      });

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(child: HtmlElementView(viewType: viewId)),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDragging
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDragging
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isDragging ? 3 : 2,
                    style: isDragging ? BorderStyle.solid : BorderStyle.solid,
                  ),
                  boxShadow: isDragging
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDragging
                          ? Icons.cloud_download_rounded
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: isDragging
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isDragging ? "Drop to upload" : "Drag & drop images here",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDragging
                            ? AppColors.primary
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("or", style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add file picker logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text(
                        "Browse Files",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TextField Widget
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? prefix,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: -0.1,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}