import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/admin/report/admin_report_detail_screen.dart'; // Import màn hình chi tiết của bạn

class ReportTab extends StatelessWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Chỉ lấy các đơn đang chờ xử lý
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: 10),
                Text("Không có khiếu nại nào cần xử lý!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;
            final reportId = reports[index].id;
            
            // Format thời gian
            String timeAgo = "";
            if (data['createdAt'] != null) {
              timeAgo = DateFormat('dd/MM HH:mm').format((data['createdAt'] as Timestamp).toDate());
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.report_problem, color: Colors.white),
                ),
                title: Text(
                  data['reason'] ?? "Không có lý do",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Xe bị tố: ${data['vehicleTitle'] ?? '---'}"),
                    Text("Người báo cáo: ${data['reporterEmail'] ?? 'Ẩn danh'}"),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  // KHI ẤN VÀO -> MỞ MÀN HÌNH CHI TIẾT
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailScreen(
                        reportData: data,
                        reportId: reportId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}