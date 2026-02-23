import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/features/home/widgets/home_header.dart';
import 'package:e_commerce/features/products/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeader(),

            R.verticalSpace(context, 10),

            Consumer<ProductProvider>(
              builder: (context, productProv, child) {
                // loading
                if (productProv.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // no products
                if (productProv.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No products found in the database.",
                        style: TextStyle(fontSize: R.font(context, 16)),
                      ),
                    ),
                  );
                }

                // products
                return Consumer<ProductProvider>(
                  builder: (context, productProv, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        double width = constraints.maxWidth;
                        int crossAxisCount;

                        if (width < 600) {
                          crossAxisCount = 2; // mobile
                        } else if (width < 900) {
                          crossAxisCount = 3; // tablet / small web
                        } else if (width < 1200) {
                          crossAxisCount = 4; // medium web
                        } else {
                          crossAxisCount = 5; // large web
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: R.symmetric(
                            context,
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: productProv.products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: R.isMobile(context)
                                    ? 0.60
                                    : 0.75,
                              ),
                          itemBuilder: (context, index) {
                            final product = productProv.products[index];
                            return ProductCard(product: product);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
