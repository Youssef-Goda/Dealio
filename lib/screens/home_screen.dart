import 'package:e_commerce/models/home_model.dart';
import 'package:e_commerce/widgets/home_widgets/home_header.dart';
import 'package:e_commerce/widgets/product_widgets/product_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  HomeScreen({
    super.key,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory HomeScreen.fromJson(Map<String, dynamic> json) {
    return HomeScreen(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final atIndex = email.indexOf('@');
    if (atIndex < 4) return email;
    return email.replaceRange(2, atIndex - 2, "*******");
  }

  final List<Product> dummyProducts = [
    Product(
      id: '1',
      name: 'iPhone 15 Pro',
      description: 'Powerful smartphone...',
      price: 999.0,
      image: 'https://images.remote.com/iphone.png',
      rating: 4.8,
    ),
    Product(
      id: '1',
      name: 'iPhone 15 Pro',
      description: 'Powerful smartphone...',
      price: 999.0,
      image: 'https://images.remote.com/iphone.png',
      rating: 4.8,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'AirPods Pro',
      description: 'Best noise canceling...',
      price: 249.0,
      image: 'https://images.remote.com/airpods.png',
      rating: 4.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeHeader(firstName: firstName),
              // هنا البانر
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                itemCount: dummyProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: dummyProducts[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
