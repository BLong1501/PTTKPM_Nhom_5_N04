import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

// 1. TẠO CLASS MỚI ĐỂ CHỨA DỮ LIỆU HÃNG XE (Gồm Tên + Danh sách loại hỗ trợ)
class BrandData {
  final String name;
  final List<String> types; // Ví dụ: ["Xe máy", "Ô tô"]

  BrandData({required this.name, required this.types});
}

class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _repo = VehicleRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. CÁC BIẾN DỮ LIỆU
  List<String> _categories = [];
  
  // SỬA: Thay vì List<String>, ta dùng List<BrandData> để lưu chi tiết hơn
  List<BrandData> _allBrands = []; 
  
  List<String> _fuelTypes = [];
  List<String> _locations = [];

  // Getter
  List<String> get categories => _categories;
  List<String> get fuelTypes => _fuelTypes;
  List<String> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  // ...
  List<String> _colors = []; // 1. Thêm biến chứa màu
  List<String> get colors => _colors; // Getter

  // 3. HÀM MỚI: LỌC BRAND THEO CATEGORY
  // Hàm này sẽ được gọi từ UI (AddVehicleScreen)
  List<String> getBrandsByCategory(String? category) {
    if (category == null) return []; // Chưa chọn loại xe thì trả về rỗng

    // Lọc trong danh sách _allBrands, tìm những ông nào có chứa category này
    return _allBrands
        .where((brand) => brand.types.contains(category))
        .map((brand) => brand.name) // Chỉ lấy ra tên để hiện lên Dropdown
        .toList();
  }

  // 4. HÀM TẢI CẤU HÌNH TỪ FIREBASE (Đã cập nhật logic lấy brands)
  Future<void> fetchAppConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _db.collection('categories').get(),
        _db.collection('brands').get(),
        _db.collection('fuel_types').get(),
        _db.collection('locations').get(),
        _db.collection('colors').get(), // 2. Lấy thêm collection 'colors'
      ]);

      // Lấy Categories
      _categories = results[0].docs.map((d) => d['name'] as String).toList();

      // SỬA: Lấy Brands (kèm theo field 'types')
      _allBrands = results[1].docs.map((d) {
        return BrandData(
          name: d['name'] as String,
          // Lấy mảng 'types' từ Firestore, nếu null thì trả về mảng rỗng
          types: List<String>.from(d['types'] ?? []), 
        );
      }).toList();

      // Lấy Fuel & Locations
      _fuelTypes = results[2].docs.map((d) => d['name'] as String).toList();
      _locations = results[3].docs.map((d) => d['name'] as String).toList();
      _colors = results[4].docs.map((d) => d['name'] as String).toList();
      
    } catch (e) {
      print("Lỗi tải cấu hình: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. Hàm đăng xe (Giữ nguyên)
Future<bool> uploadVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Gọi Repo để lưu
      await _repo.addVehicle(vehicle);
      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Hàm upload danh sách ảnh
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> downloadUrls = [];
    
    _isLoading = true;
    notifyListeners();


    try {
      for (var image in images) {
        // Tạo tên file duy nhất: vehicles/timestamp_filename
        String fileName = "${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}";
        final ref = FirebaseStorage.instance.ref().child('vehicles/$fileName');
        
        // Upload
        await ref.putFile(image);
        
        // Lấy link
        String url = await ref.getDownloadURL();
        downloadUrls.add(url);
      }
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      // Có thể ném lỗi hoặc trả về list rỗng tùy logic
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return downloadUrls;
  }
  Future<bool> updateVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    notifyListeners();
    try {
      print("Đang cập nhật xe ID: ${vehicle.id}");
      
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicle.id) // Tìm đúng document theo ID
          .update(vehicle.toMap()); // Ghi đè dữ liệu mới

      return true;
    } catch (e) {
      print("Lỗi cập nhật: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}