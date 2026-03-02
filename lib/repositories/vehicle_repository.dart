import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm để lưu một chiếc xe mới lên Firestore
  Future<void> addVehicle(VehicleModel vehicle) async {
    try {
      await _db.collection('vehicles').add(vehicle.toMap());
    } catch (e) {
      throw Exception("Lỗi khi đăng tin: $e");
    }
  }
}