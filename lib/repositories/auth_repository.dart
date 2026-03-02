import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:device_info_plus/device_info_plus.dart'; 
import 'dart:io'; 

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy thông tin User hiện tại
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      print("Lỗi lấy dữ liệu user: $e");
      return null;
    }
  }

  // 2. HÀM GHI LOG (QUAN TRỌNG)
  Future<void> logActivity(String userId, String action) async {
    try {
      String deviceName = 'Thiết bị lạ';
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.brand} ${androidInfo.model}"; 
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = "${iosInfo.name} ${iosInfo.systemName}"; 
      }

      await _db
          .collection('users')
          .doc(userId)
          .collection('activity_logs')
          .add({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceName': deviceName,
      });
    } catch (e) {
      print("Lỗi ghi log: $e"); 
    }
  }

  // 3. ĐĂNG NHẬP (Tự ghi log)
  Future<UserCredential> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      if (cred.user != null) {
        await logActivity(cred.user!.uid, "Đăng nhập"); // Ghi log
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // 4. ĐĂNG XUẤT (Tự ghi log)
  Future<void> logout() async {
    try {
      if (_auth.currentUser != null) {
        await logActivity(_auth.currentUser!.uid, "Đăng xuất"); // Ghi log
      }
      await _auth.signOut();
    } catch (e) {
      print("Lỗi đăng xuất: $e");
    }
  }

  // 5. Đăng ký (Tự ghi log)
  Future<void> register({
    required String email, 
    required String password, 
    required String name,
    String? phone,    
    String? address,  
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    UserModel newUser = UserModel(
      uid: credential.user!.uid, 
      email: email, 
      displayName: name,
      phoneNumber: phone,       
      address: address,         
      role: UserRole.user,
      isActive: true,
      isPendingUpgrade: false,
      favoritePostIds: [],
      createdAt: DateTime.now(),
      followers: 0, 
      following: 0, 
    );
    
    await _db.collection('users').doc(credential.user!.uid).set(newUser.toMap());
    
    // Ghi log đăng ký
    await logActivity(credential.user!.uid, "Đăng ký tài khoản");
  }
}