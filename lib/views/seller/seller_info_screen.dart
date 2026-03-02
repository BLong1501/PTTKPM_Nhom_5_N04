import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'create_store_screen.dart'; // Import màn hình tạo mới
import 'my_store_screen.dart';     // Import màn hình xem danh sách sản phẩm

class SellerInfoScreen extends StatelessWidget {
  const SellerInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin cá nhân từ Provider
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.user;

    if (userModel == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 👇 LOGIC MỚI: Kiểm tra xem đã có tên Shop trong user profile chưa
    bool hasStore = userModel.storeName != null && userModel.storeName!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Hồ sơ người bán"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: THÔNG TIN BÁN CÁ NHÂN (Luôn hiển thị) ---
            const Text("THÔNG TIN CÁ NHÂN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: (userModel.photoUrl != null && userModel.photoUrl!.isNotEmpty)
                        ? NetworkImage(userModel.photoUrl!)
                        : null,
                    child: (userModel.photoUrl == null || userModel.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 35)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userModel.displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(userModel.phoneNumber ?? "Chưa cập nhật SĐT"),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("Người bán đã xác thực", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- PHẦN 2: QUẢN LÝ CỬA HÀNG ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("QUẢN LÝ CỬA HÀNG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                if (hasStore) const Icon(Icons.store, color: Colors.purple),
              ],
            ),
            const SizedBox(height: 10),

            // 👇 LOGIC HIỂN THỊ NÚT BẤM 👇
            if (!hasStore)
              // TRƯỜNG HỢP A: CHƯA CÓ SHOP -> HIỆN NÚT TẠO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      "Bạn chưa thiết lập Cửa hàng?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      "Tạo cửa hàng ngay để đăng bán sản phẩm chuyên nghiệp hơn.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          // 👉 Chuyển sang màn hình tạo mới (CreateStoreScreen)
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const CreateStoreScreen())
                          );
                        },
                        child: const Text("TẠO CỬA HÀNG NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              )
            else
              // TRƯỜNG HỢP B: ĐÃ CÓ SHOP -> HIỆN THÔNG TIN VÀ NÚT XEM
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userModel.storeName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                    const Divider(),
                    _buildStoreRow(Icons.location_on, userModel.address ?? "Chưa cập nhật địa chỉ"),
                    if (userModel.description != null)
                      _buildStoreRow(Icons.info_outline, userModel.description!),
                    
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text("VÀO XEM CỬA HÀNG CỦA TÔI"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[50],
                          foregroundColor: Colors.purple,
                          elevation: 0,
                        ),
                        onPressed: () {
                          // 👉 Chuyển sang màn hình xem shop (MyStoreScreen)
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyStoreScreen()));
                        },
                      ),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStoreRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}