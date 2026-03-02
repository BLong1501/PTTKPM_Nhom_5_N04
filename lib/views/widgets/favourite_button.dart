import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  final String vehicleId;

  const FavoriteButton({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập thì hiện tim rỗng và không làm gì (hoặc hiện thông báo)
    if (user == null) {
      return const Icon(Icons.favorite_border, color: Colors.grey);
    }

    return StreamBuilder<DocumentSnapshot>(
      // 🔥 Lắng nghe trực tiếp vào document favorite của xe này
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(vehicleId)
          .snapshots(),
      builder: (context, snapshot) {
        // Kiểm tra xem doc có tồn tại không -> Có tồn tại nghĩa là đã Tim
        bool isFavorited = snapshot.hasData && snapshot.data!.exists;

        return IconButton(
          padding: EdgeInsets.zero, 
          constraints: const BoxConstraints(), 
          iconSize: 20, // Điều chỉnh kích thước icon cho vừa mắt (nếu cần)
          icon: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited ? Colors.red : Colors.grey,
          ),
          onPressed: () async {
            final favoriteRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('favorites')
                .doc(vehicleId);

            if (isFavorited) {
              // Nếu đang thích -> Xóa (Un-favorite)
              await favoriteRef.delete();
            } else {
              // Nếu chưa thích -> Thêm vào (Favorite)
              await favoriteRef.set({
                'vehicleId': vehicleId,
                'addedAt': FieldValue.serverTimestamp(),
              });
            }
          },
        );
      },
    );
  }
}