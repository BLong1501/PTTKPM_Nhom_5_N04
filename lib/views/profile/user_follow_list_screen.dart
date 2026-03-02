import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';
import '../../models/user_model.dart';

class UserFollowListScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex; // 0: Đang theo dõi (Following), 1: Người theo dõi (Followers)

  const UserFollowListScreen({
    super.key, 
    required this.userId, 
    this.initialTabIndex = 0
  });

  @override
  State<UserFollowListScreen> createState() => _UserFollowListScreenState();
}

class _UserFollowListScreenState extends State<UserFollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTabIndex
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bạn bè & Theo dõi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(text: "Đang theo dõi"),
            Tab(text: "Người theo dõi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DANH SÁCH ĐANG THEO DÕI (Following)
          _buildUserList(collectionName: 'following'),
          
          // TAB 2: DANH SÁCH NGƯỜI THEO DÕI MÌNH (Followers)
          _buildUserList(collectionName: 'followers'),
        ],
      ),
    );
  }

  // Hàm dùng chung để hiển thị list user
  Widget _buildUserList({required String collectionName}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection(collectionName) // 'following' hoặc 'followers'
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
                Icon(
                  collectionName == 'following' ? Icons.person_add_disabled : Icons.group_off,
                  size: 50, color: Colors.grey[300]
                ),
                const SizedBox(height: 10),
                Text(
                  collectionName == 'following' 
                      ? "Bạn chưa theo dõi ai" 
                      : "Chưa có ai theo dõi bạn",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final otherUserId = docs[index].id;

            // Lấy thông tin chi tiết của User kia
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox(); // Nếu user bị xóa thì ẩn luôn
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final user = UserModel.fromMap(userData, otherUserId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_)=>PublicProfileScreen(userId: otherUserId)));
                      
                      // Logic xem trang cá nhân hoặc chat (để sau)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Xem"),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}