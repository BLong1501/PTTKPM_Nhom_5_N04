import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/admin_screen.dart'; // Đảm bảo đúng tên file Admin của bạn
import 'package:my_app/views/auth/login_screen.dart';
import 'package:my_app/views/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart' as my_auth;

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lắng nghe trạng thái đăng nhập Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang kết nối tới Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Chưa đăng nhập -> Về Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Đã đăng nhập -> Lấy UID
        final User user = snapshot.data!;

        // 2. Kích hoạt Provider lắng nghe dữ liệu (Để dùng cho toàn app sau này)
        // Dùng addPostFrameCallback để tránh lỗi vẽ lại widget trong khi đang build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
          if (authProvider.user == null) {
             authProvider.startListeningToUserData();
          }
        });

        // 3. Lắng nghe trực tiếp Firestore để điều hướng (Nhanh hơn chờ Provider)
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              // Có Auth nhưng không có data trong Firestore -> Lỗi dữ liệu -> Logout
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            // Lấy role từ Firestore
            final userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
            final String role = userData['role'] ?? 'user';

            // 4. Điều hướng
            if (role == 'admin') {
              return const AdminScreen();
            } else {
              return const MainScreen();
            }
          },
        );
      },
    );
  }
}