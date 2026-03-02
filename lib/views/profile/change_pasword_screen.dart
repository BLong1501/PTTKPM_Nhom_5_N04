import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart'; // Import màn hình đăng nhập để navigate về

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Biến cho độ mạnh mật khẩu (0.0 đến 1.0)
  double _strength = 0;
  String _strengthText = "";
  Color _strengthColor = Colors.grey;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- HÀM KIỂM TRA ĐỘ MẠNH MẬT KHẨU ---
  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.isEmpty) {
      strength = 0;
    } else if (password.length < 6) {
      strength = 0.1; // Rất yếu
    } else {
      strength += 0.2; // Độ dài cơ bản ok
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2; // Có chữ hoa
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2; // Có số
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2; // Có ký tự đặc biệt
      if (password.length >= 8) strength += 0.2; // Dài trên 8 ký tự
    }

    setState(() {
      _strength = strength;
      if (_strength <= 0.3) {
        _strengthText = "Mật khẩu yếu";
        _strengthColor = Colors.red;
      } else if (_strength <= 0.7) {
        _strengthText = "Mật khẩu trung bình";
        _strengthColor = Colors.orange;
      } else {
        _strengthText = "Mật khẩu mạnh";
        _strengthColor = Colors.green;
      }
    });
  }

  // --- HÀM XỬ LÝ ĐỔI MẬT KHẨU ---
  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Kiểm tra độ mạnh bắt buộc (Ví dụ: Phải từ trung bình trở lên mới cho đổi)
    if (_strength < 0.4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn!")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 1. Gọi hàm đổi mật khẩu
      await authProvider.changePassword(
        _oldPassController.text.trim(),
        _newPassController.text.trim(),
      );

      if (!mounted) return;

      // 2. Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công! Vui lòng đăng nhập lại."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 3. Đăng xuất và đá về màn hình Login
      await authProvider.logout();

      if (!mounted) return;
      
      // Xóa hết lịch sử nav và về Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tạo mật khẩu mới",
                
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Mật khẩu mới của bạn phải khác với mật khẩu cũ."),
              const SizedBox(height: 30),

              // 1. Mật khẩu cũ
              TextFormField(
                controller: _oldPassController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập mật khẩu cũ" : null,
              ),
              const SizedBox(height: 20),

              // 2. Mật khẩu mới (Có check độ mạnh)
              TextFormField(
                controller: _newPassController,
                obscureText: _obscureNew,
                onChanged: _checkPasswordStrength, // Gọi hàm check mỗi khi gõ
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val!.isEmpty) return "Vui lòng nhập mật khẩu mới";
                  if (val.length < 6) return "Mật khẩu phải từ 6 ký tự";
                  return null;
                },
              ),
              
              // 3. Thanh hiển thị độ mạnh
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _strength,
                backgroundColor: Colors.grey[300],
                color: _strengthColor,
                minHeight: 5,
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _strengthText,
                  style: TextStyle(color: _strengthColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Nhập lại mật khẩu mới
              TextFormField(
                controller: _confirmPassController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu mới",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val != _newPassController.text) return "Mật khẩu xác nhận không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // 5. Nút xác nhận
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _handleChangePassword,
                  child: const Text(
                    "ĐỔI MẬT KHẨU",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}