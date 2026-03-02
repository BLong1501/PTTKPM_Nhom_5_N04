import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy user hiện tại
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập thì báo lỗi nhẹ
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lịch sử hoạt động")),
        body: const Center(child: Text("Vui lòng đăng nhập để xem lịch sử.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Lịch sử đăng nhập",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Sử dụng StreamBuilder để dữ liệu cập nhật Realtime
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activity_logs')
            .orderBy('timestamp', descending: true) // Mới nhất lên đầu
            .limit(50) // Chỉ lấy 50 log gần nhất cho nhẹ
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Trạng thái đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Trạng thái không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Chưa có lịch sử hoạt động nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final logs = snapshot.data!.docs;

          // 3. Hiển thị danh sách
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: logs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              
              // Lấy dữ liệu an toàn (tránh null)
              final String action = data['action'] ?? 'Hoạt động';
              final String deviceName = data['deviceName'] ?? 'Thiết bị không xác định';
              final String timeStr = data['timestamp'] ?? DateTime.now().toIso8601String();
              
              DateTime dateTime;
              try {
                dateTime = DateTime.parse(timeStr);
              } catch (e) {
                dateTime = DateTime.now();
              }

              // Kiểm tra xem đây là hành động Đăng nhập hay Đăng xuất để chọn màu Icon
              final bool isLogin = action.toLowerCase().contains("nhập"); 
              // (Mẹo: kiểm tra chữ "nhập" trong "Đăng nhập")

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isLogin ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  child: Icon(
                    isLogin ? Icons.login : Icons.logout,
                    color: isLogin ? Colors.green : Colors.grey,
                    size: 22,
                  ),
                ),
                title: Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deviceName,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(dateTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(dateTime),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
}