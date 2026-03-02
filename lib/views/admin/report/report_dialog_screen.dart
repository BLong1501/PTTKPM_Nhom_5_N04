import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart'; // <--- Dùng import chuẩn này cho an toàn
import 'package:image_picker/image_picker.dart';
// --- WIDGET DIALOG BÁO CÁO (Thêm vào cuối file hoặc file riêng) ---
class ReportDialog extends StatefulWidget {
  final String vehicleId;
  final String reportedUserId;
  final String vehicleTitle;

  const ReportDialog({
    super.key,
    required this.vehicleId,
    required this.reportedUserId,
    required this.vehicleTitle,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  // Các lý do có sẵn
  final List<String> _reasons = [
    "Lừa đảo / Yêu cầu đặt cọc",
    "Xe không giống mô tả / ảnh",
    "Giá ảo / Không liên lạc được",
    "Spam / Tin trùng lặp",
    "Khác"
  ];

  String? _selectedReason;
  final _otherReasonController = TextEditingController();
  File? _evidenceImage;
  bool _isLoading = false;

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _evidenceImage = File(pickedFile.path);
      });
    }
  }

  // Hàm gửi báo cáo
  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn lý do.")));
      return;
    }
    if (_selectedReason == "Khác" && _otherReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập lý do cụ thể.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      
      // 1. Upload ảnh lên Storage (Nếu có)
      if (_evidenceImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('report_evidence')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_evidenceImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // 2. Lưu vào Firestore collection 'reports'
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': currentUser?.uid,
        'reporterEmail': currentUser?.email,
        'reportedUserId': widget.reportedUserId, // ID người bị tố cáo
        'vehicleId': widget.vehicleId,           // ID xe bị tố cáo
        'vehicleTitle': widget.vehicleTitle,
        'reason': _selectedReason,
        'description': _selectedReason == "Khác" ? _otherReasonController.text : "",
        'evidenceImage': imageUrl,
        'status': 'pending', // pending (chờ xử lý), resolved (đã xử lý), rejected (bác bỏ)
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Đóng Dialog
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã gửi báo cáo. Admin sẽ xem xét sớm nhất!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tố cáo vi phạm"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vui lòng chọn lý do:", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _selectedReason = val),
                )),
            
            // Ô nhập lý do khác
            if (_selectedReason == "Khác")
              TextField(
                controller: _otherReasonController,
                decoration: const InputDecoration(
                  labelText: "Nhập lý do cụ thể...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            
            const SizedBox(height: 15),
            const Text("Bằng chứng (Ảnh chụp màn hình/Zalo...):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            
            // Khu vực chọn ảnh
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _evidenceImage != null
                    ? Image.file(_evidenceImage!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.camera_alt), Text("Nhấn để tải ảnh")],
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReport,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text("Gửi tố cáo", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}