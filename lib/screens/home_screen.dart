import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/models/home_model.dart';
import 'package:e_commerce/widgets/home_widgets/home_header.dart';
import 'package:e_commerce/widgets/product_widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const HomeHeader(),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 10,
                    childAspectRatio: .5,
                  ),
                  itemCount: dummyProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: dummyProducts[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(
          20,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            // currentIndex: _selectedIndex,
            // onTap: (index) {
            //   setState(() {
            //     _selectedIndex = index;
            //   });
            // },
            backgroundColor: Colors.white.withOpacity(
              0.9,
            ),
            selectedItemColor: const Color(
              0xFFFFD700,
            ),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType
                .fixed, // عشان الأيقونات ما تتحركش بشكل غريب
            showSelectedLabels:
                true,// عشان نعرض تسميات العناصر المحددة
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
