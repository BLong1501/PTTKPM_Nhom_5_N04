import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
// import '../widgets/vehicle_card.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  // Có thể truyền từ khóa hoặc bộ lọc ban đầu vào đây nếu muốn
  final String? initialKeyword;
  final String? initialLocation;

  const SearchScreen({super.key, this.initialKeyword, this.initialLocation});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VehicleModel> _allVehicles = []; // Danh sách gốc
  List<VehicleModel> _filteredVehicles = []; // Danh sách sau khi lọc
  bool _isLoading = true;
  bool _isSearching = false; // Để kiểm tra xem người dùng đã bấm tìm chưa
  String? _filterLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null) {
      _searchController.text = widget.initialKeyword!;
    }
    // Gán giá trị ban đầu được truyền từ Home
    _filterLocation = widget.initialLocation;
    _fetchAllVehicles();
  }

  // 1. Tải toàn bộ xe "approved" về trước (Client-side filtering)
  // Cách này tốt cho App < 5000 xe. Nếu nhiều hơn phải dùng giải pháp khác (Algolia).
  Future<void> _fetchAllVehicles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      final data = snapshot.docs.map((doc) {
        return VehicleModel.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _allVehicles = data;
        _isLoading = false;
        // Nếu có từ khóa ban đầu thì lọc luôn
        if (_searchController.text.isNotEmpty) {
          _runFilter(_searchController.text);
        } else {
          // Nếu chưa nhập gì thì hiện tất cả hoặc danh sách rỗng tùy bạn
          _filteredVehicles = data;
        }
      });
    } catch (e) {
      print("Lỗi tải xe: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. CẬP NHẬT LOGIC LỌC (QUAN TRỌNG)
  void _runFilter(String keyword) {
    setState(() {
      _isSearching = true;

      // Bắt đầu từ danh sách gốc
      List<VehicleModel> temp = _allVehicles;

      // A. Lọc theo địa điểm (Nếu có)
      if (_filterLocation != null && _filterLocation != "Toàn quốc") {
        temp = temp.where((v) => v.location == _filterLocation).toList();
      }

      // B. Lọc theo từ khóa (Nếu có)
      if (keyword.isNotEmpty) {
        final searchLower = keyword.toLowerCase();
        temp = temp.where((vehicle) {
          final titleLower = vehicle.title.toLowerCase();
          final brandLower = vehicle.brand.toLowerCase();
          return titleLower.contains(searchLower) ||
              brandLower.contains(searchLower);
        }).toList();
      }

      // Gán kết quả cuối cùng
      _filteredVehicles = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Tự động bật bàn phím khi vào trang này
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)), // bo tròn
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)), // bo tròn
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: "Nhập tên xe, hãng xe...", contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          ),
          onChanged: _runFilter, // Gõ đến đâu lọc đến đó
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _runFilter('');
            },
          ),
        ],
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

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredVehicles.isEmpty
          ? _buildEmptyState() // Hiện thông báo không tìm thấy
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _filteredVehicles[index];

                // 👇 BỌC CONTAINER BẰNG GESTURE DETECTOR ĐỂ BẮT SỰ KIỆN ẤN
                return GestureDetector(
                  onTap: () {
                    // Chuyển sang màn hình chi tiết khi ấn vào
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VehicleDetailScreen(vehicle: vehicle),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8), // Thêm padding cho đẹp
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
                    height: 120, // Giảm chiều cao chút cho gọn
                    child: Row(
                      children: [
                        // Ảnh xe
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            vehicle.images.isNotEmpty
                                ? vehicle.images.first
                                : 'https://via.placeholder.com/150',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            // Thêm loading builder để tránh lỗi khi ảnh đang tải
                            loadingBuilder: (ctx, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${vehicle.price} VND", // Bạn có thể dùng hàm _formatCurrency nếu muốn đẹp hơn
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${vehicle.brand} • ${vehicle.year}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      vehicle.location,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Widget hiển thị khi không tìm thấy
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Không tìm thấy kết quả nào cho \"${_searchController.text}\"",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
