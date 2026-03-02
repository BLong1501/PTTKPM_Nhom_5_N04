import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/views/log/user_log_screen.dart';
import 'package:my_app/views/profile/setting_screen.dart';
import 'package:my_app/views/profile/update_seller_screen.dart';
import 'package:my_app/views/profile/user_follow_list_screen.dart';
import 'package:my_app/views/seller/seller_info_screen.dart';
import 'package:my_app/views/seller/seller_state_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool forceIndividual; // 1. 👇 Thêm dòng này
  const ProfileScreen({super.key, this.forceIndividual = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading =
      false; // Biến trạng thái để hiện vòng xoay khi đang up ảnh

  // --- HÀM 1: CHỌN ẢNH VÀ UPLOAD ---
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    // 1. Mở thư viện ảnh
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return; // Nếu user hủy chọn

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      File file = File(image.path);

      // 2. Upload lên Firebase Storage
      // Tạo đường dẫn: user_avatars/uid.jpg
      final ref = FirebaseStorage.instance.ref().child(
        'user_avatars/${user.uid}.jpg',
      );
      await ref.putFile(file);

      // 3. Lấy link ảnh về
      final String downloadUrl = await ref.getDownloadURL();

      // 4. Cập nhật Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': downloadUrl},
      );

      // 5. Cập nhật Provider để UI đổi ngay lập tức
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // --- HÀM 2: HIỆN HỘP THOẠI ĐỔI TÊN ---
  void _showEditNameDialog(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đổi tên hiển thị"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Tên mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);

              // Cập nhật tên
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'displayName': nameController.text.trim()});
                // Load lại data
                if (context.mounted) {
                  Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).fetchUserData();
                }
              } catch (e) {
                // Xử lý lỗi
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.user;

    if (userModel == null)
      return const Center(child: CircularProgressIndicator());
    bool isStore = false;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        // 👇 DÙNG CUSTOM SCROLL VIEW ĐỂ CÓ HIỆU ỨNG TRƯỢT APPBAR
        slivers: [
          SliverAppBar(
            title: const Text(
              "Hồ sơ cá nhân",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,

            // 👇 CẤU HÌNH HIỆU ỨNG TRƯỢT
            floating: true, // Vuốt nhẹ lên là hiện lại ngay
            snap: true, // Hiện dứt khoát
            pinned:
                false, // false: Trượt mất hẳn | true: Giữ lại thanh bar dính trên cùng

            expandedHeight:
                60.0, // Chiều cao mở rộng (nếu muốn làm ảnh nền to thì tăng lên)
            backgroundColor: Colors.transparent, // Để lộ gradient bên dưới
            elevation: 4,
            automaticallyImplyLeading: false,

            // Nút Edit tên
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                onPressed: () =>
                    _showEditNameDialog(context, userModel.displayName),
              ),
            ],

            // Màu nền Gradient
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 👇 NỘI DUNG CHÍNH CỦA TRANG PROFILE
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- 1. AVATAR & TÊN ---
                Center(
                  child: Column(
                    children: [
                      // Stack Avatar
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.2),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  (userModel.photoUrl != null &&
                                      userModel.photoUrl!.isNotEmpty)
                                  ? NetworkImage(userModel.photoUrl!)
                                  : null,
                              child:
                                  (userModel.photoUrl == null ||
                                      userModel.photoUrl!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          // Nút Camera nhỏ
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploading ? null : _pickAndUploadAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userModel.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userModel.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. THỐNG KÊ FOLLOW ---
                // --- 2. THỐNG KÊ FOLLOW ---
                // --- 2. THỐNG KÊ FOLLOW (CÁ NHÂN) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Đang theo dõi
                      _buildStatItem("Đang theo dõi", userModel.following, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserFollowListScreen(
                              userId: userModel.uid,
                              initialTabIndex: 0,
                            ),
                          ),
                        );
                      }),

                      Container(height: 30, width: 1, color: Colors.grey[300]),

                      // 👇 SỬA LẠI: Luôn lấy userModel.followers (Follow cá nhân)
                      _buildStatItem("Người theo dõi", userModel.followers, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserFollowListScreen(
                              userId: userModel.uid,
                              initialTabIndex: 1, // Tab người theo dõi
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 5, color: Color(0xFFF5F5F5)),

                // --- 3. MENU CHỨC NĂNG ---
                _buildSectionTitle("Cài đặt & Tiện ích"),

                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: "Cài đặt tài khoản",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: userModel.role.name == 'seller'
                      ? Icons.storefront
                      : Icons.add_business,
                  title: userModel.role.name == 'seller'
                      ? 'Thông tin người bán'
                      : 'Đăng ký bán hàng',
                  onTap: () {
                    if (userModel.role.name == 'seller') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerInfoScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpgradeSellerScreen(),
                        ),
                      );
                    }
                  },
                ),

                _buildMenuItem(
                  icon: Icons.history,
                  title: "Lịch sử đăng nhập",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActivityLogScreen(),
                      ),
                    );
                  },
                ),

                _buildSectionTitle("Hỗ trợ"),
                // Kiểm tra nếu là Seller thì mới hiện nút Thống kê
                if (userModel.role.name == 'seller')
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    title: "Thống kê doanh thu",
                    onTap: () {
                      // Nhớ import file seller_stats_screen.dart ở đầu file
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerStatsScreen(),
                        ),
                      );
                    },
                  ),
                _buildMenuItem(
                  icon: Icons.feedback_outlined,
                  title: "Đóng góp ý kiến",
                  onTap: () {
                    /* ... */
                  },
                ),

                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: "Trợ giúp & Hỗ trợ",
                  onTap: () {
                    /* ... */
                  },
                ),

                const SizedBox(height: 10),

                // Nút Đăng xuất
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Đăng xuất",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          122,
                          40,
                          199,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ), // Khoảng trống cuối cùng để cuộn thoải mái
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị số liệu Follow
  // 👇 SỬA HÀM NÀY: Thêm tham số onTap
  Widget _buildStatItem(String label, int count, VoidCallback onTap) {
    return InkWell(
      // Bọc bằng InkWell để có hiệu ứng gợn sóng khi ấn
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // Tăng vùng bấm cho dễ
        child: Column(
          children: [
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tiêu đề mục nhỏ
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // Widget từng dòng menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: Colors.purple, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
