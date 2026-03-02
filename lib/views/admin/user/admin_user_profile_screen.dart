import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
// import 'package:my_app/views/vehicle/vehicle_detail_screen.dart'; // Assuming you have this widget

class AdminUserProfileScreen extends StatefulWidget {
  final String userId;

  const AdminUserProfileScreen({super.key, required this.userId});

  @override
  State<AdminUserProfileScreen> createState() => _AdminUserProfileScreenState();
}

class _AdminUserProfileScreenState extends State<AdminUserProfileScreen> with TickerProviderStateMixin {
  TabController? _mainTabController;

  @override
  void dispose() {
    _mainTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ Người dùng"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User not found"));

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          
          final String role = userData['role'] ?? 'user';
          final bool isSeller = role == 'seller';
          final bool isAdmin = role == 'admin';

          // [LOGIC MỚI] 
          // Nếu là Admin -> Không cần Tab (length = 0 hoặc k init).
          // Nếu Seller -> 2 Tabs.
          // Nếu User -> 1 Tab (Cá nhân).
          int tabLength = 0;
          if (!isAdmin) {
             tabLength = isSeller ? 2 : 1;
          }

          // Chỉ khởi tạo Controller nếu KHÔNG phải Admin
          if (!isAdmin && (_mainTabController == null || _mainTabController!.length != tabLength)) {
            _mainTabController?.dispose();
            _mainTabController = TabController(length: tabLength, vsync: this);
          }

          final String displayName = userData['displayName'] ?? "No Name";
          final String? photoUrl = userData['photoUrl'];
          final String? storeName = userData['storeName'];
          final String? phoneNumber = userData['phoneNumber'];

          // Cấu hình giao diện Role
          String roleLabel;
          Color roleColor;
          Color roleBgColor;

          if (isAdmin) {
            roleLabel = "QUẢN TRỊ VIÊN (ADMIN)";
            roleColor = Colors.red;
            roleBgColor = Colors.red[50]!;
          } else if (isSeller) {
            roleLabel = "ĐỐI TÁC KINH DOANH (SELLER)";
            roleColor = Colors.purple;
            roleBgColor = Colors.purple[50]!;
          } else {
            roleLabel = "NGƯỜI MUA (USER)";
            roleColor = Colors.grey[700]!;
            roleBgColor = Colors.grey[200]!;
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                      ),
                      const SizedBox(height: 10),
                      Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      
                      const SizedBox(height: 5),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: roleColor),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roleColor),
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      // Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              if (isSeller) ...[
                                _infoRow(Icons.store, "Cửa hàng:", storeName ?? "Chưa đặt tên"),
                                const Divider(),
                                _infoRow(Icons.phone, "Hotline:", phoneNumber ?? "Chưa cập nhật"),
                                const Divider(),
                                _infoRow(Icons.location_on, "Địa chỉ:", userData['address'] ?? "Chưa cập nhật"),
                              ] else ...[
                                _infoRow(Icons.email, "Email:", userData['email'] ?? "---"),
                                const Divider(),
                                _infoRow(Icons.phone, "SĐT:", phoneNumber ?? "Chưa cập nhật"),
                                if (!isAdmin) ...[ 
                                   const Divider(),
                                   _infoRow(Icons.info_outline, "Trạng thái KD:", "Chưa đăng ký kinh doanh"),
                                ]
                              ],
                              
                              const Divider(),
                              _infoRow(Icons.calendar_today, "Tham gia:", _formatDate(userData['createdAt'])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // [QUAN TRỌNG] Chỉ hiện TabBar nếu KHÔNG PHẢI ADMIN
              if (!isAdmin && _mainTabController != null)
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _mainTabController,
                      labelColor: Colors.blueGrey[900],
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueGrey[900],
                      tabs: [
                        const Tab(text: "CÁ NHÂN"),
                        if (isSeller) const Tab(text: "CỬA HÀNG"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
            ],
            
            // [QUAN TRỌNG] Phần Body:
            // Nếu là Admin -> Trả về Widget rỗng (SizedBox.shrink)
            // Nếu không -> Trả về TabBarView danh sách xe
            body: isAdmin 
                ? const SizedBox.shrink() 
                : TabBarView(
                    controller: _mainTabController,
                    children: [
                      // Tab 1: Cá nhân
                      _buildProductListTab(userId: widget.userId, isStorePost: false),
                      
                      // Tab 2: Cửa hàng (chỉ có trong list children nếu isSeller = true ở logic trên)
                      if (isSeller)
                         _buildProductListTab(userId: widget.userId, isStorePost: true),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // --- CÁC HÀM HELPER GIỮ NGUYÊN ---
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "---";
    if (timestamp is Timestamp) return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    return "---";
  }

  Widget _buildProductListTab({required String userId, required bool isStorePost}) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: "Đang bán"),
                Tab(text: "Đã bán"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVehicleStream(userId, isStorePost, isSold: false), 
                _buildVehicleStream(userId, isStorePost, isSold: true), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStream(String userId, bool isStorePost, {required bool isSold}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: isSold ? 'sold' : 'approved') 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSold ? Icons.remove_shopping_cart : Icons.car_rental, size: 40, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  isSold ? "Chưa có xe đã bán" : "Chưa có xe đang bán",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final vehicleData = docs[index].data() as Map<String, dynamic>;
            final vehicle = VehicleModel.fromMap(vehicleData, docs[index].id); 

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(vehicle.images.isNotEmpty ? vehicle.images.first : 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(vehicle.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  "${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(vehicle.price)}\n${DateFormat('dd/MM/yyyy').format(vehicle.createdAt)}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
// Helper class cho thanh TabBar dính (Sticky Header)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Màu nền của thanh TabBar
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}