import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Nhớ import AuthProvider của bạn

class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _storeNameController = TextEditingController();
  File? _pickedImage;
  String? _currentAvaUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Lấy dữ liệu cũ điền vào form
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _storeNameController.text = user.storeName ?? "";
      _currentAvaUrl = user.storeAva;
    }
  }

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm lưu dữ liệu
  Future<void> _saveStoreInfo() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user!.uid;

    String? newAvaUrl = _currentAvaUrl;

    try {
      // 1. Nếu có chọn ảnh mới -> Upload lên Storage
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('store_avatars')
            .child('$uid.jpg');
        await ref.putFile(_pickedImage!);
        newAvaUrl = await ref.getDownloadURL();
      }

      // 2. Cập nhật Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'storeName': _storeNameController.text.trim(),
        'storeAva': newAvaUrl,
      });

      // 3. Reload lại AuthProvider để app cập nhật ngay lập tức
      // (Bạn cần đảm bảo AuthProvider có hàm reload hoặc fetchUser)
      // Nếu không có, user cần đăng nhập lại mới thấy thay đổi.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật cửa hàng thành công!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chỉnh sửa Cửa hàng")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Avatar tròn
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_currentAvaUrl != null && _currentAvaUrl!.isNotEmpty
                              ? NetworkImage(_currentAvaUrl!)
                              : null),
                      child: (_pickedImage == null && _currentAvaUrl == null)
                          ? const Icon(Icons.add_a_photo, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Chạm để đổi ảnh đại diện Shop"),
                  const SizedBox(height: 30),

                  // Nhập tên Shop
                  TextField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: "Tên Cửa hàng",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút Lưu
                  ElevatedButton(
                    onPressed: _saveStoreInfo,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}