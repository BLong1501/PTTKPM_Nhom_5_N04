import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/views/profile/change_pasword_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller cho thông tin cơ bản
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _phoneController = TextEditingController(text: user?.phoneNumber ?? "");
    _addressController = TextEditingController(text: user?.address ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm xử lý Lưu thông tin
  void _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateUserProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        newAvatar: _pickedImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Hàm hiển thị Dialog đổi mật khẩu
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Đổi mật khẩu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: "Mật khẩu cũ"),
              ),
              TextField(
                controller: newPassController,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: "Mật khẩu mới"),
              ),
              TextField(
                controller: confirmPassController,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: "Nhập lại mật khẩu mới"),
              ),
              Row(
                children: [
                  Checkbox(
                    value: !obscure,
                    onChanged: (val) => setStateDialog(() => obscure = !val!),
                  ),
                  const Text("Hiện mật khẩu")
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text != confirmPassController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mật khẩu mới không khớp!")));
                  return;
                }
                if (newPassController.text.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mật khẩu phải từ 6 ký tự!")));
                   return;
                }

                try {
                  Navigator.pop(context); // Đóng dialog trước
                  // Gọi Provider
                  await Provider.of<AuthProvider>(context, listen: false)
                      .changePassword(oldPassController.text, newPassController.text);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt tài khoản"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- PHẦN 1: ẢNH ĐẠI DIỆN ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!) as ImageProvider
                                : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                                    ? NetworkImage(user.photoUrl!)
                                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider), // Nhớ thêm ảnh default vào assets
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.orange,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- PHẦN 2: FORM NHẬP LIỆU ---
                    _buildTextField("Họ và tên", _nameController, Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField("Số điện thoại", _phoneController, Icons.phone, inputType: TextInputType.phone),
                    const SizedBox(height: 15),
                    _buildTextField("Địa chỉ", _addressController, Icons.location_on),
                    
                    const SizedBox(height: 15),
                    // Email (Read-only)
                    TextFormField(
                      initialValue: user.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email (Không thể thay đổi)",
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFEEEEEE),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- PHẦN 3: ĐỔI MẬT KHẨU ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset, color: Colors.orange),
                        label: const Text("Đổi mật khẩu", style: TextStyle(color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                       onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                          );
                        },
                      ),
                    ),
                      
                    
                    
                    const SizedBox(height: 20),

                    // --- NÚT LƯU ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: authProvider.isLoading ? null : _handleUpdateProfile,
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: (value) => value == null || value.isEmpty ? "Vui lòng nhập $label" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}