import 'package:flutter/material.dart';
import 'package:my_app/views/profile/update_seller_screen.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart'; // Màn hình đăng tin
import 'package:my_app/views/profile/update_seller_screen.dart'; // Màn hình đăng ký lại

// 1. MÀN HÌNH CHÚC MỪNG (SUCCESS)
class SellerSuccessScreen extends StatelessWidget {
  const SellerSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Success",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color.fromARGB(255, 250, 250, 250),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5D3FD3), // tím
                Color(0xFFC51162), // hồng đậm
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),
            // Icon tích xanh
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[50],
              ),
              child: const Icon(Icons.check, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Congratulations! You're now a Seller",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "You can now start listing your cars and connect with potential buyers.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 30),
            
            // Box tính năng đã mở khóa
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Unlocked Features", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildFeatureItem("Unlimited listings"),
                  _buildFeatureItem("Direct chat with buyers"),
                  _buildFeatureItem("Priority support"),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Nút Bắt đầu đăng tin
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  // Chuyển hướng sang màn hình đăng xe
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                },
                child: const Text("Start Posting Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            // Nút về Dashboard (Hoặc về trang chủ)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Go to Dashboard"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.purple),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// 2. MÀN HÌNH THẤT BẠI (REJECTION)
class SellerRejectionScreen extends StatelessWidget {
  final String reason; // Lý do từ chối nhận từ thông báo

  const SellerRejectionScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Application Status"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),
            // Icon X đỏ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: const Icon(Icons.close, size: 60, color: Colors.red),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Application Unsuccessful",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "We were unable to approve your seller upgrade application at this time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 30),
            
            // Box lý do từ chối
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reason for Rejection", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(reason, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Please address the issue above and re-submit your application. We're here to help you succeed!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const Spacer(),
            
            // Nút gửi lại đơn
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  // Mở lại màn hình điền form
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeSellerScreen()));
                },
                child: const Text("Re-submit Application", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            // Nút liên hệ hỗ trợ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Logic mở chat support hoặc gọi điện
                },
                child: const Text("Contact Support"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}