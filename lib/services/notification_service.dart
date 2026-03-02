import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'notifications';

  // 1. Gửi thông báo (Dùng cho Admin hoặc Hệ thống)
  Future<void> sendNotification({
    required String receiverId, // ID người nhận
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      // Tạo model nhưng chưa có ID (Firestore tự sinh)
      final newNotif = NotificationModel(
        id: '', 
        userId: receiverId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        relatedId: relatedId,
      );

      await _firestore.collection(collectionName).add(newNotif.toJson());
      print("Đã gửi thông báo thành công cho $receiverId");
    } catch (e) {
      print("Lỗi gửi thông báo: $e");
    }
  }

  // 2. Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(collectionName).doc(notificationId).update({
      'isRead': true,
    });
  }

  // 3. Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(collectionName).doc(notificationId).delete();
  }
  
  // 4. Stream đếm số thông báo chưa đọc (Để hiện chấm đỏ)
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}