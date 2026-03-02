class LogModel {
  final String id;
  final String action; // "Đăng nhập" hoặc "Đăng xuất"
  final DateTime timestamp;
  final String deviceName; // Tên thiết bị (VD: iPhone 14 Pro)

  LogModel({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.deviceName,
  });

  factory LogModel.fromMap(Map<String, dynamic> data, String id) {
    return LogModel(
      id: id,
      action: data['action'] ?? '',
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp']) 
          : DateTime.now(),
      deviceName: data['deviceName'] ?? 'Unknown Device',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'deviceName': deviceName,
    };
  }
}