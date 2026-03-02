  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
  import '../../models/vehicle_model.dart';
  import '../widgets/vehicle_card.dart';

  class FavoriteScreen extends StatelessWidget {
    const FavoriteScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Yêu thích")),
          body: const Center(child: Text("Vui lòng đăng nhập để xem tin yêu thích")),
        );
      }

      return Scaffold(
        appBar: AppBar(
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
            
          title: const Text("Tin đã lưu", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        // 1. Lắng nghe danh sách yêu thích của User
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Bạn chưa lưu tin nào!"));
            }

            final favoriteDocs = snapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: favoriteDocs.length,
              itemBuilder: (context, index) {
                final vehicleId = favoriteDocs[index]['vehicleId'];
                final favoriteDocId = favoriteDocs[index].id; // Lấy ID của dòng favorite để xóa

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get(),
                  builder: (context, vehicleSnapshot) {
                    // 1. Đang tải
                    if (!vehicleSnapshot.hasData) {
                      return Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    
                    // 🔥 2. NẾU XE ĐÃ BỊ XÓA -> TỰ ĐỘNG XÓA KHỎI FAVORITE LUÔN 🔥
                    if (!vehicleSnapshot.data!.exists) {
                      // Gọi hàm xóa "âm thầm" (không cần await để UI chạy mượt)
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('favorites')
                          .doc(favoriteDocId) // Xóa dòng favorite này đi
                          .delete();

                      // Trả về SizedBox rỗng để chỗ này biến mất ngay lập tức trên UI
                      return const SizedBox(); 
                    }

                    final data = vehicleSnapshot.data!.data() as Map<String, dynamic>;

                    // 3. Nếu xe chưa duyệt hoặc bị ẩn -> Cũng xóa luôn hoặc chỉ ẩn đi (Tùy bạn)
                    // Ở đây tôi chọn phương án: Chỉ ẩn đi, không xóa, vì xe có thể được duyệt lại
                    if (data['status'] != 'approved') {
                      return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100], 
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.visibility_off_outlined, color: Colors.grey),
                              const SizedBox(height: 5),
                              const Text("Tin đang ẩn", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(
                                data['status'] == 'pending' ? "(Chờ duyệt)" : "(Đã ẩn/Từ chối)",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                      );
                    }

                    // 4. Hiển thị xe bình thường
                    final vehicle = VehicleModel.fromMap(data, vehicleSnapshot.data!.id);

                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        Navigator.push(context,
                              MaterialPageRoute(builder: (_)=>VehicleDetailScreen(vehicle: vehicle)));
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      );
      
    }
  }