import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
// import '../widgets/vehicle_card.dart';

class CategoryResultScreen extends StatefulWidget {
  final String category; // VD: "Xe máy", "Ô tô"

  const CategoryResultScreen({super.key, required this.category});

  @override
  State<CategoryResultScreen> createState() => _CategoryResultScreenState();
}

class _CategoryResultScreenState extends State<CategoryResultScreen> {
  // 1. CÁC BIẾN LƯU TRẠNG THÁI BỘ LỌC
  String? _selectedLocation;
  String? _selectedBrand;
  int? _selectedYear;

  // 2. HÀM HIỂN THỊ BẢNG LỌC (BOTTOM SHEET)
  void _showFilterModal() {
    final provider = Provider.of<VehicleProvider>(context, listen: false);

    // Lấy danh sách
    final brandList = provider.getBrandsByCategory(widget.category);
    final yearList = List.generate(
      37,
      (index) => DateTime.now().year + 1 - index,
    );

    // Biến tạm
    String? tempLocation = _selectedLocation;
    String? tempBrand = _selectedBrand;
    int? tempYear = _selectedYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 550, // Tăng chiều cao xíu cho thoải mái
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bộ lọc tìm kiếm",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Nút Xóa bộ lọc (Reset về null)
                          setModalState(() {
                            tempLocation = null;
                            tempBrand = null;
                            tempYear = null;
                          });
                        },
                        child: const Text(
                          "Đặt lại",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // --- 1. CHỌN KHU VỰC ---
                  const Text(
                    "Khu vực:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<String>(
                    value: tempLocation, // Nếu null sẽ hiện hint
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    hint: const Text("Toàn quốc"),
                    items: [
                      // 👇 QUAN TRỌNG: Thêm thủ công mục "Toàn quốc" để logic hoạt động đúng
                      const DropdownMenuItem(
                        value: "Toàn quốc",
                        child: Text("Toàn quốc"),
                      ),
                      ...provider.locations.map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() => tempLocation = val);
                      print("🟡 Modal chọn địa điểm: $val"); // Log kiểm tra
                    },
                  ),
                  const SizedBox(height: 15),

                  // --- 2. CHỌN HÃNG XE ---
                  const Text(
                    "Hãng xe:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<String>(
                    value: tempBrand,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      
                      contentPadding: EdgeInsets.all(10),
                    ),
                    hint: const Text("Tất cả hãng"),
                    items: [
                      const DropdownMenuItem(
                        value: "Tất cả hãng",
                        child: Text("Tất cả hãng"),
                      ),
                      ...brandList.map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      ),
                    ],
                    onChanged: (val) => setModalState(() => tempBrand = val),
                  ),
                  const SizedBox(height: 15),

                  // --- 3. CHỌN NĂM SX ---
                  const Text(
                    "Năm sản xuất:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    hint: const Text("Tất cả đời xe"),
                    items: yearList
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setModalState(() => tempYear = val),
                  ),

                  const Spacer(),

                  // --- NÚT ÁP DỤNG ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        setState(() {
                          // Nếu chọn "Toàn quốc" hoặc "Tất cả..." thì gán về null để KHÔNG lọc
                          _selectedLocation = (tempLocation == "Toàn quốc")
                              ? null
                              : tempLocation;
                          _selectedBrand = (tempBrand == "Tất cả hãng")
                              ? null
                              : tempBrand;
                          _selectedYear = tempYear;
                        });

                        print("✅ Đã áp dụng bộ lọc:");
                        print("   Location: $_selectedLocation");
                        print("   Brand: $_selectedBrand");

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Áp dụng bộ lọc",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255),fontWeight: FontWeight.bold),
        ),
        elevation: 1,
        iconTheme: const IconThemeData(
          color:  Color.fromARGB(255, 182, 38, 38),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list,
                color: Colors.white,),
                if (_selectedBrand != null ||
                    _selectedLocation != null ||
                    _selectedYear != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterModal,
          ),
        ],
        // Gradient background
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
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('status', isEqualTo: 'approved')
            .where('category', isEqualTo: widget.category)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // 4. LOGIC LỌC DỮ LIỆU (Client-side Filtering)
          final filteredVehicles = docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return VehicleModel.fromMap(data, doc.id);
              })
              .where((vehicle) {
                // --- A. Lọc Địa điểm (SỬA LẠI LOGIC SO SÁNH) ---
                if (_selectedLocation != null) {
                  // Chuyển hết về chữ thường và xóa khoảng trắng để so sánh chính xác
                  final vLoc = vehicle.location.trim().toLowerCase();
                  final sLoc = _selectedLocation!.trim().toLowerCase();

                  if (vLoc != sLoc) {
                    return false; // Loại bỏ nếu không khớp
                  }
                }

                // --- B. Lọc Hãng xe ---
                if (_selectedBrand != null) {
                  final vBrand = vehicle.brand.trim().toLowerCase();
                  final sBrand = _selectedBrand!.trim().toLowerCase();
                  if (vBrand != sBrand) return false;
                }

                // --- C. Lọc Năm sx ---
                if (_selectedYear != null) {
                  if (vehicle.year != _selectedYear) return false;
                }

                return true; // Giữ lại nếu thỏa mãn tất cả
              })
              .toList();

          // Log kiểm tra kết quả
          // print("Tổng: ${docs.length} | Sau lọc: ${filteredVehicles.length}");

          // 5. HIỂN THỊ KẾT QUẢ
          if (filteredVehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_alt_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Không tìm thấy xe nào phù hợp bộ lọc.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedLocation = null;
                        _selectedBrand = null;
                        _selectedYear = null;
                      });
                    },
                    child: const Text("Xóa bộ lọc"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredVehicles.length, // Dùng list đã lọc
            itemBuilder: (context, index) {
              final vehicle = filteredVehicles[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
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
                  height: 120,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          vehicle.images.isNotEmpty
                              ? vehicle.images.first
                              : 'https://via.placeholder.com/150',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
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
                              "${vehicle.price} VNĐ",
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
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    vehicle.location,
                                    style: const TextStyle(
                                      color: Colors.grey,
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
          );
        },
      ),
    );
  }
}
