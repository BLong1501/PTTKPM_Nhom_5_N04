import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/views/admin/user/admin_user_profile_screen.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _isLoading = false;

  // --- 1. LOGIC CẬP NHẬT TRẠNG THÁI (Giữ nguyên) ---
  Future<void> _updateUserStatus({
    required String field, 
    required bool value, 
    required String confirmTitle,
    required String confirmContent,
    required String successMsg,
    required String notifTitle,
    required String notifBody,
    String notifType = "system"
  }) async {
    // ... (Giữ nguyên logic cũ của hàm này)
    // Để tiết kiệm không gian tôi không paste lại toàn bộ hàm này, bạn giữ nguyên như cũ nhé.
    // Nếu bạn cần tôi paste lại thì báo tôi.
     bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: value ? Colors.red : Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({field: value});
      await NotificationService().sendNotification(
        receiverId: widget.userId, title: notifTitle, body: notifBody, type: notifType,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIC ĐỔI MẬT KHẨU (Reset Password) ---
  // Lưu ý: Firebase Admin SDK mới có quyền set password trực tiếp. 
  // Ở Client SDK, chúng ta chỉ có thể gửi email reset password.
  Future<void> _sendPasswordResetEmail(String email) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gửi email đổi mật khẩu?"),
        content: Text("Một email hướng dẫn đặt lại mật khẩu sẽ được gửi đến $email."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Gửi ngay")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi email khôi phục!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }
  // 4. LOGIC XÓA TÀI KHOẢN (Xóa dữ liệu Firestore)
  Future<void> _deleteUserPermanently() async {
    // Cảnh báo cực mạnh
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("XÓA VĨNH VIỄN USER?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "Hành động này sẽ xóa toàn bộ thông tin cá nhân của người dùng khỏi cơ sở dữ liệu.\n\n"
          "Lưu ý: User vẫn tồn tại trong Authentication (cần xóa thủ công trên web Firebase) nhưng họ sẽ không thể đăng nhập vào App được nữa vì mất dữ liệu.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận XÓA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1. Xóa trong Collection 'users'
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
      
      // 2. (Tùy chọn) Xóa các bài đăng xe của user này để sạch data
      var vehicles = await FirebaseFirestore.instance.collection('vehicles').where('ownerId', isEqualTo: widget.userId).get();
      for (var doc in vehicles.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa dữ liệu người dùng thành công!")));
        Navigator.pop(context); // Thoát khỏi màn hình chi tiết
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 3. LOGIC SỬA THÔNG TIN CÁ NHÂN ---
  void _showEditProfileDialog(Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['displayName']);
    final phoneController = TextEditingController(text: userData['phoneNumber'] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chỉnh sửa thông tin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Họ tên")),
            const SizedBox(height: 10),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Số điện thoại")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                  'displayName': nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
              } catch (e) {
                print(e);
              } finally {
                if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết Người dùng"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User not found"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final String email = data['email'] ?? "---";
          final String name = data['displayName'] ?? "No Name";
          final String? photoUrl = data['photoUrl'];
          final String role = data['role'] ?? "user"; // 'admin', 'seller', 'user'
          final bool isBanned = data['isBanned'] ?? false;
          final bool canPost = data['canPost'] ?? true;
          
          // Xử lý ngày tạo (String hoặc Timestamp)
          Timestamp? createdAt;
          final dynamic rawCreated = data['createdAt'];
          if (rawCreated is Timestamp) createdAt = rawCreated;
          else if (rawCreated is String) try { createdAt = Timestamp.fromDate(DateTime.parse(rawCreated)); } catch (_) {}

          // Kiểm tra xem user này có phải là Admin không
          final bool isTargetAdmin = role == 'admin';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. HEADER PROFILE (Avatar + Tên)
                // ... (Giữ nguyên code UI phần Header)
                 CircleAvatar(
  radius: 50,
  // SỬA LẠI DÒNG NÀY: Phải khác null VÀ không được rỗng
  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
      ? NetworkImage(photoUrl) 
      : null,
  
  backgroundColor: Colors.grey[300],
  
  // SỬA LẠI DÒNG NÀY: Nếu null HOẶC rỗng thì hiện Icon
  child: (photoUrl == null || photoUrl.isEmpty) 
      ? const Icon(Icons.person, size: 50, color: Colors.grey) 
      : null,
),
                const SizedBox(height: 15),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTargetAdmin ? Colors.red[100] : (role == 'seller' ? Colors.purple[100] : Colors.blue[100]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Vai trò: ${role.toUpperCase()}", style: TextStyle(color: isTargetAdmin ? Colors.red : (role == 'seller' ? Colors.purple : Colors.blue), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),

                // 2. THÔNG TIN & TRẠNG THÁI
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatusRow("Ngày tạo:", createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt.toDate()) : "---"),
                        const Divider(),
                        _buildStatusRow("Trạng thái:", isBanned ? "ĐANG BỊ KHÓA" : "Hoạt động", isRed: isBanned),
                        // Chỉ hiện dòng này nếu KHÔNG phải là Admin
                        if (!isTargetAdmin) ...[
                           const Divider(),
                           _buildStatusRow("Quyền đăng bài:", canPost ? "Được phép" : "BỊ CẤM", isRed: !canPost),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 3. CÁC NÚT HÀNH ĐỘNG
                const Text("QUẢN TRỊ VIÊN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 15),

                if (_isLoading) const CircularProgressIndicator() else Column(
                  children: [
                    // Hàng 1: Xem Profile & Sửa thông tin
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: const Text("Xem Profile"),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserProfileScreen(userId: widget.userId))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Sửa Info"),
                            onPressed: () => _showEditProfileDialog(data),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Hàng 2: Đổi mật khẩu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        icon: const Icon(Icons.lock_reset, color: Colors.white),
                        label: const Text("Gửi Email Đổi Mật Khẩu", style: TextStyle(color: Colors.white)),
                        onPressed: () => _sendPasswordResetEmail(email),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    const Divider(),
                    const SizedBox(height: 10),

                    // Hàng 3: Cấm & Khóa (Vùng nguy hiểm)
                    Row(
                      children: [
                        // Nút CẤM ĐĂNG BÀI (Chỉ hiện nếu KHÔNG phải Admin)
                        if (!isTargetAdmin) 
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canPost ? Colors.orange : Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              icon: Icon(canPost ? Icons.post_add : Icons.check, color: Colors.white),
                              label: Text(canPost ? "Cấm đăng" : "Cho đăng", style: const TextStyle(color: Colors.white)),
                              onPressed: () => _updateUserStatus(
                                field: 'canPost', value: !canPost,
                                confirmTitle: canPost ? "Cấm đăng bài?" : "Khôi phục quyền?",
                                confirmContent: "Hành động này sẽ ảnh hưởng đến quyền đăng tin.",
                                successMsg: "Đã cập nhật.", notifTitle: "Thông báo quyền đăng tin", notifBody: "Trạng thái đăng tin của bạn đã thay đổi."
                              ),
                            ),
                          ),
                        
                        if (!isTargetAdmin) const SizedBox(width: 10),

                        // Nút KHÓA TÀI KHOẢN (Luôn hiện, kể cả Admin cũng có thể bị khóa bởi Admin cấp cao hơn)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBanned ? Colors.green : Colors.red[900],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: Colors.white),
                            label: Text(isBanned ? "Mở khóa" : "Khóa TK", style: const TextStyle(color: Colors.white)),
                            onPressed: () => _updateUserStatus(
                                field: 'isBanned', value: !isBanned,
                                confirmTitle: isBanned ? "Mở khóa?" : "Khóa tài khoản?",
                                confirmContent: "Người dùng sẽ bị đăng xuất.",
                                successMsg: "Đã cập nhật.", notifTitle: "Thông báo tài khoản", notifBody: "Trạng thái tài khoản đã thay đổi.", notifType: "account_banned"
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                // ... (Đoạn code các nút Cấm/Khóa cũ) ...
                    
                    const SizedBox(height: 20),
                    const Divider(thickness: 2, color: Colors.red),
                    
                    // NÚT XÓA VĨNH VIỄN
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.delete_forever, size: 28),
                        label: const Text("XÓA TÀI KHOẢN VĨNH VIỄN", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _deleteUserPermanently,
                      ),
                    ),
                    const SizedBox(height: 30),
                
              ],
              
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black)),
        ],
      ),
    );
  }
}