import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Dữ liệu Categories
  final List<String> categories = [
    'Xe máy', 'Ô tô', 'Xe đạp', 'Xe tải', 'Xe điện', 'Phụ tùng', 'Tàu thuyền','Khác'
  ];

  // 2. Mapping Hãng xe (ĐÃ BỔ SUNG TESLA & CẬP NHẬT)
  final Map<String, List<String>> brandMapping = {
    'Xe máy': [
      'Honda', 'Yamaha', 'Suzuki', 'Piaggio', 'SYM', 'VinFast', 'Ducati', 'Kawasaki', 'BMW','Khác',
    ],
    'Ô tô': [
      'Toyota', 'Hyundai', 'Kia', 'Mazda', 'Ford', 'Honda', 'VinFast', 
      'Mercedes', 'BMW', 'Audi', 'Lexus', 'Mitsubishi', 'Tesla', 'Land Rover', 'Porsche','Khác',
    ],
    'Xe đạp': [
      'Asama', 'Giant', 'Martin', 'Thống Nhất', 'Galaxy','Khác',
    ],
    'Xe tải': [
      'Thaco', 'Hyundai', 'Isuzu', 'Hino', 'Dongfeng', 'Fuso', 'Kia', 'JAC', 'Howo','Khác',
    ],
    'Xe điện': [
      'VinFast', 'Pega', 'Yadea', 'Dat Bike', 'Tesla','Khác',// Tesla cũng là xe điện
    ]
  };

  final List<String> fuelTypes = ['Xăng', 'Dầu', 'Điện', 'Hybrid','Khác',];

  final List<String> locations = [
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ', 'Nghệ An', 'Thanh Hóa', 'Huế',
    'Bình Dương', 'Đồng Nai', 'Quảng Ninh', 'Toàn quốc' ,'Khác',// Thêm vài tỉnh hay mua bán xe
  ];

  // --- 3. CÁC MỤC MỚI BỔ SUNG ---
  final List<String> colors = ['Đen', 'Trắng', 'Đỏ', 'Bạc', 'Xám', 'Xanh', 'Vàng', 'Cam', 'Nâu', 'Khác',];
  
  final List<String> conditions = ['Xe mới', 'Đã sử dụng', 'Xe lướt (Like New)'];
  
  final List<String> gearboxes = ['Số tự động', 'Số sàn', 'Bán tự động'];


  // --- HÀM CHẠY SEED ---
  Future<void> seedData() async {
    print("⏳ Đang bắt đầu đẩy dữ liệu...");
    
    // Upload từng phần
    await _uploadSimpleList('categories', categories);
    await _uploadSimpleList('fuel_types', fuelTypes);
    await _uploadSimpleList('locations', locations);
    
    // Upload các mục mới bổ sung
    await _uploadSimpleList('colors', colors);
    await _uploadSimpleList('conditions', conditions);
    await _uploadSimpleList('gearboxes', gearboxes);

    // Upload Brands logic phức tạp
    await _uploadBrands();
    
    print(" Đã khởi tạo dữ liệu thành công!");
  }

  // Hàm upload danh sách đơn giản (Có merge: true để không mất dữ liệu cũ nếu có field khác)
  Future<void> _uploadSimpleList(String collectionName, List<String> items) async {
    // Lưu ý: Nếu list > 500 item phải chia batch, nhưng ở đây list ngắn nên OK
    WriteBatch batch = _db.batch();
    
    for (var item in items) {
      final docRef = _db.collection(collectionName).doc(item);
      batch.set(docRef, {
        'name': item,
        // Dùng SetOptions merge để không ghi đè mất field khác (nếu sau này bạn thêm ảnh icon cho category chẳng hạn)
      }, SetOptions(merge: true)); 
    }
    await batch.commit();
    print("   -> Đã xong collection: $collectionName");
  }

  // Hàm xử lý Brands
  Future<void> _uploadBrands() async {
    WriteBatch batch = _db.batch();
    int count = 0; // Đếm để tránh quá 500

    for (var entry in brandMapping.entries) {
      String category = entry.key; 
      List<String> brands = entry.value;

      for (var brandName in brands) {
        final docRef = _db.collection('brands').doc(brandName);
        
        batch.set(docRef, {
          'name': brandName,
          'types': FieldValue.arrayUnion([category]), 
        }, SetOptions(merge: true));

        count++;
        // Kỹ thuật an toàn: Nếu batch đầy 450 item thì commit rồi tạo batch mới
        if (count >= 450) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
    }
    await batch.commit(); // Commit nốt số còn lại
    print("   -> Đã xong Brands (Có xử lý gộp loại xe)");
  }
}