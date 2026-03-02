import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👇 1. IMPORT THƯ VIỆN FACEBOOK AUTH
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _user;
  UserModel? get user => _user;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Khai báo biến này dùng cho tiện
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> fetchUserData() async {
    _user = await _authRepo.getCurrentUserData();
    notifyListeners();
    startListeningToUserData();
  }

  void startListeningToUserData() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _userSubscription?.cancel();

    _userSubscription = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            _user = UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
            // print("🔄 Data User cập nhật Realtime: Follow = ${_user?.followers}");
            notifyListeners();
          }
        }, onError: (e) {
          print("Lỗi lắng nghe user: $e");
        });
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _userSubscription?.cancel();
    _userSubscription = null;
    await _auth.signOut();
    // 👇 Logout cả Facebook để lần sau nó hỏi lại tài khoản (tùy chọn)
    await FacebookAuth.instance.logOut(); 
    _user = null; 
    notifyListeners();
  }
// 1. Hàm cập nhật thông tin cá nhân
  Future<void> updateUserProfile({
    required String displayName,
    required String phoneNumber,
    required String address,
    File? newAvatar, // Ảnh mới (nếu có)
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String uid = _user!.uid;
      String? photoUrl = _user!.photoUrl;

      // Nếu có chọn ảnh mới -> Upload lên Storage
      if (newAvatar != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars/$uid.jpg');
        await storageRef.putFile(newAvatar);
        photoUrl = await storageRef.getDownloadURL();
      }

      // Cập nhật Firestore
      await _firestore.collection('users').doc(uid).update({
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'address': address,
        'photoUrl': photoUrl,
      });
      
      // Cập nhật User Auth (để hiển thị tên chuẩn ở các nơi khác)
      await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
      if (photoUrl != null) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(photoUrl);
      }

      // Load lại dữ liệu mới nhất
      await fetchUserData();

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Hàm đổi mật khẩu (Quan trọng)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Chưa đăng nhập");

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Bắt buộc xác thực lại trước khi đổi mật khẩu (Bảo mật của Firebase)
      await user.reauthenticateWithCredential(cred);

      // Đổi mật khẩu
      await user.updatePassword(newPassword);
      
    } catch (e) {
      // Bắt lỗi sai mật khẩu cũ
      if (e.toString().contains('wrong-password')) {
        throw Exception("Mật khẩu cũ không chính xác");
      }
      rethrow;
    }
  }
  // ... (Giữ nguyên hàm register) ...
Future<void> register(String email, String password, String name, String phone, String address) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 👇 GỌI REPO
      await _authRepo.register(
        email: email, 
        password: password, 
        name: name,
        phone: phone,
        address: address
      );
      
      // Sau khi đăng ký xong, user đã được tạo và login, load data lên
      await fetchUserData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (Giữ nguyên hàm createStore) ...
  Future<void> createStore({
    required String storeName,
    required String address,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _user!.uid;
      await _firestore.collection('users').doc(uid).update({
        'storeName': storeName,
        'address': address,
        'description': description,
      });
      await fetchUserData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (Giữ nguyên hàm login thường) ...
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepo.login(email, password);
      await fetchUserData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 👇👇👇 2. THÊM HÀM ĐĂNG NHẬP FACEBOOK 👇👇👇
  Future<void> loginWithFacebook() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Mở popup đăng nhập Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // 2. Lấy Access Token
        final AccessToken accessToken = result.accessToken!;

        // 3. Tạo Credential để đăng nhập Firebase
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

        // 4. Đăng nhập vào Firebase
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          // 5. Kiểm tra xem user này đã có trong Firestore chưa
          // Nếu chưa (lần đầu login bằng FB) thì tạo mới
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

          if (!doc.exists) {
            // Tạo User Model mới từ thông tin Facebook
            // Lưu ý: Facebook có thể không trả về email hoặc sđt tùy quyền riêng tư
            UserModel newUser = UserModel(
              uid: user.uid,
              email: user.email ?? "", 
              displayName: user.displayName ?? "Người dùng Facebook",
              phoneNumber: user.phoneNumber ?? "", // FB thường ko trả về sđt
              address: "", // FB không có địa chỉ cụ thể
              photoUrl: user.photoURL, // Lấy ảnh đại diện từ FB
              role: UserRole.user,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );

            // Lưu vào Firestore
            await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
            _user = newUser;
          } else {
            // Nếu đã có thì cập nhật thời gian đăng nhập (tùy chọn)
            await _firestore.collection('users').doc(user.uid).update({
              'lastLoginAt': FieldValue.serverTimestamp(),
            });
            // Load thông tin lên
            await fetchUserData();
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception("Bạn đã hủy đăng nhập Facebook.");
      } else {
        throw Exception("Lỗi đăng nhập Facebook: ${result.message}");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // 👆👆👆 HẾT PHẦN THÊM MỚI 👆👆👆


  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  // ... (Giữ nguyên các hàm requestUpgradeToSeller, submitSellerRequest) ...
  Future<void> requestUpgradeToSeller() async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try { 
      await _firestore.collection('users').doc(_user!.uid).update({'isPendingUpgrade': true});
      await fetchUserData(); 
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> submitSellerRequest({
    required String fullName,
    required String citizenId,
    required String address,
    required File? frontImage,
    required File? backImage,
  }) async {
    if (_user == null) return;
    if (frontImage == null || backImage == null) throw Exception("Vui lòng chọn đủ ảnh CCCD");

    _isLoading = true;
    notifyListeners();

    try {
      String uid = _user!.uid;
      final storageRef = FirebaseStorage.instance.ref().child('seller_requests/$uid');
      
      final frontRef = storageRef.child('front.jpg');
      UploadTask uploadTaskFront = frontRef.putFile(frontImage);
      TaskSnapshot snapshotFront = await uploadTaskFront;
      final String frontUrl = await snapshotFront.ref.getDownloadURL();

      final backRef = storageRef.child('back.jpg');
      UploadTask uploadTaskBack = backRef.putFile(backImage);
      TaskSnapshot snapshotBack = await uploadTaskBack;
      final String backUrl = await snapshotBack.ref.getDownloadURL();

      await _firestore.collection('seller_requests').doc(uid).set({
        'uid': uid,
        'email': _user!.email,
        'phoneNumber': _user!.phoneNumber,
        'fullName': fullName,
        'citizenId': citizenId,
        'address': address,
        'frontIdUrl': frontUrl,
        'backIdUrl': backUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(uid).update({
        'isPendingUpgrade': true
      });
      
      await fetchUserData();

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}