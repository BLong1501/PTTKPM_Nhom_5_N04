import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverName;
  final String receiverId;
  final String vehicleTitle;
  final String vehicleId;
  final String? receiverAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.receiverName,
    required this.receiverId,
    required this.vehicleTitle,
    required this.vehicleId,
    required this.receiverAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  // --- 1. Gửi tin nhắn Text ---
  void _handleSend() async {
    if (_msgController.text.trim().isEmpty) return;
    final String msg = _msgController.text.trim();
    _msgController.clear();

    try {
      await Provider.of<ChatProvider>(context, listen: false).sendMessage(
        chatRoomId: widget.chatRoomId,
        message: msg,
        senderId: currentUserId,
        receiverId: widget.receiverId,
        vehicleId: widget.vehicleId,
        vehicleTitle: widget.vehicleTitle,
        receiverName: widget.receiverName,
        type: 'text',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể gửi: ${e.toString().replaceAll('Exception:', '')}")),
        );
      }
    }
  }

  // --- 2. Gửi ảnh ---
  void _handleSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        await Provider.of<ChatProvider>(context, listen: false).sendImageMessage(
          chatRoomId: widget.chatRoomId,
          imageFile: File(image.path),
          senderId: currentUserId,
          receiverId: widget.receiverId,
          vehicleId: widget.vehicleId,
          vehicleTitle: widget.vehicleTitle,
          receiverName: widget.receiverName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi gửi ảnh: ${e.toString().replaceAll('Exception:', '')}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.receiverAvatar != null && widget.receiverAvatar!.isNotEmpty
                  ? NetworkImage(widget.receiverAvatar!)
                  : null,
              child: widget.receiverAvatar == null || widget.receiverAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                  Text(
                    widget.vehicleTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded),
            tooltip: 'Xem hồ sơ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublicProfileScreen(userId: widget.receiverId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(backgroundColor: Colors.transparent),

          // --- 1. DANH SÁCH TIN NHẮN (Giữ nguyên) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bắt đầu cuộc trò chuyện!"));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;
                    final String messageContent = msg['message'] ?? '';
                    final String type = msg['type'] ?? 'text';
                    final bool isImage = type == 'image' || messageContent.startsWith('https://firebasestorage.googleapis.com');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isImage 
                            ? Colors.transparent 
                            : (isMe ? Colors.blue : Colors.grey[300]),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(messageContent, width: 200, height: 200, fit: BoxFit.cover),
                              )
                            : Text(
                                messageContent,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- 2. LOGIC KIỂM SOÁT THANH CHAT (QUAN TRỌNG) ---
          // Stream 1: Kiểm tra xem TÔI có chặn HỌ không?
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
            builder: (context, mySnapshot) {
              bool iBlockedThem = false;
              if (mySnapshot.hasData && mySnapshot.data!.exists) {
                final myData = mySnapshot.data!.data() as Map<String, dynamic>?;
                final List myBlockedList = myData?['blockedUsers'] ?? [];
                if (myBlockedList.contains(widget.receiverId)) iBlockedThem = true;
              }

              // Stream 2: Kiểm tra xem HỌ có chặn TÔI không?
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
                builder: (context, theirSnapshot) {
                  bool theyBlockedMe = false;
                  if (theirSnapshot.hasData && theirSnapshot.data!.exists) {
                    final theirData = theirSnapshot.data!.data() as Map<String, dynamic>?;
                    final List theirBlockedList = theirData?['blockedUsers'] ?? [];
                    if (theirBlockedList.contains(currentUserId)) theyBlockedMe = true;
                  }

                  // --- XỬ LÝ GIAO DIỆN DỰA TRÊN 2 BIẾN TRÊN ---

                  // Trường hợp 1: TÔI đang chặn HỌ -> Ưu tiên hiện nút mở chặn
                  if (iBlockedThem) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          const Text("Bạn đã chặn người dùng này.", style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            onPressed: () async {
                              await Provider.of<ChatProvider>(context, listen: false)
                                  .unblockUser(currentUserId, widget.receiverId);
                            },
                            child: const Text("Bỏ chặn để trò chuyện"),
                          ),
                        ],
                      ),
                    );
                  }

                  // Trường hợp 2: HỌ đang chặn TÔI -> Ẩn ô chat, báo lỗi
                  if (theyBlockedMe) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          "Bạn không thể nhắn tin cho người dùng này.",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }

                  // Trường hợp 3: Không ai chặn ai -> Hiện ô chat bình thường
                  return Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: _handleSendImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            decoration: InputDecoration(
                              hintText: "Nhập tin nhắn...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _handleSend,
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}