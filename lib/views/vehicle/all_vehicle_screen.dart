import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class AllVehiclesScreen extends StatefulWidget {
  const AllVehiclesScreen({super.key});

  @override
  State<AllVehiclesScreen> createState() => _AllVehiclesScreenState();
}

class _AllVehiclesScreenState extends State<AllVehiclesScreen> {
  // Cấu hình
  final int _limit = 16; // Số lượng mỗi trang
  bool _isLoading = false;
  List<DocumentSnapshot> _products = []; // Danh sách xe đang hiển thị
  
  // Logic phân trang
  // Lưu lại snapshot đầu tiên của mỗi trang để làm điểm mốc khi quay lại
  final List<DocumentSnapshot> _pageStartDocuments = []; 
  int _currentPage = 1;
  bool _hasMore = true; // Kiểm tra xem còn trang sau không

  @override
  void initState() {
    super.initState();
    _loadData(); // Tải trang 1 ngay khi mở
  }

  // HÀM TẢI DỮ LIỆU
  Future<void> _loadData({DocumentSnapshot? startAfterDoc}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('vehicles')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    try {
      final QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.length < _limit) {
        _hasMore = false; // Nếu lấy về ít hơn 16 cái -> Hết dữ liệu
      } else {
        _hasMore = true;
      }

      setState(() {
        _products = snapshot.docs;
        _isLoading = false;
        
        // Lưu lại document đầu tiên của trang này vào lịch sử nếu chưa có
        // (Để dùng cho nút "Trang trước")
        if (_products.isNotEmpty) {
           if (_pageStartDocuments.length < _currentPage) {
             _pageStartDocuments.add(_products.first);
           }
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tải trang: $e");
    }
  }

  // HÀM SANG TRANG TIẾP THEO
  void _nextPage() {
    if (!_hasMore || _products.isEmpty) return;
    
    setState(() {
      _currentPage++;
    });
    // Lấy dữ liệu bắt đầu sau thằng cuối cùng của trang hiện tại
    _loadData(startAfterDoc: _products.last);
  }

  // HÀM QUAY LẠI TRANG TRƯỚC
  void _prevPage() {
    if (_currentPage <= 1) return;

    setState(() {
      _currentPage--;
      // Reset lại list nếu về trang 1
      if (_currentPage == 1) {
        _pageStartDocuments.clear(); // Clear lịch sử để load lại từ đầu cho sạch
        _loadData(); // Load không tham số = Load trang đầu
      } else {
        // Load lại trang trước dựa vào lịch sử document đầu tiên của trang đó
        // Logic Firestore back hơi phức tạp, cách đơn giản nhất là:
        // Lưu lại "Document CUỐI CÙNG của trang (N-2)" để làm startAfter cho trang (N-1)
        // Tuy nhiên để đơn giản cho người mới, ta sẽ dùng mảng _pageStartDocuments:
        // Nhưng Firestore Cursor chỉ hỗ trợ "startAfter". 
        
        // CÁCH ĐƠN GIẢN: Reset về trang đầu và chạy lại (An toàn nhất)
        // Hoặc xây dựng lại logic cache. Ở đây mình chọn cách load lại trang đầu nếu user back.
        // Để làm nút Back chuẩn chỉnh cần logic phức tạp hơn nhiều. 
        // -> Tạm thời logic: Back = Load lại từ đầu trang 1
         _pageStartDocuments.clear();
         _currentPage = 1;
         _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả xe đang bán"),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
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
      
      body: Column(
        children: [
          // 1. DANH SÁCH SẢN PHẨM
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("Không tìm thấy xe nào"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final data = _products[index].data() as Map<String, dynamic>;
                          final vehicle = VehicleModel.fromMap(data, _products[index].id);
                          return VehicleCard(
                              vehicle: vehicle, 
                              onTap: () {
                                Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (_)=>VehicleDetailScreen(vehicle: vehicle),
                                  )
                                );
                                // Navigator to detail
                              }
                          );
                        },
                      ),
          ),

          // 2. THANH CÔNG CỤ PHÂN TRANG (BOTTOM BAR)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, -2))]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút TRƯỚC
                ElevatedButton.icon(
                  onPressed: _currentPage > 1 && !_isLoading ? _prevPage : null,
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  label: const Text("Trước"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),

                // Số trang hiện tại
                Text(
                  "Trang $_currentPage",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                // Nút SAU
                ElevatedButton.icon(
                  onPressed: _hasMore && !_isLoading ? _nextPage : null,
                  // Đảo chiều icon cho đẹp
                  icon: const Text("Sau", style: TextStyle(fontWeight: FontWeight.bold)),
                  label: const Icon(Icons.arrow_forward_ios, size: 16),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}