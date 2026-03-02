import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_app/views/chat/chat_detail_screen.dart';
import 'package:my_app/providers/chat_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin nhắn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // 👇 STREAM 1: LẮNG NGHE LIST CHẶN CỦA CHÍNH MÌNH (QUAN TRỌNG ĐỂ NÚT ĐỔI MÀU)
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Xử lý danh sách chặn an toàn (Ép kiểu sang List<String>)
          List<String> blockedUsers = [];
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data['blockedUsers'] != null) {
              blockedUsers = List<String>.from(data['blockedUsers']);
            }
          }

          // 👇 STREAM 2: LẤY DANH SÁCH CHAT ROOMS
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_rooms')
                .where('participants', arrayContains: currentUserId)
                .orderBy('lastTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("Chưa có tin nhắn nào", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final chatDocs = snapshot.data!.docs;

              return ListView.separated(
                itemCount: chatDocs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final chatRoomDoc = chatDocs[index];
                  final data = chatRoomDoc.data() as Map<String, dynamic>;
                  final String chatRoomId = chatRoomDoc.id;

                  final String lastMessage = data['lastMessage'] ?? "";
                  final Timestamp? timestamp = data['lastTime'];
                  final String timeString = timestamp != null
                      ? DateFormat('HH:mm dd/MM').format(timestamp.toDate())
                      : "";
                  final String vehicleTitle = data['vehicleTitle'] ?? "Tin xe";
                  final String vehicleId = data['vehicleId'] ?? "";
                  final List participants = data['participants'] ?? [];

                  // Tìm ID người chat cùng
                  final String otherUserId = participants.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => "",
                  );

                  if (otherUserId.isEmpty) return const SizedBox();

                  // 2. Kiểm tra chặn (Logic của đoạn code 1)
                  final bool isBlocked = blockedUsers.contains(otherUserId);

                  return Slidable(
                    key: Key(chatRoomId),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        // Nút Đã đọc
                        SlidableAction(
                          onPressed: (_) => Provider.of<ChatProvider>(context, listen: false)
                              .markAsRead(chatRoomId, currentUserId),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.mark_chat_read,
                          label: 'Đã đọc',
                        ),

                        // 👇 NÚT CHẶN/MỞ CHẶN (Logic của đoạn code 1)
                        SlidableAction(
                          backgroundColor: isBlocked ? Colors.green : Colors.redAccent, 
                          foregroundColor: Colors.white,
                          icon: isBlocked ? Icons.lock_open : Icons.block,
                          label: isBlocked ? 'Mở chặn' : 'Chặn',
                          onPressed: (context) async {
                            final provider = Provider.of<ChatProvider>(context, listen: false);
                            if (isBlocked) {
                              // Đang chặn -> Mở
                              await provider.unblockUser(currentUserId, otherUserId);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã mở chặn"), backgroundColor: Colors.green));
                            } else {
                              // Chưa chặn -> Chặn
                              bool confirm = await showDialog(
                                context: context, 
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Chặn người dùng?"),
                                  content: const Text("Bạn sẽ không nhận được tin nhắn từ họ nữa."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")), 
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Chặn", style: TextStyle(color: Colors.red)))
                                  ]
                                )
                              ) ?? false;
                              if (confirm) {
                                await provider.blockUser(currentUserId, otherUserId);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chặn")));
                              }
                            }
                          },
                        ),

                        // Nút Xóa
                        SlidableAction(
                          onPressed: (_) async {
                             bool confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Xóa?"), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Hủy")), TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Xóa"))])) ?? false;
                             if(confirm) await Provider.of<ChatProvider>(context, listen: false).deleteChatRoom(chatRoomId);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Xóa',
                        ),
                      ],
                    ),
                    
                    // 👇 PHẦN HIỂN THỊ ĐẸP (Lấy từ đoạn code 2)
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        String displayName = "Người dùng";
                        String? avatarUrl;

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          displayName = userData['displayName'] ?? userData['storeName'] ?? "Người dùng";
                          avatarUrl = userData['photoUrl'] ?? userData['storeAva'];
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue[100],
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[$vehicleTitle]",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 12, 
                                    color: isBlocked ? Colors.red : Colors.blueGrey 
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Logic hiển thị tin nhắn hoặc cảnh báo đã chặn
                              Text(
                                isBlocked ? "Bạn đã chặn người dùng này" : lastMessage, 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isBlocked ? Colors.red : Colors.grey,
                                  fontStyle: isBlocked ? FontStyle.italic : FontStyle.normal
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              // Stream đếm tin nhắn chưa đọc
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('chat_rooms')
                                    .doc(chatRoomId)
                                    .collection('messages')
                                    .where('isRead', isEqualTo: false)
                                    .where('receiverId', isEqualTo: currentUserId)
                                    .snapshots(),
                                builder: (context, msgSnapshot) {
                                  if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final int count = msgSnapshot.data!.docs.length;
                                  return Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text(
                                      count > 10 ? "10+" : "$count",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Provider.of<ChatProvider>(context, listen: false)
                                .markAsRead(chatRoomId, currentUserId);
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatRoomId: chatRoomId,
                                  receiverId: otherUserId,
                                  receiverName: displayName,
                                  vehicleTitle: vehicleTitle,
                                  vehicleId: vehicleId,
                                  receiverAvatar: avatarUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}