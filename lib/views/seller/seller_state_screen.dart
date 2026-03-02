import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellerStatsScreen extends StatefulWidget {
  const SellerStatsScreen({super.key});

  @override
  State<SellerStatsScreen> createState() => _SellerStatsScreenState();
}

class _SellerStatsScreenState extends State<SellerStatsScreen> {
  // Biến cho bộ lọc tổng sản phẩm
  DateTimeRange? _selectedDateRange;
  int _totalProductsSold = 0;
  bool _isLoadingCount = false;

  // Doanh thu theo sản phẩm trong khoảng thời gian chọn
  Map<String, double> _revenueByProduct = {}; // productId -> revenue
  Map<String, int> _quantityByProduct = {}; // productId -> quantity sold
  Map<String, String> _productNames = {}; // productId -> title
  bool _isLoadingProductRevenue = false;

  // Biến cho biểu đồ doanh thu
  int _selectedYear = DateTime.now().year;
  Map<int, double> _monthlyRevenue = {}; // Tháng (1-12) : Doanh thu
  bool _isLoadingChart = false;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn tháng hiện tại cho bộ lọc sản phẩm
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );

    _fetchStats();
  }

  void _fetchStats() {
    _calculateProductsSold();
    _calculateRevenueByProduct();
    _calculateMonthlyRevenue();
  }

  // --- HÀM FIX LỖI: TẠO ORDER CHO CÁC XE ĐÃ BÁN TỪ TRƯỚC ---
  Future<void> _syncOldOrders(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đồng bộ dữ liệu?"),
        content: const Text(
          "Hệ thống sẽ quét các xe 'Đã bán' trong quá khứ và tạo dữ liệu thống kê cho chúng. Bạn chỉ cần chạy cái này 1 lần.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Đồng bộ"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingCount = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;

      // 1. Lấy tất cả xe ĐÃ BÁN của người này
      final soldVehicles = await db
          .collection('vehicles')
          .where('ownerId', isEqualTo: uid)
          .where('status', isEqualTo: 'sold')
          .get();

      int fixedCount = 0;
      WriteBatch batch = db.batch();

      for (var doc in soldVehicles.docs) {
        final vehicleData = doc.data();

        // 2. Kiểm tra xem xe này đã có Order chưa (tránh tạo trùng)
        final existingOrder = await db
            .collection('orders')
            .where('vehicleId', isEqualTo: doc.id)
            .get();

        if (existingOrder.docs.isEmpty) {
          // 3. Nếu chưa có Order -> Tạo mới
          final orderRef = db.collection('orders').doc(); // Tự sinh ID

          // Lấy giá tiền và ngày tạo từ xe cũ
          double price = (vehicleData['price'] ?? 0).toDouble();
          // Lấy ngày bán (Vì xe cũ k lưu ngày bán, ta lấy tạm ngày tạo xe hoặc ngày hiện tại)
          // Tốt nhất lấy createdAt của xe để biểu đồ rải đều ra các tháng cũ
          Timestamp vehicleCreatedAt =
              vehicleData['createdAt'] ?? Timestamp.now();

          batch.set(orderRef, {
            'sellerId': uid,
            'vehicleId': doc.id,
            'vehicleName': vehicleData['title'] ?? 'Xe đã bán',
            'totalPrice': price,
            'status': 'completed',
            'createdAt': vehicleCreatedAt, // Dùng ngày tạo của xe làm ngày bán
            'items': [
              {
                'id': doc.id,
                'price': price,
                'title': vehicleData['title'] ?? 'Xe cũ',
              },
            ],
          });
          fixedCount++;
        }
      }

      // 4. Thực thi
      if (fixedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Đã khôi phục $fixedCount đơn hàng cũ!")),
          );
          _fetchStats(); // Load lại thống kê ngay
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dữ liệu đã đồng bộ, không cần cập nhật thêm."),
            ),
          );
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ: $e");
    } finally {
      setState(() => _isLoadingCount = false);
    }
  }

  // --- LOGIC 1: TÍNH TỔNG SẢN PHẨM BÁN ĐƯỢC ---
  Future<void> _calculateProductsSold() async {
    if (_selectedDateRange == null) return;
    setState(() => _isLoadingCount = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: _selectedDateRange!.start)
          .where('createdAt', isLessThanOrEqualTo: _selectedDateRange!.end)
          .get();

      int count = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Kiểm tra an toàn: Nếu có items thì đếm items, nếu không thì tính là 1 đơn
        if (data['items'] != null && data['items'] is List) {
          List items = data['items'];
          count += items.isNotEmpty ? items.length : 1;
        } else {
          count += 1; // Fallback: 1 đơn hàng = 1 sản phẩm
        }
      }

      setState(() => _totalProductsSold = count);

      // Log để debug
      print(
        "Tìm thấy ${querySnapshot.docs.length} đơn hàng. Tổng sp tính được: $count",
      );
    } catch (e) {
      print("Lỗi tính sản phẩm: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  // --- LOGIC 3: TÍNH DOANH THU THEO SẢN PHẨM TRONG KHOẢNG THỜI GIAN CHỌN ---
  Future<void> _calculateRevenueByProduct() async {
    if (_selectedDateRange == null) return;
    setState(() => _isLoadingProductRevenue = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: _selectedDateRange!.start)
          .where('createdAt', isLessThanOrEqualTo: _selectedDateRange!.end)
          .get();

      Map<String, double> rev = {};
      Map<String, int> qty = {};
      Map<String, String> names = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Nếu order có items: cộng từng item
        if (data['items'] != null && data['items'] is List) {
          List items = data['items'];
          for (var item in items) {
            final id = (item['id'] ?? '').toString();
            if (id.isEmpty) continue;

            double price = 0;
            if (item['price'] != null) {
              price = (item['price'] is int)
                  ? (item['price'] as int).toDouble()
                  : (item['price'] as double);
            } else if (data['totalPrice'] != null) {
              price = (data['totalPrice'] is int)
                  ? (data['totalPrice'] as int).toDouble()
                  : (data['totalPrice'] as double);
            }

            rev[id] = (rev[id] ?? 0) + price;
            qty[id] = (qty[id] ?? 0) + 1;
            names[id] = (item['title'] ?? data['vehicleName'] ?? 'Sản phẩm')
                .toString();
          }
        } else {
          // Nếu không có items, gán toàn bộ order cho vehicleId hoặc doc.id
          final id = (data['vehicleId'] ?? doc.id).toString();
          double price = 0;
          if (data['totalPrice'] != null) {
            price = (data['totalPrice'] is int)
                ? (data['totalPrice'] as int).toDouble()
                : (data['totalPrice'] as double);
          }
          rev[id] = (rev[id] ?? 0) + price;
          qty[id] = (qty[id] ?? 0) + 1;
          names[id] = (data['vehicleName'] ?? 'Sản phẩm').toString();
        }
      }

      if (mounted)
        setState(() {
          _revenueByProduct = rev;
          _quantityByProduct = qty;
          _productNames = names;
        });
      print('Doanh thu theo sản phẩm: $_revenueByProduct');
    } catch (e) {
      print('Lỗi tính doanh thu theo sản phẩm: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProductRevenue = false);
    }
  }

  // --- LOGIC 2: TÍNH DOANH THU TỪNG THÁNG ---
  Future<void> _calculateMonthlyRevenue() async {
    setState(() => _isLoadingChart = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Tạo timestamp đầu năm và cuối năm
      final startOfYear = DateTime(_selectedYear, 1, 1);
      final endOfYear = DateTime(_selectedYear, 12, 31, 23, 59, 59);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          ) // Convert sang Timestamp rõ ràng
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfYear),
          )
          .get();

      // Reset data về 0 hết
      Map<int, double> tempRevenue = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // 1. Xử lý ngày tháng an toàn
        DateTime date;
        if (data['createdAt'] is Timestamp) {
          date = (data['createdAt'] as Timestamp).toDate();
        } else {
          continue; // Bỏ qua nếu không có ngày tháng hợp lệ
        }

        // 2. Xử lý giá tiền an toàn (chấp nhận cả Int và Double)
        double price = 0;
        if (data['totalPrice'] != null) {
          price = (data['totalPrice'] is int)
              ? (data['totalPrice'] as int).toDouble()
              : (data['totalPrice'] as double);
        }

        // Cộng dồn
        tempRevenue[date.month] = (tempRevenue[date.month] ?? 0) + price;
      }

      setState(() => _monthlyRevenue = tempRevenue);
      print("Dữ liệu biểu đồ năm $_selectedYear: $tempRevenue");
    } catch (e) {
      print("Lỗi tính doanh thu: $e");
    } finally {
      if (mounted) setState(() => _isLoadingChart = false);
    }
  }

  // Widget chọn ngày
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _calculateProductsSold();
      _calculateRevenueByProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productEntries = _revenueByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalRevenue = _revenueByProduct.values.fold<double>(0.0, (p, c) => p + c);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Thống kê bán hàng",
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
            ),
          ),
        ),
        // 👇 THÊM NÚT NÀY ĐỂ FIX LỖI DỮ LIỆU
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: "Đồng bộ dữ liệu cũ",
            onPressed: () => _syncOldOrders(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: TỔNG SẢN PHẨM ---
            const Text(
              "Tổng quan sản phẩm",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Thời gian:",
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDateRange == null
                                ? "Chọn ngày"
                                : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _isLoadingCount
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              Text(
                                "$_totalProductsSold",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const Text("Sản phẩm đã bán (hoàn thành)"),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Doanh thu theo sản phẩm trong khoảng thời gian đã chọn
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Doanh thu theo sản phẩm",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng doanh thu:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            NumberFormat.compactCurrency(locale: 'vi', symbol: 'đ').format(totalRevenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingProductRevenue)
                      const Center(child: CircularProgressIndicator()),
                    if (!_isLoadingProductRevenue && productEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Chưa có dữ liệu doanh thu trong khoảng thời gian này.",
                        ),
                      ),
                    if (!_isLoadingProductRevenue && productEntries.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          itemCount: productEntries.length,
                          itemBuilder: (context, index) {
                            final entry = productEntries[index];
                            final id = entry.key;
                            final revenue = entry.value;
                            final count = _quantityByProduct[id] ?? 0;
                            final name = _productNames[id] ?? id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name),
                              // subtitle: Text('Số lượng: $count'),
                              trailing: Text(
                                NumberFormat.compactCurrency(
                                  locale: 'vi',
                                  symbol: 'đ',
                                ).format(revenue),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- PHẦN 2: BIỂU ĐỒ DOANH THU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Biểu đồ doanh thu",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (index) {
                    int year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text("Năm $year"),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _calculateMonthlyRevenue();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6),
                ],
              ),
              child: _isLoadingChart
                  ? const Center(child: CircularProgressIndicator())
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            _monthlyRevenue.values.fold<double>(
                              0.0,
                              (p, c) => p > c ? p : c,
                            ) *
                            1.2, // Tăng đỉnh biểu đồ lên chút
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                NumberFormat.compactCurrency(
                                  locale: 'vi',
                                  symbol: 'đ',
                                ).format(rod.toY),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    "T${value.toInt()}",
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ), // Ẩn số bên trái cho gọn
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(12, (index) {
                          int month = index + 1;
                          return BarChartGroupData(
                            x: month,
                            barRods: [
                              BarChartRodData(
                                toY: _monthlyRevenue[month] ?? 0,
                                color: Colors.blueAccent,
                                width: 12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
