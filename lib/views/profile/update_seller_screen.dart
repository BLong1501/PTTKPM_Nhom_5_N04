import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpgradeSellerScreen extends StatefulWidget {
  const UpgradeSellerScreen({super.key});

  @override
  State<UpgradeSellerScreen> createState() => _UpgradeSellerScreenState();
}

class _UpgradeSellerScreenState extends State<UpgradeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _citizenIdController = TextEditingController();
  // Đã xóa _storeNameController
  final _addressController = TextEditingController();

  // Biến lưu ảnh
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _citizenIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh
  Future<void> _pickImage(bool isFront) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isPending = user?.isPendingUpgrade ?? false;

    // Nếu đang chờ duyệt thì hiện thông báo
    if (isPending) {
      return Scaffold(
        appBar: AppBar(title: const Text("Trạng thái hồ sơ")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text("Hồ sơ đang được xét duyệt!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Admin đang kiểm tra thông tin CCCD của bạn.\nQuá trình này có thể mất 24h.", textAlign: TextAlign.center),
              ),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại"))
            ],
          ),
        ),
      );
    }

    // Giao diện điền Form
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký Người bán"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thông tin định danh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              
              _buildTextField("Họ và tên thật (Trên CCCD)", _fullNameController, Icons.person),
              _buildTextField("Số CCCD / CMND", _citizenIdController, Icons.badge, isNumber: true),
              
              const SizedBox(height: 20),
              // Đổi tên tiêu đề cho hợp lý
              const Text("Thông tin liên hệ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              
              // Đã xóa ô nhập Tên cửa hàng
              _buildTextField("Địa chỉ thường trú / Kinh doanh", _addressController, Icons.location_on),

              const SizedBox(height: 20),
              const Text("Xác thực hình ảnh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const Text("Vui lòng chụp rõ nét 2 mặt CCCD", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),

              // Khu vực chọn ảnh
              Row(
                children: [
                  Expanded(child: _buildImagePicker(true, "Mặt trước")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildImagePicker(false, "Mặt sau")),
                ],
              ),

              const SizedBox(height: 30),
              
              // Nút Gửi
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_frontImage == null || _backImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Vui lòng chọn đủ 2 ảnh CCCD")),
                              );
                              return;
                            }

                            try {
                              // CẬP NHẬT HÀM GỌI (Bỏ storeName)
                              await authProvider.submitSellerRequest(
                                fullName: _fullNameController.text.trim(),
                                citizenId: _citizenIdController.text.trim(),
                                // storeName: _storeNameController.text.trim(), // <-- ĐÃ XÓA
                                address: _addressController.text.trim(),
                                frontImage: _frontImage,
                                backImage: _backImage,
                              );
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi hồ sơ thành công!")));
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                              }
                            }
                          }
                        },
                        child: const Text("GỬI HỒ SƠ XÉT DUYỆT", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        validator: (value) => value!.isEmpty ? "Vui lòng nhập thông tin này" : null,
      ),
    );
  }

  Widget _buildImagePicker(bool isFront, String label) {
    File? imageFile = isFront ? _frontImage : _backImage;
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[400]!),
          image: imageFile != null 
            ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
            : null,
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.grey),
                  const SizedBox(height: 5),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              )
            : null,
      ),
    );
  }
}