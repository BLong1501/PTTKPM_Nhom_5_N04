import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/services/notification_service.dart';

class SellerApprovalTab extends StatelessWidget {
  const SellerApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('seller_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 10),
                Text("Không có yêu cầu nâng cấp nào"),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final reqId = requests[index].id;
            final userId = data['uid'];
            
            // Thay vì hiển thị tên Shop, ta hiển thị tên người đăng ký
            final fullName = data['fullName'] ?? 'Người dùng ẩn danh';

            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card: Hiển thị tên người đăng ký
                    Row(
                      children: [
                        const Icon(Icons.person_pin, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Yêu cầu: $fullName", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // Thông tin cá nhân
                    Text("CCCD: ${data['citizenId']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text("SĐT: ${data['phoneNumber'] ?? 'Chưa cập nhật'}"),
                    const SizedBox(height: 10),
                    
                    // Hiển thị 2 ảnh CCCD
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Mặt trước", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 5),
                              _buildImagePreview(data['frontIdUrl']),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Mặt sau", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 5),
                              _buildImagePreview(data['backIdUrl']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Nút Hành Động
                    Row(
                      children: [
                        // Nút Từ chối
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text("Từ chối"),
                            onPressed: () => _rejectRequest(context, reqId, userId, fullName),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nút Duyệt
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Duyệt"),
                            onPressed: () => _approveRequest(context, reqId, userId, fullName),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePreview(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url, 
        height: 100, 
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.error),
      ),
    );
  }

  // --- LOGIC DUYỆT (Đã xóa storeName) ---
  Future<void> _approveRequest(BuildContext context, String reqId, String userId, String fullName) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Cập nhật trạng thái yêu cầu
      batch.update(
        FirebaseFirestore.instance.collection('seller_requests').doc(reqId), 
        {'status': 'approved'}
      );

      // 2. Cập nhật User -> Lên chức Seller
      // Không cập nhật storeName ở đây nữa vì chưa có
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(userId), 
        {
          'role': 'seller', 
          'isPendingUpgrade': false,
        }
      );

      await batch.commit();

      // 3. Gửi thông báo (Nhắc user tạo shop)
      await NotificationService().sendNotification(
        receiverId: userId,
        title: "Hồ sơ đã được duyệt! 🎉",
        body: "Chúc mừng $fullName! Bạn đã trở thành Người bán. Hãy vào mục Tài khoản để thiết lập tên Cửa hàng của bạn ngay.",
        type: "seller_approved", 
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Đã duyệt thành công!")),
        );
      }
    } catch (e) {
      print("Lỗi duyệt seller: $e");
    }
  }

  // --- LOGIC TỪ CHỐI ---
  Future<void> _rejectRequest(BuildContext context, String reqId, String userId, String fullName) async {
    final batch = FirebaseFirestore.instance.batch();
    
    batch.update(FirebaseFirestore.instance.collection('seller_requests').doc(reqId), {'status': 'rejected'});
    batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {'isPendingUpgrade': false});
    
    await batch.commit();

    // Thông báo lý do chung chung hoặc có thể mở dialog nhập lý do nếu muốn kỹ hơn
    await NotificationService().sendNotification(
      receiverId: userId,
      title: "Đăng ký Người bán thất bại ❌",
      body: "Hồ sơ của bạn chưa đạt yêu cầu (Ảnh mờ hoặc thông tin không khớp). Vui lòng thử lại.",
      type: "seller_rejected", 
    );

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Đã từ chối hồ sơ của $fullName")),
       );
    }
  }
}