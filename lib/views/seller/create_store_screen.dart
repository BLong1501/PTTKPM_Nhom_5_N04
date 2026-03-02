import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Thiết lập cửa hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thông tin cửa hàng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Hãy điền thông tin để khách hàng tìm thấy bạn", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              _buildTextField("Tên Cửa hàng", _nameController, Icons.store),
              _buildTextField("Địa chỉ kinh doanh", _addressController, Icons.location_on),
              _buildTextField("Mô tả cửa hàng", _descController, Icons.info, maxLines: 3),

              const SizedBox(height: 30),

              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await authProvider.createStore(
                                storeName: _nameController.text.trim(),
                                address: _addressController.text.trim(),
                                description: _descController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context); // Đóng màn hình tạo
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tạo cửa hàng thành công!")));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                            }
                          }
                        },
                        child: const Text("HOÀN TẤT TẠO CỬA HÀNG"),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) => val!.isEmpty ? "Vui lòng nhập" : null,
      ),
    );
  }
}