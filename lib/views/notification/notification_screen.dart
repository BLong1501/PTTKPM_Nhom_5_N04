import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/notification_model.dart';
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/views/profile/seller_result_screen.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import 'package:my_app/views/profile/seller_result_screen.dart';
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notifService = NotificationService();

    if (user == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có thông báo nào"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Convert dữ liệu sang Model
              final notification = NotificationModel.fromFirestore(docs[index]);

              return Container(
                color: notification.isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  leading: _buildIcon(notification.type),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: columDetail(notification),
                  onTap: () {
                    // 1. Đánh dấu đã đọc
                    notifService.markAsRead(notification.id);

                    // 2. Xử lý sự kiện bấm (Mở màn hình tương ứng)
                    _handleNavigation(context, notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget columDetail(NotificationModel notif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Text(
          DateFormat('HH:mm dd/MM/yyyy').format(notif.createdAt),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildIcon(String type) {
    switch (type) {
      case 'approved': return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected': return const Icon(Icons.cancel, color: Colors.orange);
      case 'account_banned': return const Icon(Icons.block, color: Colors.red);
      case 'new_post_following': return const Icon(Icons.rss_feed, color: Colors.blue);
      case 'violation_removed': return const Icon(Icons.gavel, color: Colors.red);
      
      // 👇 THÊM DÒNG NÀY: Icon cho thông báo hệ thống
      case 'system': return const Icon(Icons.campaign, color: Colors.blueAccent); 
      
      case 'seller_approved': return const Icon(Icons.verified, color: Colors.purple); // (Tùy chọn thêm)
      case 'seller_rejected': return const Icon(Icons.running_with_errors, color: Colors.orange); // (Tùy chọn thêm)
      
      default: return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  // Hàm xử lý khi ấn vào thông báo
 // Hàm xử lý khi ấn vào thông báo
  void _handleNavigation(BuildContext context, NotificationModel notif) async {
    // 👇 1. XỬ LÝ THÔNG BÁO HỆ THỐNG (ADMIN GỬI) 👇
    if (notif.type == 'system') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          // Tiêu đề có icon loa cho đẹp
          title: Row(
            children: [
              const Icon(Icons.campaign, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notif.title, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                )
              ),
            ],
          ),
          // Nội dung tin nhắn
          content: SingleChildScrollView(
            child: Text(
              notif.body,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
      return; // Dừng lại, không chạy code phía dưới
    }
    
    // --- 1. XỬ LÝ NÂNG CẤP SELLER (MỚI THÊM) ---
    
    // Nếu được duyệt làm Seller -> Mở màn hình Chúc mừng
    if (notif.type == 'seller_approved') {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => const SellerSuccessScreen())
      );
      return; // Dừng hàm, không chạy các đoạn dưới nữa
    }

    // Nếu bị từ chối làm Seller -> Mở màn hình Thất bại
    if (notif.type == 'seller_rejected') {
      Navigator.push(
        context, 
        MaterialPageRoute(
          // Truyền nội dung body của thông báo (lý do từ chối) sang màn hình đỏ
          builder: (_) => SellerRejectionScreen(reason: notif.body)
        )
      );
      return;
    }

    // --- 2. XỬ LÝ DUYỆT XE / FOLLOW (GIỮ NGUYÊN CODE CŨ) ---

    // Trường hợp: Tin đăng xe được duyệt HOẶC Người mình follow đăng bài mới
    if ((notif.type == 'approved' || notif.type == 'new_post_following') && notif.relatedId != null) {
      
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(notif.relatedId)
            .get();

        if (context.mounted) Navigator.pop(context); // Tắt loading

        if (doc.exists) {
          VehicleModel vehicle = VehicleModel.fromSnapshot(doc);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bài đăng này không còn tồn tại!")),
            );
          }
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        print("Lỗi tải xe: $e");
      }
    } 
    
    // --- 3. XỬ LÝ CÁC LOẠI KHÁC ---
    
    // Thông báo xe bị từ chối hoặc vi phạm
    else if (notif.type == 'rejected' || notif.type == 'violation_removed') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(notif.title),
          content: Text(notif.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đã hiểu"),
            ),
          ],
        ),
      );
    }
  }
}