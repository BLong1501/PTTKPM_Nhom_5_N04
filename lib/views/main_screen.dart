import 'package:flutter/material.dart';
import 'package:my_app/views/chat/chat_list_screen.dart';
import 'package:my_app/views/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// Import các màn hình con
import 'package:my_app/views/home/home_screen.dart';
// import 'package:my_app/views/chat/chat_list_screen.dart';
import 'package:my_app/views/vehicle/my_post_screen.dart';
import 'package:my_app/views/favourite/favourite_screen.dart';
// import 'package:my_app/views/profile/profile_screen.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart';
// import 'package:my_app/views/auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Tab hiện tại (Mặc định là 0 - Trang chủ)

  // Danh sách các màn hình tương ứng với từng tab
  final List<Widget> _pages = [
    const HomeScreen(),      // Index 0: Trang chủ
    const ChatListScreen(),  // Index 1: Tin nhắn
    const MyPostsScreen(),   // Index 2: Tin của tôi (Chỉ hiện cho Seller)
    const FavoriteScreen(),  // Index 3: Yêu thích
    const ProfileScreen(),   // Index 4: Tài khoản
  ];  

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải thông tin user ngay khi màn hình MainScreen được tạo ra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserData();
    });
  }

  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        final bool isSeller = user != null && (user.role == UserRole.seller || user.role == UserRole.admin);
        if (!isSeller && _currentIndex == 2) {
           // Dùng addPostFrameCallback để tránh lỗi setState trong khi build
           WidgetsBinding.instance.addPostFrameCallback((_) {
             setState(() {
               _currentIndex = 0;
             });
           });
        }
        // Logic kiểm tra để hiện nút: Phải là Seller VÀ đang ở tab Trang chủ (index 0)
        final bool showFab = isSeller && _currentIndex == 0;

        return Scaffold(
          // Hiển thị nội dung trang theo index
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // NÚT ĐĂNG TIN (FAB)
          // Import Firestore

          // NÚT ĐĂNG TIN (FAB)
          floatingActionButton: showFab
              ? SizedBox(
                  height: 65, width: 65,
                  child: FloatingActionButton(
                    backgroundColor: Colors.purple,
                    elevation: 5,
                    shape: const CircleBorder(),
                    // 👇 SỬA ĐOẠN onPressed NÀY
                    onPressed: () async {
                      // 1. Hiện loading để user biết đang xử lý
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 2. Lấy dữ liệu mới nhất từ Firestore (Không lấy từ cache hay provider để đảm bảo chính xác)
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid) // user lấy từ auth provider ở trên
                            .get();

                        // Tắt loading
                        if (context.mounted) Navigator.pop(context);

                        if (userDoc.exists) {
                          final userData = userDoc.data() as Map<String, dynamic>;
                          // Mặc định là true nếu trường này chưa có
                          final bool canPost = userData['canPost'] ?? true; 
                          final bool isBanned = userData['isBanned'] ?? false;

                          // 3. KIỂM TRA QUYỀN
                          if (isBanned) {
                             _showRestrictionDialog(context, "Tài khoản của bạn đã bị KHÓA vĩnh viễn.");
                             return;
                          }

                          if (!canPost) {
                             _showRestrictionDialog(context, "Chức năng đăng bài đang bị tạm khóa do vi phạm tiêu chuẩn cộng đồng.");
                             return;
                          }

                          // 4. NẾU ỔN THÌ MỚI CHO VÀO TRANG ĐĂNG
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                          }
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.pop(context); // Tắt loading nếu lỗi
                        print("Lỗi kiểm tra quyền: $e");
                      }
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                )
              : null,

          // THANH BOTTOM BAR
          bottomNavigationBar: BottomAppBar(
            elevation: 10,
            color: Colors.white,
            shape: null,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomItem(Icons.home, "Trang chủ", 0),
                  _buildBottomItem(Icons.chat_bubble_outline, "Tin nhắn", 1),
                  if (isSeller)
                    _buildBottomItem(Icons.assignment_outlined, "Tin của tôi", 2),
                  _buildBottomItem(Icons.favorite_border, "Yêu thích", 3),
                  _buildBottomItem(Icons.person_outline, "Tài khoản", 4), // Bỏ isLogout: true
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomItem(IconData icon, String label, int index) { // Bỏ tham số isLogout
    final bool isActive = _currentIndex == index;
    
    return InkWell(
      onTap: () {
        // Chỉ đơn giản là chuyển tab
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.purple : Colors.grey),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.purple : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}
// Hàm hiển thị thông báo chặn
  void _showRestrictionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 10),
            Text("Hạn chế quyền", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đã hiểu"),
          ),
        ],
      ),
    );
  }