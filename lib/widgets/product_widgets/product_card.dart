import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final dynamic product; // استخدم الموديل بتاعك هنا

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200), // نون بتستخدم حدود خفيفة بدل الـ Shadow الثقيل
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. صورة المنتج مع السلايدر الصغير (Dots)
              Expanded(
                child: Center(
                  child: Image.network(product.image, fit: BoxFit.contain),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. اسم المنتج (سطرين بالظبط)
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 5),
                    
                    // 3. التقييم (زي نون: نجمة وخلفية خفيفة)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.green, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          "${product.rating} (1.2K)", // رقم التقييمات
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    
                    // 4. السعر والخصم
                    Row(
                      children: [
                        const Text("EGP ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(
                          "${product.price}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    
                    // السعر القديم والخصم
                    Row(
                      children: [
                        Text(
                          "${product.oldPrice}",
                          style: const TextStyle(
                            fontSize: 11, 
                            color: Colors.grey, 
                            decoration: TextDecoration.lineThrough
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text("8% OFF", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // 5. علامة Express (مستطيل أصفر)
                    // Image.network("https://z.nooncdn.com/s/app/com/noon/images/en_express_v2.png", width: 45),
                  ],
                ),
              ),
            ],
          ),
          
          // 6. الأزرار العلوية (المفضلة والزيادة)
          Positioned(
            top: 5,
            right: 5,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              radius: 15,
              child: const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
            ),
          ),
          Positioned(
            top: 100, // مكان تقريبي لزرار الزائد
            right: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: const Icon(Icons.add, color: Colors.blue, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}