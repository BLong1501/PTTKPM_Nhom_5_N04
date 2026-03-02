import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/notification_service.dart'; // 1. Nhớ Import Service này

class VehicleApprovalTab extends StatelessWidget {
  const VehicleApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        // Lọc ra những xe đang chờ duyệt (status == 'pending')
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 10),
                  Text("Không có xe nào cần duyệt!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index].data() as Map<String, dynamic>;
              final vehicleId = vehicles[index].id;
              
              // Lấy thông tin cần thiết để gửi thông báo
              final String ownerId = vehicle['ownerId']; 
              final String title = vehicle['title'] ?? 'Xe không tên';
              final String price = vehicle['price'].toString(); // Format giá sau nếu cần

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // Phần hiển thị ảnh và thông tin xe (Giữ nguyên UI của bạn)
                    ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(
                                (vehicle['images'] != null && (vehicle['images'] as List).isNotEmpty)
                                    ? vehicle['images'][0]
                                    : 'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Giá: $price đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text("Người đăng: ${ownerId.substring(0, 5)}..."), // Hiển thị tạm ID
                          Text("Ngày đăng: ${_formatDate(vehicle['createdAt'])}"),
                        ],
                      ),
                    ),
                    
                    // NÚT HÀNH ĐỘNG
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          // Nút Từ chối
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                              onPressed: () => _handleReject(context, vehicleId, ownerId, title),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Nút Duyệt
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Duyệt bài", style: TextStyle(color: Colors.white)),
                              onPressed: () => _handleApprove(context, vehicleId, ownerId, title),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  
  // --- HÀM DUYỆT BÀI VÀ GỬI THÔNG BÁO (PHIÊN BẢN HOÀN CHỈNH) ---
  Future<void> _handleApprove(BuildContext context, String vehicleId, String ownerId, String vehicleTitle) async {
    try {
      // 1. Cập nhật trạng thái xe thành 'approved'
      await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
      });

      // 2. Gửi thông báo cho CHỦ XE (Owner)
      await NotificationService().sendNotification(
        receiverId: ownerId,
        title: "Tin đăng đã được duyệt ✅",
        body: "Chiếc xe '$vehicleTitle' của bạn đã được duyệt và hiển thị công khai.",
        type: "approved",
        relatedId: vehicleId,
      );

      // --- 3. GỬI THÔNG BÁO CHO FOLLOWERS (QUÉT CẢ 2 BẢNG) ---
      
      // A. Lấy thông tin chủ xe để lấy tên hiển thị
      String ownerName = "Người bán";
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Ưu tiên lấy tên Shop, nếu không có thì lấy tên hiển thị
        ownerName = (data['storeName'] != null && data['storeName'].toString().isNotEmpty)
            ? data['storeName']
            : (data['displayName'] ?? "Người dùng");
      }

      // B. Lấy danh sách Follower từ CẢ 2 NGUỒN (followers & store_followers)
      // Điều này giải quyết trường hợp Seller nhưng chưa tạo Store
      final List<QuerySnapshot> snapshots = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(ownerId).collection('followers').get(),
        FirebaseFirestore.instance.collection('users').doc(ownerId).collection('store_followers').get(),
      ]);

      // C. Gộp danh sách ID (Dùng Set để loại bỏ trùng lặp)
      Set<String> followerIds = {};
      for (var snap in snapshots) {
        for (var doc in snap.docs) {
          followerIds.add(doc.id);
        }
      }

      // D. Gửi thông báo nếu có người theo dõi
      if (followerIds.isNotEmpty) {
        final List<Future> tasks = followerIds.map((uid) {
          return NotificationService().sendNotification(
            receiverId: uid,
            title: "Tin mới từ $ownerName",
            body: "Vừa đăng bán: $vehicleTitle",
            type: "new_post_following", // Khớp với NotificationScreen
            relatedId: vehicleId,
          );
        }).toList();

        await Future.wait(tasks);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã duyệt và gửi thông báo thành công!"))
        );
      }
    } catch (e) {
      print("Lỗi duyệt bài: $e");
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // --- HÀM 2: XỬ LÝ TỪ CHỐI VÀ GỬI THÔNG BÁO ---
  Future<void> _handleReject(BuildContext context, String vehicleId, String ownerId, String vehicleTitle) async {
    // Hiển thị dialog để nhập lý do từ chối
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Từ chối bài đăng"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Nhập lý do từ chối..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(ctx); // Đóng dialog

              // 1. Cập nhật Firestore: Chuyển status thành 'rejected'
              await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).update({
                'status': 'rejected',
                'rejectionReason': reasonController.text, // Lưu lý do vào xe luôn
              });

              // 2. GỬI THÔNG BÁO TỪ CHỐI
              await NotificationService().sendNotification(
                receiverId: ownerId,
                title: "Tin đăng bị từ chối ❌",
                body: "Xe '$vehicleTitle' bị từ chối. Lý do: ${reasonController.text}",
                type: "rejected", // Loại rejected sẽ hiện icon màu đỏ
                relatedId: vehicleId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối bài đăng.")));
              }
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }
}