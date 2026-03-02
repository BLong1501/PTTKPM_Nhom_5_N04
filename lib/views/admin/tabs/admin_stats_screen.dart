import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // Các biến lưu trữ số liệu
  int _totalUsers = 0;
  int _totalPosts = 0;
  int _pendingPosts = 0;
  int _reports = 0;
  int _bannedUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllStats();
  }

  // Hàm tải tất cả thống kê cùng lúc
  Future<void> _fetchAllStats() async {
    try {
      final results = await Future.wait([
        // 0. Tổng người dùng
        FirebaseFirestore.instance.collection('users').count().get(),
        // 1. Tổng bài đăng
        FirebaseFirestore.instance.collection('vehicles').count().get(),
        // 2. Bài chờ duyệt
        FirebaseFirestore.instance
            .collection('vehicles')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
        // 3. Số lượng báo cáo
        FirebaseFirestore.instance.collection('reports').count().get(),
        // 4. Tài khoản bị cấm
        FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'banned')
            .count()
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers = results[0].count ?? 0;
          _totalPosts = results[1].count ?? 0;
          _pendingPosts = results[2].count ?? 0;
          _reports = results[3].count ?? 0;
          _bannedUsers = results[4].count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thống kê: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM WIDGET CON: KHÔNG DÙNG EXPANDED Ở ĐÂY ---
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 1. Giảm padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Dùng spaceBetween để icon lên đỉnh, số xuống đáy
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            // PHẦN TRÊN: ICON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28), // Giảm size icon chút xíu
                if (onTap != null)
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
              ],
            ),
            
            // Không cần SizedBox cứng nữa, để nó tự giãn bằng mainAxisAlignment: spaceBetween
            
            // PHẦN DƯỚI: SỐ LIỆU & TIÊU ĐỀ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Dùng FittedBox để số tự thu nhỏ nếu quá to/dài
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$count",
                    style: TextStyle(
                      fontSize: 26, // Giảm font size mặc định xuống 1 xíu
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1, // Chỉ cho hiện 1 dòng
                  overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện ...
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HÀM BUILD CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar có thể bỏ nếu AdminScreen cha đã có AppBar, 
      // nhưng giữ lại cũng không sao nếu muốn có nút refresh riêng
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hoạt động cần xử lý",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // PHẦN 1: ROW (Cần bọc Expanded thủ công ở đây)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Chờ duyệt",
                            count: _pendingPosts,
                            icon: Icons.hourglass_top,
                            color: Colors.orange,
                            onTap: () {
                              // TODO: Navigate to Approval Screen
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: "Đơn tố cáo",
                            count: _reports,
                            icon: Icons.report_problem,
                            color: Colors.red,
                            onTap: () {
                              // TODO: Navigate to Reports Screen
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Dữ liệu hệ thống",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // PHẦN 2: GRIDVIEW (Không được dùng Expanded ở đây)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          title: "Thành viên",
                          count: _totalUsers,
                          icon: Icons.group,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: "Tin đăng",
                          count: _totalPosts,
                          icon: Icons.car_rental,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          title: "Bị khóa",
                          count: _bannedUsers,
                          icon: Icons.block,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}