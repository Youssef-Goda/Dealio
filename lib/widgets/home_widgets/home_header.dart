import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:e_commerce/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  XFile? _pickedFile; // هنخزن الملف هنا لأنه بيشتغل ويب وموبايل
  dynamic
  _previewImage; // لعرض الصورة محلياً (File للموبايل أو Uint8List للويب)

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // select image from gallery
    final XFile? selected = await picker.pickImage(source: ImageSource.gallery);

    if (selected != null) {
      if (kIsWeb) {
        final bytes = await selected.readAsBytes();
        setState(() {
          _pickedFile = selected;
          _previewImage = bytes; // في الويب بنعرضها بـ Image.memory
        });
      } else {
        final bytes = await selected.readAsBytes();
        setState(() {
          _pickedFile = selected;
          _previewImage = bytes;
        });
      }
      debugPrint("✅ تم اختيار الصورة: ${selected.name}");
    }
  }

  Future<String?> _uploadImageToImgBB(XFile imageXFile) async {
    // 1.fetch API key from .env file
    // التعديل ده بيخلي الكود يدور في ملف الـ .env (لو موجود عندك لوكال)
    // ولو مش موجود (زي في فيرسال) يدور في إعدادات السيرفر
    final String imgbbApiKey = const String.fromEnvironment('IMGBB_API_KEY') ?? dotenv.env['IMGBB_API_KEY'] ?? '';
    // final String imgbbApiKey = dotenv.env['IMGBB_API_KEY'] ?? '';
    const String imgbbBaseUrl = 'https://api.imgbb.com/1/upload';

    if (imgbbApiKey.isEmpty) {
      debugPrint("❌ Error: IMGBB_API_KEY is not found in .env file");
      return null;
    } 

    try {
      // 2. إنشاء طلب الرفع
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$imgbbBaseUrl?key=$imgbbApiKey'),
      );

      // 3. إضافة الصورة للطلب
      // تحويل XFile إلى MultipartFile
      var stream = http.ByteStream(imageXFile.openRead());
      var length = await imageXFile.length();

      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageXFile.name,
      );

      request.files.add(multipartFile);

      debugPrint("⏳ Uploading image to ImgBB (Universal Method)...");
      var response = await request.send();

      // 4. response handling
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        String imageUrl = jsonResponse['data']['url'];
        debugPrint("✅ Upload successful: $imageUrl");
        return imageUrl;
      } else {
        debugPrint("⚠️ Server returned an error: ${response.statusCode}");
        var errorResponse = await response.stream.bytesToString();
        debugPrint("Details: $errorResponse");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception caught during upload: $e");
      return null;
    }
  }

  String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final atIndex = email.indexOf('@');
    if (atIndex < 4) return email;
    return email.replaceRange(2, atIndex - 2, "*******");
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final firstName = user != null ? (user['firstName'] ?? 'Guest') : 'Guest';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $firstName 👋",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Text(
                    "Find your deals!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),

          // const SizedBox(height: 20),
          // // Section for image upload
          // here77777777777777777777777777777777777777777777777777777777777777777777777777777777777777
          // _buildImagePickerSection(),
        ],
      ),
    );
  }

  // section widget for image picker and upload
  Widget _buildImagePickerSection() {
    return Column(
      children: [
        if (_previewImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.memory(
                    _previewImage as Uint8List,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.memory(
                    _previewImage as Uint8List,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            if (_pickedFile != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Uploading image... Please wait"),
                  duration: Duration(seconds: 2),
                ),
              );

              String? link = await _uploadImageToImgBB(_pickedFile!);

              if (link != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Upload Successful! Link: $link"),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'Copy Link',
                        textColor: Colors.white,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                        },
                      ),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Upload failed. Please try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please pick an image first!")),
              );
            }
          },
          icon: const Icon(Icons.cloud_upload),
          label: const Text("Upload Product to Server"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text("Pick Product Image"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Search for products...",
          hintStyle: TextStyle(color: AppColors.secondary),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
