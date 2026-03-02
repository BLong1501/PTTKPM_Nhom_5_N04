import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class StoreFollowersScreen extends StatelessWidget {
  final String storeId;

  const StoreFollowersScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Người theo dõi cửa hàng"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Truy vấn vào sub-collection chứa danh sách follower
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(storeId)
            .collection('store_followers') 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có ai theo dõi cửa hàng.", style: TextStyle(color: Colors.grey)),
            );
          }

          final followerDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: followerDocs.length,
            itemBuilder: (context, index) {
              final followerId = followerDocs[index].id;

              // Vì follower chỉ có ID, ta cần fetch thông tin chi tiết (Tên, Avatar) từ collection 'users'
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(followerId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final user = UserModel.fromMap(userData, followerId);

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
                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
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