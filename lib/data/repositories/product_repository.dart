import 'package:e_commerce/data/services/api_service.dart';

class ProductRepository {
  
  // 1. ميثود لجلب كل المنتجات (عشان نعرضهم في جدول الأدمن)
  Future<Map<String, dynamic>> getAllProducts() async {
    final res = await ApiService.postRequest('/products/all', {});
    return ApiService.processResponse(res);
  }

  // 2. ميثود إضافة منتج جديد
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    final res = await ApiService.postRequest('/products/add', productData);
    return ApiService.processResponse(res);
  }

  // 3. ميثود مسح منتج
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    final res = await ApiService.postRequest('/products/delete', {"id": productId});
    return ApiService.processResponse(res);
  }
}