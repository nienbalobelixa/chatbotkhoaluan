import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_docs_screen.dart';
import 'screens/admin_screen.dart'; 

void main() {
  runApp(KnowledgeApp());
}

class KnowledgeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABC TECH AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), 

      // Nếu bạn để '/' là trang chủ, nên có định nghĩa trong routes bên dưới
      initialRoute: '/login', 

      // Dùng onGenerateRoute để bóc tách dữ liệu khi chuyển trang
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          // KHI LOGIN CHUYỂN SANG: Đổi Map<String, String> thành Map<String, dynamic>
          final args = settings.arguments as Map<String, dynamic>? ?? {
            "username": "Guest",
            "role": "staff",
            "isOnboarded": false // Giá trị mặc định nếu không có
          };

          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              username: args["username"].toString(), // Chắc chắn nó là chữ
              role: args["role"].toString(),
              isOnboarded: args["isOnboarded"] as bool?, // BẮT VÀ TRUYỀN BIẾN MỚI VÀO ĐÂY
            ),
          );
        }
        
        // Các route khác không cần tham số
        return null; 
      },

      routes: {
        '/': (context) => LoginScreen(), // Định nghĩa route gốc để không bị lỗi màn hình đen
        '/login': (context) => LoginScreen(),
        '/admin': (context) => AdminScreen(),
        '/admin_docs': (context) => AdminDocsScreen(),
      },
    );
  }
}