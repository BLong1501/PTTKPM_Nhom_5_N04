import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String brand;
  final String category;
  final int year;
  final int mileage;
  final String fuelType;
  final String location;
  final List<String> images;
  final String contactPhone;
  final DateTime createdAt;
  final String status;

  // --- CÁC TRƯỜNG MỚI ---
  final String condition; 
  final String origin;    
  final String capacity;  
  final int weight;     
  final String? storeName;   
  final String color;

  VehicleModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.year,
    required this.mileage,
    required this.fuelType,
    required this.location,
    required this.images,
    required this.contactPhone,
    required this.createdAt,
    required this.status,
    required this.condition,
    required this.origin,
    required this.capacity,
    required this.weight,
    required this.color,
    this.storeName, // storeName có thể null, bỏ required đi
  });

  // Chuyển Object -> Map để lưu lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'brand': brand,
      'category': category,
      'year': year,
      'mileage': mileage,
      'fuelType': fuelType,
      'location': location,
      'images': images,
      'contactPhone': contactPhone,
      'createdAt': Timestamp.fromDate(createdAt), // Đổi DateTime sang Timestamp
      'status': status,
      'condition': condition,
      'origin': origin,
      'capacity': capacity,
      'weight': weight,
      'color': color,
      'storeName': storeName,
    };
  }

  // Chuyển Map -> Object (Dùng khi bạn đã có Map sẵn)
  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      year: map['year'] ?? 0,
      mileage: map['mileage'] ?? 0,
      fuelType: map['fuelType'] ?? '',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      contactPhone: map['contactPhone'] ?? '',
      // Kiểm tra null cho an toàn
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      condition: map['condition'] ?? 'Đã sử dụng',
      origin: map['origin'] ?? 'Lắp ráp trong nước',
      capacity: map['capacity'] ?? '',
      weight: map['weight'] ?? 0,
      color: map['color'] ?? 'Khác',
      storeName: map['storeName'],
    );
  }

  // --- THÊM HÀM NÀY ĐỂ SỬA LỖI ---
  // Chuyển DocumentSnapshot -> Object (Dùng trong NotificationScreen)
  factory VehicleModel.fromSnapshot(DocumentSnapshot doc) {
    // Gọi lại hàm fromMap ở trên cho gọn code
    // doc.data() lấy dữ liệu, doc.id lấy ID của document
    return VehicleModel.fromMap(
      doc.data() as Map<String, dynamic>, 
      doc.id
    );
  }
}