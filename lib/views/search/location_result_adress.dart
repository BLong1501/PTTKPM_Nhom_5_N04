import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import '../../models/vehicle_model.dart';
// import '../widgets/vehicle_card.dart';

class LocationResultScreen extends StatelessWidget {
  final String location;

  const LocationResultScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    // Logic xác định Query
    Query query = FirebaseFirestore.instance.collection('vehicles')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);

    // Nếu không phải "Toàn quốc" thì thêm điều kiện lọc theo địa điểm
    if (location != "Toàn quốc") {
      query = query.where('location', isEqualTo: location);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          location == "Toàn quốc" ? "Tất cả khu vực" : "Xe tại $location",
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 182, 38, 38)),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Chưa có xe nào tại $location", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final vehicle = VehicleModel.fromMap(data, docs[index].id);

              // 👇 BỌC GESTURE DETECTOR ĐỂ ẤN ĐƯỢC
              return GestureDetector(
                onTap: () {
                  // Chuyển sang màn hình chi tiết
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8), // Thêm padding nội bộ cho đẹp
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  height: 120, // Giảm chiều cao chút cho cân đối
                  child: Row(
                    children: [
                      // Ảnh xe
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          vehicle.images.isNotEmpty ? vehicle.images.first : 'https://via.placeholder.com/150',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Container(width: 120, height: 120, color: Colors.grey[200], child: const Icon(Icons.error)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Thông tin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vehicle.title, 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${vehicle.price} VNĐ", // Có thể dùng hàm format tiền nếu muốn
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            const SizedBox(height: 4),
                            // Hiển thị thêm Năm sx và Hãng cho đầy đủ
                            Text(
                              "${vehicle.brand} • ${vehicle.year}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    vehicle.location, 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}