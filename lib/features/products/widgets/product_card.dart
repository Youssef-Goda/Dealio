import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Discount calculation
    int discount = 0;
    if (product.oldPrice != null && product.oldPrice! > product.price) {
      discount =
          (((product.oldPrice! - product.price) / product.oldPrice!) * 100)
              .round();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.r(context, 15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: R.r(context, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Product image
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(R.r(context, 15)),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.all(R.r(context, 12)),
                        child:
                            // inside the ProductCard in the image section
                            Image.network(
                              product.imageUrls.isNotEmpty
                                  ? product
                                        .imageUrls
                                        .first //first image in the array
                                  : 'assets/images/dealio_logo.svg', //backup image if there is no image
                              fit: BoxFit.contain,
                              width: constraints.maxWidth * 0.85,
                              errorBuilder: (context, error, stackTrace) =>
                                  SvgPicture.asset(
                                    'assets/images/dealio_logo.svg',
                                    color: Colors.grey,
                                  ),
                            ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: R.all(context, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: R.font(context, 14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    R.verticalSpace(context, 5),

                    //2.Rating
                    Container(
                      padding: R.symmetric(context, horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(R.r(context, 3.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: R.iconSize(context, 14),
                          ),
                          SizedBox(width: R.w(context, 2)),
                          Text(
                            "${product.rating.toString()} (1.2K)",
                            style: TextStyle(
                              fontSize: R.font(context, 11),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    R.verticalSpace(context, 5),

                    //3.price
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "${product.price} EGP",
                          style: TextStyle(
                            fontSize: R.font(context, 15),
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (product.oldPrice != null &&
                            product.oldPrice! > 0) ...[
                          SizedBox(width: R.w(context, 8)),
                          Text(
                            "${product.oldPrice} EGP",
                            style: TextStyle(
                              fontSize: R.font(context, 12),
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 4.discount badge
          if (discount > 0)
            Positioned(
              top: R.h(context, 10),
              left: R.w(context, 10),
              child: Container(
                padding: R.symmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(R.r(context, 10)),
                ),
                child: Text(
                  "-$discount%",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: R.font(context, 10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 5.heart icon
          Positioned(
            top: R.h(context, 10),
            right: R.w(context, 10),
            child: Icon(
              LucideIcons.heart,
              size: R.iconSize(context, 20),
              color: Colors.grey,
            ),
          ),

          // 6.add button
          Positioned(
            bottom: R.h(context, 77.5),
            right: R.w(context, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(R.r(context, 5)),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.plus,
                color: AppColors.secondary,
                size: R.iconSize(context, 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
