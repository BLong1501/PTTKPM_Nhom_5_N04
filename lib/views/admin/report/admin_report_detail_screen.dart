import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/services/notification_service.dart';
// Import màn hình Profile công khai để Admin bấm xem chi tiết người bị tố cáo
import 'package:my_app/views/profile/public_profile_screen.dart'; 

class AdminReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reportData; // Dữ liệu của báo cáo
  final String reportId;                 // ID của báo cáo để cập nhật

  const AdminReportDetailScreen({
    super.key, 
    required this.reportData, 
    required this.reportId
  });

  // --- LOGIC XỬ LÝ ---

  // 1. Hàm cập nhật trạng thái đơn (Chấp nhận hoặc Bác bỏ)
  Future<void> _processReport(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': status,
        'resolvedAt': FieldValue.serverTimestamp(), // Lưu thời gian xử lý
      });
      
      if (context.mounted) {
        Navigator.pop(context); // Quay lại danh sách
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã cập nhật trạng thái: $status"))
        );
      }
    } catch (e) {
      print("Lỗi: $e");
    }
  }

  // 2. Hàm Cấm tài khoản (Ban User)
  Future<void> _banUser(BuildContext context, String userId) async {
    // Cập nhật user thành bị ban
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': true,
      'bannedAt': FieldValue.serverTimestamp(),
    });

    // Đánh dấu đơn này đã giải quyết xong
    await _processReport(context, 'resolved');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã KHÓA TÀI KHOẢN thành công!"))
      );
    }
  }

  // 3. Hàm Cấm đăng bài (Restrict Posting)
  Future<void> _restrictPosting(BuildContext context, String userId) async {
    try {
      // 1. Cập nhật Database
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'canPost': false,
      });

      // 2. Cập nhật trạng thái đơn tố cáo
      await _processReport(context, 'resolved');

      // 🔥 3. GỬI THÔNG BÁO CHO USER (Đây là phần bạn thiếu)
      await NotificationService().sendNotification(
        receiverId: userId,
        title: "Tài khoản bị hạn chế ⚠️",
        body: "Bạn đã bị tạm khóa quyền đăng bài do vi phạm chính sách cộng đồng. Vui lòng liên hệ Admin để biết thêm chi tiết.",
        type: "system", // Hoặc type 'violation_removed' nếu muốn icon búa đỏ
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã CẤM quyền đăng bài và gửi thông báo!")),
        );
      }
    } catch (e) {
      print("Lỗi cấm đăng bài: $e");
    }
  }

  // --- GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    final reportedUserId = reportData['reportedUserId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết vi phạm"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHẦN 1: THÔNG TIN TỐ CÁO
            _buildSectionTitle("NỘI DUNG TỐ CÁO", Colors.red),
            const SizedBox(height: 10),
            _buildInfoRow("Lý do:", reportData['reason']),
            _buildInfoRow("Mô tả thêm:", reportData['description']),
            _buildInfoRow("Xe bị tố:", reportData['vehicleTitle']),
            const SizedBox(height: 15),

            // Ảnh bằng chứng
            if (reportData['evidenceImage'] != null) ...[
              const Text("Bằng chứng hình ảnh:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  reportData['evidenceImage'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Text("Không tải được ảnh")),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // PHẦN 2: THÔNG TIN ĐỐI TƯỢNG BỊ TỐ CÁO
            _buildSectionTitle("ĐỐI TƯỢNG BỊ TỐ CÁO", Colors.blue),
            const SizedBox(height: 10),

            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(reportedUserId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text("Người dùng này không còn tồn tại.");
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(userData['photoUrl'] ?? 'https://via.placeholder.com/150'),
                          ),
                          title: Text(userData['displayName'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(userData['email'] ?? "No Email"),
                        ),
                        const Divider(),
                        
                        // Nút xem Profile chi tiết
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person),
                          label: const Text("Xem trang cá nhân đầy đủ"),
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(
                               builder: (_) => PublicProfileScreen(
                                 userId: reportedUserId, 
                                 forceIndividual: false
                               )
                             ));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const Text("HÀNH ĐỘNG XỬ LÝ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            // CÁC NÚT HÀNH ĐỘNG
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _restrictPosting(context, reportedUserId),
                    child: const Column(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        Text("Cấm đăng bài", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _banUser(context, reportedUserId),
                    child: const Column(
                      children: [
                        Icon(Icons.block, color: Colors.white),
                        Text("KHÓA TÀI KHOẢN", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Nút Bác bỏ (Không vi phạm)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => _processReport(context, 'rejected'),
                child: const Text("Bác bỏ tố cáo (Không vi phạm)", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tiện ích để vẽ tiêu đề
  Widget _buildSectionTitle(String title, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 2)),
      ),
      child: Text(
        title, 
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)
      ),
    );
  }

  // Widget tiện ích vẽ dòng thông tin
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, 
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))
          ),
          Expanded(child: Text(value ?? "---", style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}