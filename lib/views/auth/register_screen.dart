import 'package:flutter/material.dart';
import 'package:my_app/enums/password_strength.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// import 'login_screen.dart'; // Import để chuyển trang sau khi đăng ký xong

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Khai báo Form Key để kiểm tra dữ liệu
  final _formKey = GlobalKey<FormState>();

  // 2. Các Controller
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Thêm SĐT
  final _addressController = TextEditingController(); // Thêm Địa chỉ
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Thêm xác nhận mật khẩu
  // strength password
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  double _strengthValue = 0.0;

  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;
  @override
  void dispose() {
    // Giải phóng controller
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // 👉 GIẢI PHÓNG FOCUS NODE (THIẾU DÒNG NÀY)
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  void _checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;

    setState(() {
      _strengthValue = score / 4;

      if (score <= 1) {
        _passwordStrength = PasswordStrength.weak;
      } else if (score <= 3) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  Widget _buildPasswordStrengthIcons() {
    Color color;
    String text;
    int activeLocks;

    switch (_passwordStrength) {
      case PasswordStrength.weak:
        color = Colors.red;
        text = "Mật khẩu yếu";
        activeLocks = 1;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        text = "Mật khẩu trung bình";
        activeLocks = 2;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        text = "Mật khẩu mạnh";
        activeLocks = 3;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                index < activeLocks ? Icons.lock : Icons.lock_outline,
                color: index < activeLocks ? color : Colors.grey[400],
                size: 18,
              ),
            );
          }),
        ),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      // Dùng SingleChildScrollView để cuộn khi bàn phím bật lên
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50.0),

        child: Form(
          key: _formKey, // Gắn key vào Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Tạo tài khoản mới",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 30, 103, 162),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- HỌ TÊN ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 139, 150, 170),
                      width: 0.2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 200, 200, 200),
                    ), // xám nhạt
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  // Viền khi focus
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 114, 162, 233),
                      width: 2,
                    ), // xám đậm hơn chút
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),

                validator: (value) =>
                    value!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 15),

              // --- EMAIL ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 139, 150, 170),
                      width: 0.2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 200, 200, 200),
                    ), // xám nhạt
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  // Viền khi focus
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 114, 162, 233),
                      width: 2,
                    ), // xám đậm hơn chút
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Vui lòng nhập email";
                  // Regex chuẩn cho email
                  bool emailValid = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                  ).hasMatch(value);
                  if (!emailValid) return "Email không đúng định dạng";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- SỐ ĐIỆN THOẠI (Mới) ---
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 139, 150, 170),
                      width: 0.2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 200, 200, 200),
                    ), // xám nhạt
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  // Viền khi focus
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 114, 162, 233),
                      width: 2,
                    ), // xám đậm hơn chút
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                validator: (value) =>
                    value!.length < 9 ? "SĐT không hợp lệ" : null,
              ),
              const SizedBox(height: 15),

              // --- ĐỊA CHỈ (Mới - Quan trọng để mua bán) ---
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: const Icon(Icons.location_on),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 139, 150, 170),
                      width: 0.2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 200, 200, 200),
                    ), // xám nhạt
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  // Viền khi focus
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 114, 162, 233),
                      width: 2,
                    ), // xám đậm hơn chút
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
              ),
              const SizedBox(height: 15),

              // --- MẬT KHẨU ---
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                onChanged: _checkPasswordStrength, // 👈 GẮN VÀO ĐÂY
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFF72A2E9), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Vui lòng nhập mật khẩu";
                  }
                  if (_passwordStrength == PasswordStrength.weak) {
                    return "Mật khẩu quá yếu";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isPasswordFocused
                    ? Container(
                        key: const ValueKey('password-strength'),
                        margin: const EdgeInsets.only(top: 6),
                        child: _buildPasswordStrengthIcons(),
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),

              const SizedBox(height: 10),
              // --- XÁC NHẬN MẬT KHẨU ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_sharp),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFF72A2E9), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text)
                    return "Mật khẩu không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- NÚT ĐĂNG KÝ ---
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // 1. Kiểm tra validator
                        if (_formKey.currentState!.validate()) {
                          try {
                            // 2. Gọi hàm đăng ký với đầy đủ thông tin
                            await authProvider.register(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              _nameController.text.trim(),
                              _phoneController.text.trim(), // Truyền SĐT
                              _addressController.text.trim(), // Truyền Địa chỉ
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đăng ký thành công!'),
                                ),
                              );
                              // Chuyển sang màn hình Home (Vì register xong đã tự login rồi)
                              // Hoặc chuyển về Login tùy logic của bạn
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Lỗi: ${e.toString()}")),
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        'ĐĂNG KÝ NGAY',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
