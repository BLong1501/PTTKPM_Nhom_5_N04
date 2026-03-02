import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/favourite_button.dart';
import '../../models/vehicle_model.dart';

class VehicleCard extends StatefulWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  bool isFavorite = false; // Trạng thái yêu thích (Tạm thời lưu cục bộ)
  final user = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // 1. Kiểm tra xem user đã like xe này chưa
  void _checkFavoriteStatus() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.vehicle.id) // Check theo ID xe
        .get();

    if (mounted) {
      setState(() {
        isFavorite = doc.exists;
      });
    }
  }
  // 2. Hàm Thả tim / Bỏ tim
  // Thay thế toàn bộ hàm _toggleFavorite cũ bằng hàm này
  void _toggleFavorite() async {
    // 1. Kiểm tra đăng nhập
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để lưu tin!")),
      );
      return;
    }

    // 2. KIỂM TRA QUAN TRỌNG: ID xe có bị rỗng không?
    if (widget.vehicle.id.isEmpty) {
      print("❌ LỖI NGHIÊM TRỌNG: ID xe bị rỗng (Empty String)!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không tìm thấy ID xe để lưu!")),
      );
      return;
    }

    print("ℹ️ Đang xử lý tim cho xe ID: ${widget.vehicle.id}");
    print("ℹ️ User ID: ${user!.uid}");

    // 3. Lưu trạng thái cũ để nếu lỗi thì quay xe
    final bool originalStatus = isFavorite;

    // 4. Cập nhật UI trước cho mượt
    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.vehicle.id);

      if (!originalStatus) {
        // Hành động: TIM
        await favoriteRef.set({
          'vehicleId': widget.vehicle.id,
          'addedAt': FieldValue.serverTimestamp(),
        });
        print("✅ Đã lưu thành công lên Firebase!");
      } else {
        // Hành động: BỎ TIM
        await favoriteRef.delete();
        print("🗑 Đã xóa thành công khỏi Firebase!");
      }
    } catch (e) {
      // 5. NẾU CÓ LỖI XẢY RA
      print("🔥 LỖI FIREBASE: $e");

      // Quay lại trạng thái cũ (Revert UI)
      setState(() {
        isFavorite = originalStatus;
      });

      // Hiện thông báo lỗi đỏ lòm lên màn hình điện thoại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi lưu tin: $e"), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Bo góc toàn bộ thẻ
          border: Border.all(color: Colors.grey.shade200), // Viền mỏng
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PHẦN ẢNH VÀ OVERLAY ---
            Expanded(
              flex: 5
              , // Chiếm 6 phần chiều cao
              child: Stack(
                children: [
                  // Ảnh nền
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      image: DecorationImage(
                        image: NetworkImage(
                          widget.vehicle.images.isNotEmpty 
                              ? widget.vehicle.images.first 
                              : 'https://via.placeholder.com/200',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Icon Tim (Yêu thích) - Góc phải trên
                  Positioned(
      top: 8,
      right: 8,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 16,
        child: FavoriteButton(vehicleId: widget.vehicle.id), // Truyền ID xe vào đây
      ),
    ),

                  // Thời gian đăng - Góc trái dưới
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTimeAgo(widget.vehicle.createdAt),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  // Số lượng ảnh - Góc phải dưới
                  if (widget.vehicle.images.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              "${widget.vehicle.images.length}",
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- 2. PHẦN THÔNG TIN ---
            Expanded(
              flex: 6, // Chiếm 5 phần chiều cao
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều dọc
                  children: [
                    // Tiêu đề
                    Text(   
                      widget.vehicle.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    
                    // Dòng phụ: Năm • Loại xe • Tình trạng
                    Text(
                      "${widget.vehicle.year} • ${widget.vehicle.category} • ${widget.vehicle.condition}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Giá bán
                    Text(
                      _formatCurrency(widget.vehicle.price),
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.red
                      ),
                    ),

                    // Địa điểm
                    // 👇 THÊM PHẦN NGƯỜI BÁN
                    Row(
                      children: [
                        // Icon tùy thuộc là Shop hay Cá nhân
                        Icon(
                          widget.vehicle.storeName != null ? Icons.store : Icons.person,
                          size: 12,
                          color: widget.vehicle.storeName != null ? Colors.purple : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.vehicle.storeName ?? "Người bán cá nhân", // Nếu null thì hiện text mặc định
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.vehicle.storeName != null ? Colors.purple : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 2),

                    // 👇 PHẦN ĐỊA ĐIỂM (Dời xuống đây)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.vehicle.location,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM PHỤ TRỢ: ĐỊNH DẠNG TIỀN TỆ ---
  String _formatCurrency(double price) {
    // Nếu bạn chưa cài package intl thì dùng regex đơn giản này
    // Chuyển 16900000 -> 16.900.000 đ
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // --- HÀM PHỤ TRỢ: TÍNH THỜI GIAN (VD: 26 giây trước) ---
  String _getTimeAgo(DateTime createdDate) {
    final duration = DateTime.now().difference(createdDate);
    
    if (duration.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(createdDate);
    } else if (duration.inDays >= 1) {
      return "${duration.inDays} ngày trước";
    } else if (duration.inHours >= 1) {
      return "${duration.inHours} giờ trước";
    } else if (duration.inMinutes >= 1) {
      return "${duration.inMinutes} phút trước";
    } else {
      return "Vừa xong";
    }
  }
}