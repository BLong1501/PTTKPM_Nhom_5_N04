import 'package:cloud_firestore/cloud_firestore.dart'  ;
// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👇 Import Provider
import '../../providers/auth_provider.dart'; // 👇 Import AuthProvider
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/views/seller/edit_profile_screen.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import 'package:my_app/views/widgets/vehicle_card.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart'; 
import 'package:my_app/views/seller/store_followers_screen.dart'; // 👇 Import màn hình mới tạo

class MyStoreScreen extends StatelessWidget {
  const MyStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Lấy thông tin user từ Provider để có số lượng follow mới nhất
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.user;
    final uid = userModel?.uid;

    if (uid == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Cửa hàng"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStoreScreen()));
            },
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const AddVehicleScreen(isStorePost: true))
          );
        },
        backgroundColor: Colors.purple,
        label: const Text("Đăng sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),

      // 👇 Đổi cấu trúc thành Column để chứa phần Follower ở trên và List xe ở dưới
      body: Column(
        children: [
          
          // --- 1. PHẦN HIỂN THỊ FOLLOWER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.05), // Màu nền nhẹ
            child: GestureDetector( // Bắt sự kiện ấn vào
              onTap: () {
                // Mở màn hình danh sách follower
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => StoreFollowersScreen(storeId: uid))
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        "${userModel?.storeFollowers ?? 0}", // 👇 Lấy số từ Model
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Người theo dõi cửa hàng",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),

          // --- 2. DANH SÁCH XE (Bọc trong Expanded) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('ownerId', isEqualTo: uid)
                  .where('status', isEqualTo: 'approved')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bạn chưa đăng tin nào"));
                }

                // Lọc thủ công xe của Shop
                final allDocs = snapshot.data!.docs;
                final shopDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['storeName'] != null;
                }).toList();

                if (shopDocs.isEmpty) {
                   return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("Cửa hàng chưa có sản phẩm nào", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        const Text("Các bài đăng cá nhân sẽ không hiện ở đây.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 2, 
                     childAspectRatio: 0.65, 
                     mainAxisSpacing: 10,
                     crossAxisSpacing: 10
                  ),
                  itemCount: shopDocs.length,
                  itemBuilder: (ctx, index) {
                    final data = shopDocs[index].data() as Map<String, dynamic>;
                    final vehicle = VehicleModel.fromMap(data, shopDocs[index].id);
                    
                    return VehicleCard(
                      vehicle: vehicle, 
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_)=>VehicleDetailScreen(vehicle: vehicle),
                          )
                        );
                      }
                    ); 
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}