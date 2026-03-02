import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/views/wrap_auth.dart';
import 'package:provider/provider.dart';

// Import providers
import 'package:my_app/providers/auth_provider.dart' as my_auth;
import 'package:my_app/providers/vehicle_provider.dart';
import 'package:my_app/providers/chat_provider.dart';

// Import AuthWrapper vừa tạo
// import 'package:my_app/views/auth_wrapper.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => my_auth.AuthProvider()), // Khởi tạo đơn giản
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Xe Tốt Market',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color.fromARGB(255, 48, 90, 204),
        ),
        // 👇 Chỉ cần gọi AuthWrapper, nó sẽ tự lo mọi việc
        home: const AuthWrapper(),
      ),
    );
  }
}