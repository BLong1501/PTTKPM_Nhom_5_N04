import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/tabs/vehicle_approval_tab.dart';
import 'package:my_app/views/admin/tabs/seller_approval_tab.dart';
import 'package:my_app/views/admin/tabs/report_tab.dart';

class RequestManagementScreen extends StatelessWidget {
  const RequestManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.blueGrey,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                // 1. TAB DUYỆT XE (Đếm xe status = 'pending')
                _buildTabWithBadge(
                  label: "Duyệt Xe",
                  icon: Icons.directions_car,
                  stream: FirebaseFirestore.instance
                      .collection('vehicles')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                ),

                // 2. TAB SELLER (Đếm yêu cầu seller chưa duyệt)
                // Lưu ý: Bạn cần sửa query này khớp với logic duyệt seller của bạn
                // Ví dụ: collection('seller_requests') hoặc collection('users').where('sellerStatus', isEqualTo: 'pending')
                _buildTabWithBadge(
                  label: "Seller",
                  icon: Icons.verified_user,
                  stream: FirebaseFirestore.instance
                      .collection('users') 
                      .where('isSellerRequestPending', isEqualTo: true) // Ví dụ điều kiện
                      .snapshots(),
                ),

                // 3. TAB TỐ CÁO (Đếm report status = 'pending')
                _buildTabWithBadge(
                  label: "Tố cáo",
                  icon: Icons.report_problem,
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('status', isEqualTo: 'pending') // Chỉ đếm cái chưa xử lý
                      .snapshots(),
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                VehicleApprovalTab(),
                SellerApprovalTab(),
                ReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM HỖ TRỢ TẠO TAB CÓ BADGE ---
  Widget _buildTabWithBadge({
    required String label,
    required IconData icon,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // Mặc định là 0
        int count = 0;
        
        // Nếu có dữ liệu thì lấy số lượng docs
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Tab(
          icon: Badge(
            // Chỉ hiện Badge nếu số lượng > 0
            isLabelVisible: count > 0,
            // Màu nền của số (thường là đỏ)
            backgroundColor: Colors.red,
            // Nội dung số
            label: Text(
              count > 99 ? '99+' : '$count', // Nếu nhiều quá thì hiện 99+
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            // Icon chính của Tab
            child: Icon(icon),
          ),
          text: label,
        );
      },
    );
  }
}