import 'package:e_commerce/models/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.transparent,
                          child: SvgPicture.asset(
                            'assets/images/dealio_logo.svg',
                            height: 250,
                            colorFilter: ColorFilter.mode(
                              Colors.grey.shade400,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 5),
                    // 3. rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // to wrap content width
                        children: [
                          const Icon(Icons.star, color: Colors.green, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            "${product.rating} (1.2K)",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // 4. price and discount
                    Row(
                      children: [
                        const Text(
                          "EGP ",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${product.price}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (product.oldPrice != null)
                          Text(
                            "${product.oldPrice}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const SizedBox(width: 5),
                        if (product.oldPrice != null)
                          const Text(
                            '8% OFF',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 120,
            left: 5,
            child: const Icon(
              Icons.favorite_border,
              size: 20,
              color: Colors.grey,
            ),
          ),
          Positioned(
            bottom: 120,
            right: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
