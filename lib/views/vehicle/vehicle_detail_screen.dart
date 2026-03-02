import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/providers/chat_provider.dart';
import 'package:my_app/views/chat/chat_detail_screen.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart';
import 'package:my_app/views/admin/report/report_dialog_screen.dart'; // Import Dialog báo cáo
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import 'package:flutter/services.dart';

class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Xác định xem đây là bài đăng của Cửa hàng hay Cá nhân
    final bool isStorePost =
        vehicle.storeName != null && vehicle.storeName!.isNotEmpty;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Kiểm tra xem người xem có phải là chủ xe không
    final bool isOwner =
        currentUserId != null && currentUserId == vehicle.ownerId;

    return Scaffold(
      // backgroundColor: Colors.white,
      
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text(vehicle.title, style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
        ),),
       flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5D3FD3), // tím
                  Color(0xFFC51162), // hồng đậm
                ],
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight,
              ),
            ),
          ),
        elevation: 0,

        // Các nút hành động trên AppBar
        actions: isOwner
            ? [
                // Nút Sửa (Chỉ hiện cho chủ xe)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color.fromARGB(255, 255, 255, 255)),
                  tooltip: "Chỉnh sửa",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddVehicleScreen(
                          isStorePost: isStorePost,
                          vehicleToEdit: vehicle,
                        ),
                      ),
                    ).then((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                ),
                // Nút Xóa (Chỉ hiện cho chủ xe)
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 255, 253, 253),
                  ),
                  tooltip: "Xóa tin",
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
              ]
            : [
                // Nút Báo cáo (Chỉ hiện cho người xem)
                IconButton(
                  icon: const Icon(
                    Icons.report_gmailerrorred,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  tooltip: "Báo cáo vi phạm",
                  onPressed: () {
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng đăng nhập để báo cáo."),
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (ctx) => ReportDialog(
                        vehicleId: vehicle.id,
                        reportedUserId: vehicle.ownerId,
                        vehicleTitle: vehicle.title,
                      ),
                    );
                  },
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SLIDER
            SizedBox(
              height: 250,
              child: vehicle.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: vehicle.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          vehicle.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. GIÁ & TIÊU ĐỀ
                  Text(
                    _formatCurrency(vehicle.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${vehicle.location} • ${_getTimeAgo(vehicle.createdAt)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  // 3. THÔNG SỐ KỸ THUẬT
                  const Text(
                    "Thông số kỹ thuật",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4,
                    children: [
                      _buildSpecItem("Hãng xe", vehicle.brand),
                      _buildSpecItem("Năm sx", vehicle.year.toString()),
                      _buildSpecItem("Tình trạng", vehicle.condition),
                      _buildSpecItem("Nhiên liệu", vehicle.fuelType),
                      _buildSpecItem("Xuất xứ", vehicle.origin),
                      _buildSpecItem("Dung tích", vehicle.capacity),
                      _buildSpecItem("Trọng lượng", "${vehicle.weight} kg"),
                      _buildSpecItem("Màu sắc", vehicle.color),
                      _buildSpecItem("Odo", "${vehicle.mileage} km"),
                    ],
                  ),

                  const Divider(height: 30),

                  // 4. MÔ TẢ CHI TIẾT
                  const Text(
                    "Mô tả chi tiết",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vehicle.description.isNotEmpty
                        ? vehicle.description
                        : "Không có mô tả.",
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),

                  const Divider(height: 30),

                  // 5. THÔNG TIN NGƯỜI BÁN
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(vehicle.ownerId)
                        .get(),
                    builder: (context, snapshot) {
                      String sellerName = "Đang tải...";
                      String? displayAvaUrl;

                      // Fallback name
                      if (isStorePost && vehicle.storeName != null) {
                        sellerName = vehicle.storeName!;
                      }

                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        if (isStorePost) {
                          // Logic hiển thị Shop
                          displayAvaUrl = userData['storeAva'];
                          if (userData['storeName'] != null) {
                            sellerName = userData['storeName'];
                          }
                        } else {
                          // Logic hiển thị Cá nhân
                          displayAvaUrl = userData['photoUrl'];
                          sellerName = userData['displayName'] ?? "Người dùng";
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: vehicle.ownerId,
                                forceIndividual: !isStorePost,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: isStorePost
                                    ? Colors.purple[100]
                                    : Colors.blue[100],
                                backgroundImage: displayAvaUrl != null
                                    ? NetworkImage(displayAvaUrl)
                                    : null,
                                child: displayAvaUrl == null
                                    ? Icon(
                                        isStorePost
                                            ? Icons.store
                                            : Icons.person,
                                        color: isStorePost
                                            ? Colors.purple
                                            : Colors.blue,
                                        size: 30,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (isStorePost)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          "Cửa hàng uy tín",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    else
                                      const Text(
                                        "Người bán cá nhân",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 18,
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION BAR: NÚT LIÊN HỆ
      // BOTTOM NAVIGATION BAR: NÚT LIÊN HỆ
      // BOTTOM NAVIGATION BAR: NÚT LIÊN HỆ
     // BOTTOM NAVIGATION BAR: NÚT LIÊN HỆ & GỌI ĐIỆN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        
        child:   Row( // Chia làm 2 nút
       
          children: [
            if (currentUserId != vehicle.ownerId)
            // --- NÚT 1: GỌI ĐIỆN (COPY SỐ) ---
            Expanded(
              flex: 4, // Chiếm 40% chiều rộng
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color.fromARGB(255, 138, 68, 156), width: 2),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.phone, color: Color.fromARGB(255, 151, 67, 146)),
                label: const Text(
                  "GỌI ĐIỆN", 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: Color.fromRGBO(164, 70, 167, 1)
                  )
                ),
                onPressed: () {
                  // Logic copy số điện thoại
                  if (vehicle.contactPhone.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: vehicle.contactPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã copy số: ${vehicle.contactPhone}"),
                        backgroundColor: const Color.fromARGB(255, 89, 57, 139),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: "OK",
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Người bán không để lại số điện thoại.")),
                    );
                  }
                },
              ),
            ),
            
  
            const SizedBox(width: 12), // Khoảng cách giữa 2 nút

            // --- NÚT 2: LIÊN HỆ NGAY (CHAT) ---
            if (currentUserId != vehicle.ownerId)
            Expanded(
              flex: 6, // Chiếm 60% chiều rộng (Nút Chat quan trọng hơn)
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 175, 87, 183),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text(
                  "CHAT NGAY",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Logic Chat giữ nguyên như cũ
                onPressed: () async {
                  if (currentUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng đăng nhập để chat.")),
                    );
                    return;
                  }
                  if (isOwner) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đây là bài đăng của bạn.")),
                    );
                    return;
                  }

                  // Hiển thị loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    String targetChatRoomId;
                    String targetVehicleId = vehicle.id;
                    String targetVehicleTitle = vehicle.title;

                    // 1. TÌM KIẾM PHÒNG CHAT CŨ
                    final QuerySnapshot query = await FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .where('users', arrayContains: currentUserId)
                        .get();

                    DocumentSnapshot? existingRoom;
                    for (var doc in query.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final List<dynamic> users = data['users'] ?? [];
                      if (users.contains(vehicle.ownerId)) {
                        existingRoom = doc;
                        break;
                      }
                    }

                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                    if (existingRoom != null) {
                      targetChatRoomId = existingRoom.id;
                    } else {
                      targetChatRoomId = chatProvider.getChatRoomId(
                          currentUserId!, vehicle.ownerId, vehicle.id);
                    }
                    
                    // Lấy thông tin người bán
                    String finalReceiverName = "Người bán";
                    String? finalReceiverAvatar;
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(vehicle.ownerId).get();
                    if (userDoc.exists) {
                        final userData = userDoc.data() as Map<String, dynamic>;
                        if (isStorePost) {
                            finalReceiverName = vehicle.storeName ?? userData['storeName'] ?? "Cửa hàng";
                            finalReceiverAvatar = userData['storeAva'];
                        } else {
                            finalReceiverName = userData['displayName'] ?? "Người dùng";
                            finalReceiverAvatar = userData['photoUrl'];
                        }
                    }

                    if (context.mounted) Navigator.pop(context); // Tắt loading

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatRoomId: targetChatRoomId,
                            receiverId: vehicle.ownerId,
                            receiverName: finalReceiverName,
                            receiverAvatar: finalReceiverAvatar,
                            vehicleId: targetVehicleId,     
                            vehicleTitle: targetVehicleTitle,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    print("Lỗi: $e");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM PHỤ TRỢ (HELPER METHODS) ---

  Widget _buildSpecItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            "$label:",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty ? "---" : value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  String _getTimeAgo(DateTime createdDate) {
    final duration = DateTime.now().difference(createdDate);
    if (duration.inDays > 7)
      return DateFormat('dd/MM/yyyy').format(createdDate);
    if (duration.inDays >= 1) return "${duration.inDays} ngày trước";
    if (duration.inHours >= 1) return "${duration.inHours} giờ trước";
    return "Vừa xong";
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text(
          "Bạn có chắc chắn muốn xóa bài đăng này không? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicle.id)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa bài đăng thành công")),
                  );
                  Navigator.pop(context); // Quay về màn hình trước
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
                }
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
