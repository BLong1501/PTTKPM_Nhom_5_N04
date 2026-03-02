import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Đảm bảo đã có intl trong pubspec.yaml
import 'package:my_app/services/data_seeder.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/views/admin/tabs/admin_stats_screen.dart';
import 'package:my_app/views/admin/tabs/user_management_screen.dart';
import 'package:my_app/views/admin/request_management_screen.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    UserManagementTab(),
    RequestManagementScreen(),
    AdminStatsScreen(),
    const Center(child: Text("Màn hình Cấu Hình (Đang phát triển)")),
  ];

  final List<String> _titles = [
    "Quản lý Người dùng",
    "Quản lý Yêu cầu & Duyệt",
    "Thống kê Báo cáo",
    "Cấu hình Hệ thống"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: "Gửi thông báo hệ thống",
            onPressed: () => _showBroadcastDialog(context),
          ),
          // ... (Các nút Data Seeder và Logout giữ nguyên)
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => _confirmSeedData(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueGrey[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Người dùng"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: "Xét duyệt"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Thống kê"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Cấu hình"),
        ],
      ),
    );
  }

  // --- 🔥 HÀM GỬI THÔNG BÁO NÂNG CAO ---
  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    
    // Các biến trạng thái cho Dialog
    bool isSendToAll = true;       // Mặc định gửi tất cả
    String? selectedUserId;        // ID người nhận cụ thể
    DateTime? scheduledTime;       // Thời gian hẹn giờ (null = gửi ngay)

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc bấm nút mới tắt
      builder: (ctx) {
        // StatefulBuilder giúp cập nhật giao diện bên trong Dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Tạo thông báo mới"),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. NHẬP NỘI DUNG
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Tiêu đề",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bodyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Nội dung",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.message),
                        ),
                      ),
                      
                      const Divider(height: 30),

                      // 2. CHỌN NGƯỜI NHẬN
                      const Text("Người nhận:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: isSendToAll,
                            onChanged: (val) => setStateDialog(() => isSendToAll = val!),
                          ),
                          const Text("Tất cả"),
                          const SizedBox(width: 15),
                          Radio<bool>(
                            value: false,
                            groupValue: isSendToAll,
                            onChanged: (val) => setStateDialog(() => isSendToAll = val!),
                          ),
                          const Text("Chọn người dùng"),
                        ],
                      ),

                      // Dropdown chọn user (chỉ hiện khi không chọn Tất cả)
                      if (!isSendToAll)
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('users').get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            
                            // Tạo danh sách Dropdown
                            final users = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: selectedUserId,
                              decoration: const InputDecoration(
                                labelText: "Chọn user",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                              isExpanded: true,
                              items: users.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['displayName'] ?? data['storeName'] ?? doc.id;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(
                                    name, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setStateDialog(() => selectedUserId = val),
                            );
                          },
                        ),

                      const Divider(height: 30),

                      // 3. HẸN GIỜ GỬI
                      const Text("Thời gian gửi:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_today, 
                          color: scheduledTime == null ? Colors.grey : Colors.green
                        ),
                        title: Text(
                          scheduledTime == null 
                              ? "Gửi ngay lập tức" 
                              : "Hẹn giờ: ${DateFormat('HH:mm dd/MM/yyyy').format(scheduledTime!)}",
                          style: TextStyle(
                            color: scheduledTime == null ? Colors.black : Colors.green[700],
                            fontWeight: scheduledTime == null ? FontWeight.normal : FontWeight.bold
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            // Chọn Ngày
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date == null) return;

                            // Chọn Giờ
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time == null) return;

                            // Gộp lại
                            setStateDialog(() {
                              scheduledTime = DateTime(
                                date.year, date.month, date.day, time.hour, time.minute
                              );
                            });
                          },
                          child: const Text("Thay đổi"),
                        ),
                      ),
                      if (scheduledTime != null)
                        TextButton.icon(
                          onPressed: () => setStateDialog(() => scheduledTime = null),
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          label: const Text("Hủy hẹn giờ (Gửi ngay)", style: TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy"),
                ),
                ElevatedButton.icon(
                  icon: Icon(scheduledTime == null ? Icons.send : Icons.schedule),
                  label: Text(scheduledTime == null ? "Gửi Ngay" : "Lên Lịch"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheduledTime == null ? Colors.blue : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tiêu đề và nội dung")));
                      return;
                    }
                    if (!isSendToAll && selectedUserId == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn người nhận")));
                      return;
                    }

                    Navigator.pop(ctx); // Đóng Dialog

                    // --- XỬ LÝ GỬI ---
                    if (scheduledTime != null) {
                      // TRƯỜNG HỢP 1: HẸN GIỜ (Lưu vào DB để Cloud Function xử lý)
                      await FirebaseFirestore.instance.collection('scheduled_notifications').add({
                        'title': "[HỆ THỐNG] ${titleController.text}",
                        'body': bodyController.text,
                        'targetUserId': isSendToAll ? 'ALL' : selectedUserId,
                        'scheduledAt': scheduledTime,
                        'status': 'pending', // pending -> sent
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đã lên lịch gửi vào ${DateFormat('HH:mm dd/MM').format(scheduledTime!)}"))
                        );
                      }

                    } else {
                      // TRƯỜNG HỢP 2: GỬI NGAY
                      if (isSendToAll) {
                        // Gửi cho tất cả (Lấy danh sách ID và gửi loop)
                        // Lưu ý: Với app thực tế lớn, nên dùng Cloud Function. Ở đây demo vòng lặp.
                        final usersSnap = await FirebaseFirestore.instance.collection('users').get();
                        for (var doc in usersSnap.docs) {
                           await NotificationService().sendNotification(
                            receiverId: doc.id,
                            title: "[HỆ THỐNG] ${titleController.text}",
                            body: bodyController.text,
                            type: "system",
                          );
                        }
                         if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gửi cho ${usersSnap.docs.length} người dùng!")));
                        }
                      } else {
                        // Gửi cho 1 người
                        await NotificationService().sendNotification(
                          receiverId: selectedUserId!,
                          title: "[HỆ THỐNG] ${titleController.text}",
                          body: bodyController.text,
                          type: "system",
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi thành công!")));
                        }
                      }
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  // (Hàm Data Seeder cũ giữ nguyên)
  void _confirmSeedData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Dữ liệu?"),
        content: const Text("Thêm dữ liệu mẫu vào Firestore."),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(ctx);
               await DataSeeder().seedData();
               if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Done!")));
             }, 
             child: const Text("Đồng ý")
           )
        ],
      ),
    );
  }
}