import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDialogs {
  // Hàm static để gọi trực tiếp không cần khởi tạo class
  static void showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Quên mật khẩu?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập email để nhận link đặt lại mật khẩu:"),
            const SizedBox(height: 10),
            TextFormField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                prefixIcon: Icon(Icons.email, color: Colors.lightBlueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;

              // Đóng hộp thoại trước cho mượt
              Navigator.pop(ctx);

              try {
                // Gọi hàm logic từ AuthProvider (đã tách ở Bước 1)
                await Provider.of<AuthProvider>(context, listen: false)
                    .sendPasswordReset(resetEmailController.text.trim());

                // Hiện thông báo thành công
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã gửi link vào email! Hãy kiểm tra hộp thư."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Hiện thông báo lỗi
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Lỗi: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Gửi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}