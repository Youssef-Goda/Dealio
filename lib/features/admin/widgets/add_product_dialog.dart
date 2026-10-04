import 'dart:typed_data';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:dealio/features/admin/widgets/drag_drop_zone.dart';
import 'package:dealio/features/admin/widgets/uploading_images.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --- TextField Widget ---
Widget _buildTextField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? prefix,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600, 
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
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
          prefixIcon: Icon(
            icon,
            color: AppColors.primary.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? const Color.fromARGB(255, 203, 203, 203).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

/// --- Main Dialog ---
void showAddProductDialog(BuildContext context, {Product? product}) {
  final isEdit = product != null;
  context.read<CategoryProvider>().fetchCategories();

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

  String? selectedCategoryId = product?.categoryId;

  List<String> uploadedImageUrls = product?.imageUrls.toList() ?? [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = MediaQuery.of(context).size.width > 900;
            double dialogWidth = isWide
                ? 1100
                : MediaQuery.of(context).size.width * 0.95;

            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // تأثير الـ Blur
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Container(
                  width: dialogWidth,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Header (White on Primary) ---
                      _buildHeader(context, isEdit),

                      // --- Content ---
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Product Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // الحقول مفرودة بالعرض في الويب
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: [
                                  _box(
                                    isWide,
                                    0.65,
                                    _buildTextField(
                                      context: context,
                                      controller: nameController,
                                      label: "Product Name",
                                      hint: "Enter name",
                                      icon: Icons.shopping_bag_outlined,
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    0.31,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Category",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor?.withOpacity(0.8),
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Consumer<CategoryProvider>(
                                          builder: (context, catProv, _) {
                                            return DropdownButtonFormField<
                                              String
                                            >(
                                              value: selectedCategoryId,
                                              decoration: InputDecoration(
                                                hintText: "Select Category",
                                                prefixIcon: Icon(
                                                  Icons.category_outlined,
                                                  color: AppColors.primary
                                                      .withOpacity(0.7),
                                                  size: 20,
                                                ),
                                                filled: true,
                                                fillColor:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white.withOpacity(
                                                        0.05,
                                                      )
                                                    : Colors.grey.withOpacity(
                                                        0.05,
                                                      ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .dividerColor
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Theme.of(context)
                                                            .dividerColor
                                                            .withOpacity(0.1),
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .primary,
                                                            width: 2,
                                                          ),
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                hintStyle: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).hintColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              items: catProv.categories
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c.id,
                                                      child: Text(c.breadcrumb),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                setDialogState(() {
                                                  selectedCategoryId = val;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    0.31,
                                    _buildTextField(
                                      context: context,
                                      controller: priceController,
                                      label: "Price",
                                      hint: "0.00",
                                      icon: Icons.attach_money,
                                      keyboardType: TextInputType.number,
                                      prefix: "EGP ",
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    1.0,
                                    _buildTextField(
                                      context: context,
                                      controller: descController,
                                      label: "Description",
                                      hint: "Describe product...",
                                      icon: Icons.description_outlined,
                                      maxLines: 2,
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    0.31,
                                    _buildTextField(
                                      context: context,
                                      controller: oldPriceController,
                                      label: "Old Price",
                                      hint: "0.00",
                                      icon: Icons.money_off,
                                      keyboardType: TextInputType.number,
                                      prefix: "EGP ",
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    0.31,
                                    _buildTextField(
                                      context: context,
                                      controller: stockController,
                                      label: "Stock",
                                      hint: "0",
                                      icon: Icons.inventory_2,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  _box(
                                    isWide,
                                    0.31,
                                    _buildTextField(
                                      context: context,
                                      controller: ratingController,
                                      label: "Rating",
                                      hint: "4.5",
                                      icon: Icons.star_border,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
                              Text(
                                "Product Images",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // عرض الصور
                              if (uploadedImageUrls.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: uploadedImageUrls
                                        .map(
                                          (url) => _buildImageThumbnail(
                                            url,
                                            () => setDialogState(
                                              () =>
                                                  uploadedImageUrls.remove(url),
                                            ),
                                            context,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),

                              DragDropZone(
                                onImagesDropped: (List<XFile> files) async {
                                  _showCoolSnackBar(
                                    context,
                                    "📤 Uploading ${files.length} image(s)...",
                                    AppColors.primary,
                                  );

                                  int successCount = 0;
                                  // Get the JWT token once before the loop
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('accessToken') ?? prefs.getString('token') ?? '';
                                  for (var file in files) {
                                    try {
                                      final Uint8List bytes = await file
                                          .readAsBytes();
                                      String? url =
                                          await UploadingImages.uploadImageToImgBB(
                                            bytes,
                                            file.name,
                                            token,
                                          );

                                      if (url != null) {
                                        setDialogState(
                                          () => uploadedImageUrls.add(url),
                                        );
                                        successCount++;
                                      }
                                    } catch (e) {
                                      debugPrint("❌ Error uploading: $e");
                                    }
                                  }

                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  if (successCount > 0) {
                                    _showCoolSnackBar(
                                      context,
                                      "✅ Uploaded $successCount images successfully!",
                                      AppColors.primary,
                                    );
                                  } else {
                                    _showCoolSnackBar(
                                      context,
                                      "❌ Failed to upload images",
                                      AppColors.errorRedDark,
                                    );
                                  }
                                },
                                onImageUploaded: (url) => setDialogState(
                                  () => uploadedImageUrls.add(url),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      _buildDialogFooter(
                        context,
                        isDark,
                        textColor,
                        isEdit,
                        uploadedImageUrls,
                        nameController,
                        descController,
                        priceController,
                        oldPriceController,
                        ratingController,
                        stockController,
                        selectedCategoryId,
                        product,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

/// --- Header ---
Widget _buildHeader(BuildContext context, bool isEdit) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.05),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isEdit ? Icons.edit_note_rounded : Icons.add_box_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Edit Product' : 'Product Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.errorRed,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  );
}

/// --- وظيفة الـ SnackBar "السمارت" ---
void _showCoolSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ),
  );
}

/// --- Helper لتقسيم المساحات ---
Widget _box(bool isWide, double ratio, Widget child) {
  return SizedBox(
    width: isWide ? (1100 - 80) * ratio : double.infinity,
    child: child,
  );
}

/// --- Thumbnail الصور ---
Widget _buildImageThumbnail(
  String url,
  VoidCallback onDelete,
  BuildContext context,
) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).dividerColor.withOpacity(0.2),
      ),
      image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.errorRed,
              child: Icon(LucideIcons.x, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

/// --- Footer ---
Widget _buildDialogFooter(
  BuildContext context,
  bool isDark,
  Color? textColor,
  bool isEdit,
  List<String> uploadedImageUrls,
  nameController,
  descController,
  priceController,
  oldPriceController,
  ratingController,
  stockController,
  String? selectedCategoryId,
  product,
) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.02)
          : AppColors.backgroundLight,
      border: Border(
        top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: textColor)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                          "Please upload at least one image",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.errorRedDark,
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
              price: double.tryParse(priceController.text) ?? 0.0,
              imageUrls: uploadedImageUrls,
              oldPrice: double.tryParse(oldPriceController.text),
              rating: double.tryParse(ratingController.text) ?? 0.0,
              countInStock: int.tryParse(stockController.text) ?? 0,
              categoryId: selectedCategoryId,
              createdAt: isEdit ? product.createdAt : DateTime.now(),
            );

            bool success = isEdit
                ? await provider.updateProduct(productData)
                : await provider.addProduct(
                    name: productData.name,
                    description: productData.description,
                    price: productData.price,
                    imageUrls: uploadedImageUrls,
                    oldPrice: productData.oldPrice,
                    rating: productData.rating,
                    countInStock: productData.countInStock,
                    categoryId: selectedCategoryId,
                  );

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? "Product updated!" : "Product added!",
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.successGreenDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Text(
            isEdit ? "Update Product" : "Save Product",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
