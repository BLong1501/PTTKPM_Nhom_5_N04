import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;      // Người nhận
  final String title;       // Tiêu đề
  final String body;        // Nội dung
  final String type;        // Loại: approved, rejected, banned, follow...
  final bool isRead;        // Đã xem chưa
  final DateTime createdAt; // Thời gian
  final String? relatedId;  // ID liên quan (ID xe, ID người bán...)

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  // Chuyển từ Firestore Document sang Model
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      relatedId: data['relatedId'],
    );
  }

  // Chuyển từ Model sang JSON để lưu lên Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedId': relatedId,
    };
  }
}