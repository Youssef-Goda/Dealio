import 'dart:ui';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/features/admin/widgets/drag_drop_zone.dart';
import 'package:provider/provider.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/features/admin/widgets/uploading_images.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// import 'package:lucide_icons/lucide_icons.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showProductDetailsDialog(
  BuildContext context,
  Product product,
  VoidCallback onDelete,
) {
  showDialog(
    context: context,
    builder: (ctx) =>
        ProductDetailsDialog(product: product, onDelete: onDelete),
  );
} 

class ProductDetailsDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onDelete;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onDelete,
  });

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  bool isEditing = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;
  late TextEditingController oldPriceController;
  late TextEditingController ratingController;
  late TextEditingController stockController;
  late List<String> uploadedImageUrls;
  String? selectedCategoryId;

  bool _isUploading = false;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _initControllers() {
    nameController = TextEditingController(text: _currentProduct.name);
    descController = TextEditingController(text: _currentProduct.description);
    priceController = TextEditingController(
      text: _currentProduct.price.toString(),
    );
    oldPriceController = TextEditingController(
      text: _currentProduct.oldPrice?.toString(),
    );
    ratingController = TextEditingController(
      text: _currentProduct.rating.toString(),
    );
    stockController = TextEditingController(
      text: _currentProduct.countInStock.toString(),
    );
    uploadedImageUrls = _currentProduct.imageUrls.toList();
    selectedCategoryId = _currentProduct.categoryId;
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    oldPriceController.dispose();
    ratingController.dispose();
    stockController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = R.isLargeScreen(context);
    double dialogWidth = isDesktop ? 1100 : 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: isDesktop
                    ? _buildDesktopContent()
                    : _buildMobileContent(),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary.withOpacity(0.05) : AppColors.primary,
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
                isEditing ? LucideIcons.pencilLine : LucideIcons.package,
                color: isDark ? AppColors.primary : AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Product' : 'Product Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.errorRed,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white, // الإكس أبيض
              iconSize: 14,
              padding: EdgeInsets.zero, // عشان الأيقونة تكون في النص بالظبط
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildImageSection(),
              ),
            ),
            Container(
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.2),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isEditing ? _buildEditForm() : _buildViewDetails(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 24),
          isEditing ? _buildEditForm() : _buildViewDetails(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGallery(),
        if (isEditing) ...[
          const SizedBox(height: 24),
          _buildEditImagesSection(),
        ],
      ],
    );
  }

  Widget _buildImageGallery() {
    final images = isEditing ? uploadedImageUrls : _currentProduct.imageUrls;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (images.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.black.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          LucideIcons.imageOff,
          size: 48,
          color: AppColors.textSecondary,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        // شيلنا الـ boxShadow والـ border الخارجي تماماً
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: R.isLargeScreen(context) ? 400 : 250,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: // الجزء المعدل جوه itemBuilder
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. الخلفية الـ Blur
                                Image.network(images[index], fit: BoxFit.cover),

                                // 2. طبقة التعتيم (دي اللي هتعالج التنوير)
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    // في الدارك مود بنخليها سودة أتقل (0.5) عشان تمنع النور
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black.withOpacity(0.5)
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                ),

                                // 3. الصورة الأساسية
                                Image.network(
                                  images[index],
                                  fit: BoxFit
                                      .contain, // حافظنا عليها عشان متتقصش
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  uploadedImageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                  // شيلنا الـ shadow من زرار المسح برضه
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Image Navigation Arrows (Left / Right)
                if (images.length > 1)
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // السهم الشمال
                        IconButton(
                          onPressed: () {
                            if (_currentImageIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // اللون بيقلب حسب المود من غير shadow
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.secondary.withOpacity(0.8)
                                  : AppColors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                        // السهم اليمين
                        IconButton(
                          onPressed: () {
                            if (_currentImageIndex < images.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.secondary.withOpacity(0.8)
                                  : AppColors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : AppColors.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add New Images",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            // اللون هنا هيتعدل تلقائياً حسب المود
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        DragDropZone(
          onImagesDropped: (List<XFile> files) async {
            setState(() => _isUploading = true);
            int successCount = 0;
            // Retrieve the JWT token once before the loop
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('accessToken') ?? prefs.getString('token') ?? '';

            for (var file in files) {
              try {
                final Uint8List bytes = await file.readAsBytes();
                String? url = await UploadingImages.uploadImageToImgBB(
                  bytes,
                  file.name,
                  token,
                );

                if (url != null) {
                  setState(() {
                    uploadedImageUrls.add(url);
                  });
                  successCount++;
                }
              } catch (e) {
                debugPrint("❌ Error uploading ${file.name}: $e");
              }
            }

            setState(() => _isUploading = false);

            if (mounted && successCount > 0) {
              // استخدمنا الـ CoolSnackBar عشان تظبط مع الدارك واللايت
              _showCoolSnackBar(
                context,
                "✅ Uploaded $successCount image(s) successfully!",
                AppColors.primary,
              );
            }
          },
          onImageUploaded: (url) {
            setState(() {
              uploadedImageUrls.add(url);
            });
          },
        ),
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // اللون بياخد Primary علطول
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Uploading images...",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    // النص لونه بيبقى مناسب للمود
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ميثود الـ SnackBar اللي بتظبط الألوان
  void _showCoolSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white, // دايماً أبيض عشان الـ Primary غالباً غامق
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

  Widget _buildViewDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductInfo(context),
        const SizedBox(height: 24),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildDatesRow(),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        // شيلنا الـ boxShadow والـ border اللي بيعملوا وهج أو "نور" في الدارك مود
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.surfaceLight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentProduct.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        // النص بيبقى أبيض في الدارك مود
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // خلفية الكود بتبقى أغمق في الدارك مود
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Code: ${_currentProduct.code}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,###.##').format(_currentProduct.price)} EGP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      // بنستخدم أخضر منور شوية في الدارك مود عشان يظهر
                      color: isDark
                          ? Colors.greenAccent
                          : AppColors.successGreenDark,
                    ),
                  ),
                  if (_currentProduct.oldPrice != null &&
                      _currentProduct.oldPrice! > 0)
                    Text(
                      '${NumberFormat('#,###.##').format(_currentProduct.oldPrice)} EGP',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentProduct.description.isNotEmpty
                ? _currentProduct.description
                : 'No description available.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              // لون الوصف خفيته شوية عشان ميبقاش "فقع" في العين
              color: isDark ? Colors.white70 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.star_rounded,
            title: 'Rating',
            value: _currentProduct.rating.toStringAsFixed(1),
            color: AppColors.starAmber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: LucideIcons.boxes,
            title: 'Stock',
            value: '${_currentProduct.countInStock} units',
            color: _currentProduct.countInStock > 10
                ? AppColors.successGreen
                : (_currentProduct.countInStock > 0
                      ? AppColors.warningAmber
                      : AppColors.errorRed),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // في الدارك مود بنقلل الـ Opacity جداً عشان ميبقاش "منور" زيادة
        color: isDark ? color.withOpacity(0.08) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // البوردر بيبقى خفيف ومن نفس روح اللون
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // الأيقونة واخدة اللون الصريح عشان تبرز
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            // ضفت Expanded هنا عشان لو النص طويل ميعملش Overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    // لون العنوان بيبقى خافت شوية
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesRow() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // بدل اللون الثابت، بنستخدم خلفية شفافة بذكاء عشان تناسب المود
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.surfaceLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // التاريخ الأول (إنشاء) محاذاة للشمال
          _buildDateInfo('Created At', _currentProduct.createdAt, isLeft: true),

          // خط فاصل رفيع في النص بيخلي الشكل "Premium"
          Container(
            height: 24,
            width: 1,
            color: isDark ? Colors.white10 : AppColors.borderLight,
          ),

          // التاريخ الثاني (تحديث) محاذاة لليمين
          _buildDateInfo(
            'Last Updated',
            _currentProduct.updatedAt,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime? date, {required bool isLeft}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      // بيحدد المحاذاة حسب مكانه في الـ Row
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            // العنوان بيبقى خافت شوية عشان نبرز التاريخ
            color: isDark ? Colors.white38 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date != null
              ? DateFormat('MMM dd, yyyy HH:mm').format(date.toLocal())
              : 'Never',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            // التاريخ بياخد النص الأساسي للمود الحالي
            color: isDark
                ? Colors.white.withOpacity(0.9)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        // شيلنا الـ boxShadow والـ border التقليدي عشان نمنع الوهج
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.surfaceLight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Edit Product Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
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
          _buildTextField(
            controller: descController,
            label: "Description",
            hint: "Describe your product...",
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Consumer<CategoryProvider>(
            builder: (context, catProv, _) {
              return DropdownButtonFormField<String>(
                value: selectedCategoryId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.backgroundLight,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.dividerGrey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                items: catProv.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.breadcrumb),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedCategoryId = value),
              );
            },
          ),
          const SizedBox(height: 20),
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
                  label: "Old Price",
                  hint: "0.00",
                  icon: Icons.money_off_outlined,
                  keyboardType: TextInputType.number,
                  prefix: "EGP ",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : AppColors.textHint,
              fontSize: 14,
            ),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              size: 20,
            ),
            filled: true,
            // هنا السر: اللون بيبقى غامق جداً في الدارك عشان ميعملش "نور"
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.backgroundLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.dividerGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.textSecondary.withOpacity(0.1),
          ),
        ),
        // الخلفية بقت ذكية عشان متعملش "نور" فاقع في الدارك مود
        color: isDark ? Theme.of(context).cardColor : AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: isEditing ? _buildEditActions() : _buildViewActions(),
    );
  }

  Widget _buildViewActions() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            widget.onDelete(); // Trigger delete action
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorRed,
            side: BorderSide(
              color: AppColors.errorRed.withOpacity(isDark ? 0.3 : 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.trash2, size: 18),
          label: const Text('Delete'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => isEditing = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.pencilLine, size: 18),
          label: const Text('Edit Product'),
        ),
      ],
    );
  }

  Widget _buildEditActions() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              isEditing = false;
              _initControllers(); // Reset form
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark ? Colors.white10 : AppColors.borderLight,
              ),
            ),
          ),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (uploadedImageUrls.isEmpty) {
      _showCustomSnackBar(
        "⚠️ Please have at least one image",
        AppColors.errorRed,
      );
      return;
    }

    // بنشغل لودينج لو عندك Variable ماسك الحالة دي
    // setState(() => _isSaving = true);

    final provider = context.read<ProductProvider>();
    final productData = Product(
      id: _currentProduct.id,
      serialId: _currentProduct.serialId,
      code: _currentProduct.code,
      name: nameController.text,
      description: descController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
      imageUrls: uploadedImageUrls,
      oldPrice: double.tryParse(oldPriceController.text),
      rating: double.tryParse(ratingController.text) ?? 0.0,
      countInStock: int.tryParse(stockController.text) ?? 0,
      categoryId: selectedCategoryId,
      createdAt: _currentProduct.createdAt,
      updatedAt: DateTime.now(),
    );

    bool success = await provider.updateProduct(productData);

    if (mounted) {
      if (success) {
        _showCustomSnackBar(
          "✅ Product updated successfully!",
          AppColors.successGreen,
        );
        setState(() {
          _currentProduct = productData;
          isEditing = false;
        });
      } else {
        _showCustomSnackBar("⚠️ Failed to update product", AppColors.errorRed);
      }
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
