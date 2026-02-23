import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_commerce/core/constants/base_url.dart';

class ApiService {
  //General Post Request
  static Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  //Response Processing Method
  static Map<String, dynamic> processResponse(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'حدث خطأ ما'};
    }
  }
}
