import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/tabs/admin_user_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 👇 1. Đổi thành 3 tab
    _tabController = TabController(length: 3, vsync: this);
    
    // 👇 Thêm lắng nghe thao tác VUỐT màn hình để cập nhật nút Tạo mới
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. HÀM TẠO USER ---
  Future<void> _createNewUser({
    required String email, 
    required String password, 
    required String name, 
    required String role,
    required String phone,   
    required String address, 
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(name: 'TempApp', options: Firebase.app().options);

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': name,
        'phoneNumber': phone,    
        'address': address,      
        'photoUrl': null,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isBanned': false,
        'canPost': true,
        'followers': 0,
        'following': 0,
        if (role == 'seller') ...{
           'storeName': name, 
           'storeFollowers': 0,
           'isSellerVerified': true, 
        }
      });

      await tempApp.delete();
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        Navigator.pop(context); // Tắt dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã tạo $role: $email thành công!")));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (tempApp != null) await tempApp.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- 2. HỘP THOẠI THÔNG MINH ---
  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();   
    final addressController = TextEditingController(); 
    
    // 👇 2. Logic xác định vai trò dựa trên Tab đang mở
    int currentIndex = _tabController.index;
    String selectedRole = 'user';
    String roleDisplayName = "Người mua (User)";
    Color roleColor = Colors.blueGrey;

    if (currentIndex == 0) {
      selectedRole = 'user';
      roleDisplayName = "Người mua (User)";
      roleColor = Colors.blue;
    } else if (currentIndex == 1) {
      selectedRole = 'seller';
      roleDisplayName = "Người bán (Seller)";
      roleColor = Colors.orange;
    } else {
      selectedRole = 'admin';
      roleDisplayName = "Quản trị viên (Admin)";
      roleColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Thêm $roleDisplayName mới"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email (*)")),
              TextField(controller: passController, decoration: const InputDecoration(labelText: "Mật khẩu (*)"), obscureText: true),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên hiển thị (*)")),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Số điện thoại")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Địa chỉ")),
              const SizedBox(height: 15),
              
              // Hiển thị trực quan Role đang được tạo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: roleColor)
                ),
                child: Text(
                  "Vai trò: $roleDisplayName", 
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
            onPressed: () {
              if (emailController.text.isEmpty || passController.text.isEmpty || nameController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ Email, Mật khẩu, Tên")));
                 return;
              }
              
              _createNewUser(
                email: emailController.text.trim(),
                password: passController.text.trim(),
                name: nameController.text.trim(),
                role: selectedRole, // Tự động lấy role theo Tab
                phone: phoneController.text.trim(),
                address: addressController.text.trim(), 
              );
            },
            child: const Text("Tạo ngay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm theo tên hoặc email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
            ),
          ),

          // 2. TAB BAR (👇 CẬP NHẬT THÀNH 3 TAB)
          TabBar(
            controller: _tabController,
            labelColor: Colors.blueGrey[900],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueGrey,
            isScrollable: true, // Cho phép cuộn ngang nếu text quá dài
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: "Người mua (User)"),
              Tab(text: "Người bán (Seller)"),
              Tab(text: "Quản trị viên (Admin)"),
            ],
          ),

          // 3. DANH SÁCH (👇 CẬP NHẬT THÀNH 3 LIST)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(filterRoles: ['user']),
                _buildUserList(filterRoles: ['seller']),
                _buildUserList(filterRoles: ['admin']),
              ],
            ),
          ),
        ],
      ),
      
      // 👇 NÚT TẠO MỚI (Tự đổi màu và Icon theo 3 Tab)
      floatingActionButton: FloatingActionButton(
        backgroundColor: _tabController.index == 0 
            ? Colors.blue 
            : (_tabController.index == 1 ? Colors.orange : Colors.red[900]),
        onPressed: _showAddUserDialog,
        child: Icon(
          _tabController.index == 0 
              ? Icons.person_add 
              : (_tabController.index == 1 ? Icons.storefront : Icons.admin_panel_settings), 
          color: Colors.white
        ),
      ),
    );
  }

  // Hàm _buildUserList (Giữ nguyên logic của bạn)
  Widget _buildUserList({required List<String> filterRoles}) {
     return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không có dữ liệu."));

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? "user";
          final String email = (data['email'] ?? "").toString().toLowerCase();
          final String name = (data['displayName'] ?? "").toString().toLowerCase();
          
          bool roleMatch = filterRoles.contains(role);
          bool searchMatch = email.contains(_searchText) || name.contains(_searchText);
          return roleMatch && searchMatch;
        }).toList();

        if (users.isEmpty) return const Center(child: Text("Không tìm thấy kết quả."));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 10), // Padding bottom để không bị nút FAB che
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;
            
            final String email = userData['email'] ?? "No Email";
            final String name = userData['displayName'] ?? "No Name";
            final String? photoUrl = userData['photoUrl'];
            final bool isBanned = userData['isBanned'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isBanned ? Colors.grey[200] : Colors.white,
              child: ListTile(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: userId)));
                },
                leading: CircleAvatar(
                 backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                    ? NetworkImage(photoUrl) 
                    : null,
                  backgroundColor: Colors.blueGrey,
                  child: (photoUrl == null || photoUrl.isEmpty) 
                    ? const Icon(Icons.person, color: Colors.white) 
                    : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                subtitle: Text(email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}