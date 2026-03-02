import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. HÀM TẠO ID PHÒNG CHAT ---
  String getChatRoomId(String userId, String otherUserId, String vehicleId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    return "${ids[0]}_${ids[1]}_$vehicleId";
  }

  // --- 2. GỬI ẢNH ---
  Future<void> sendImageMessage({
    required String chatRoomId,
    required File imageFile,
    required String senderId,
    required String receiverId,
    required String vehicleId,
    required String vehicleTitle,
    required String receiverName,
  }) async {
    // Kiểm tra chặn trước khi upload
    bool isBlocked = await checkIsBlocked(senderId, receiverId);
    if (isBlocked) {
      throw Exception("Bạn không thể gửi tin nhắn cho người dùng này.");
    }

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatRoomId)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await sendMessage(
        chatRoomId: chatRoomId,
        message: downloadUrl,
        senderId: senderId,
        receiverId: receiverId,
        vehicleId: vehicleId,
        vehicleTitle: vehicleTitle,
        receiverName: receiverName,
        type: 'image', 
      );
    } catch (e) {
      print("Error sending image: $e");
      rethrow;
    }
  }

  // --- 3. GỬI TIN NHẮN ---
  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    required String senderId,
    required String receiverId,
    required String vehicleId,
    required String vehicleTitle,
    String? receiverName,
    String? receiverAvatar,
    String type = 'text',
  }) async {
    // Kiểm tra chặn trước khi gửi
    bool isBlocked = await checkIsBlocked(senderId, receiverId);
    if (isBlocked) {
      throw Exception("Cuộc trò chuyện đã bị chặn."); 
    }

    final Timestamp timestamp = Timestamp.now();

    // 1. Lưu tin nhắn chi tiết
    Map<String, dynamic> messageData = {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
      "isRead": false,
      "type": type,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // 2. Cập nhật thông tin phòng chat bên ngoài
    String previewMessage = type == 'image' ? "[Hình ảnh]" : message;

    Map<String, dynamic> chatRoomData = {
      "chatRoomId": chatRoomId,
      "participants": [senderId, receiverId],
      "users": [senderId, receiverId], 
      "lastMessage": previewMessage,
      "lastTime": timestamp,
      "vehicleId": vehicleId,
      "vehicleTitle": vehicleTitle,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set(chatRoomData, SetOptions(merge: true));
  }

  // --- 4. ĐÁNH DẤU ĐÃ ĐỌC ---
  Future<void> markAsRead(String chatRoomId, String currentUserId) async {
    try {
      final unreadDocs = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      if (unreadDocs.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print("Lỗi markAsRead: $e");
    }
  }

  // --- 5. XÓA CUỘC TRÒ CHUYỆN ---
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).delete();
    } catch (e) {
      print("Lỗi xóa chat: $e");
      rethrow;
    }
  }

  // --- 6. CHẶN NGƯỜI DÙNG (Sửa lại dùng set merge) ---
  Future<void> blockUser(String currentUserId, String userToBlockId) async {
    try {
      // Dùng set + merge: true để nếu chưa có document user thì tự tạo
      await _firestore.collection('users').doc(currentUserId).set({
        'blockedUsers': FieldValue.arrayUnion([userToBlockId])
      }, SetOptions(merge: true));
    } catch (e) {
      print("Lỗi block user: $e");
      rethrow;
    }
  }

  // --- 7. BỎ CHẶN (Sửa lại dùng set merge) ---
  Future<void> unblockUser(String currentUserId, String userToUnblockId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).set({
        'blockedUsers': FieldValue.arrayRemove([userToUnblockId])
      }, SetOptions(merge: true));
    } catch (e) {
      print("Lỗi unblock user: $e");
      rethrow;
    }
  }
 
  // --- 8. KIỂM TRA TRẠNG THÁI CHẶN ---
  Future<bool> checkIsBlocked(String currentUserId, String otherUserId) async {
    try {
      // Kiểm tra xem mình có chặn họ không
      DocumentSnapshot myDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (myDoc.exists) {
        List myBlocked = (myDoc.data() as Map<String, dynamic>)['blockedUsers'] ?? [];
        if (myBlocked.contains(otherUserId)) return true;
      }

      // Kiểm tra xem họ có chặn mình không
      DocumentSnapshot otherDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (otherDoc.exists) {
        List theirBlocked = (otherDoc.data() as Map<String, dynamic>)['blockedUsers'] ?? [];
        if (theirBlocked.contains(currentUserId)) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}