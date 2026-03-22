import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Khai báo bộ điều khiển cho các ô nhập liệu
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. Hàm gọi API Đăng nhập
  Future<void> _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // THAY ĐỔI IP CHO ĐÚNG: 10.0.2.2 (máy ảo) hoặc 127.0.0.1 (web) hoặc IP máy tính
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/login'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Đăng nhập thành công, chuyển sang màn hình Chat
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        // Sai tài khoản hoặc mật khẩu
        _showError(data['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      _showError("Không thể kết nối tới server backend!");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView( // Thêm cuộn để tránh tràn màn hình khi hiện bàn phím
          child: Card(
            margin: EdgeInsets.all(20),
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ABC TECH", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 10),
                  Text("Hệ thống Quản trị Tri thức"),
                  SizedBox(height: 30),
                  
                  // Ô nhập Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: "Tên đăng nhập", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  SizedBox(height: 15),
                  
                  // Ô nhập Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                  ),
                  SizedBox(height: 25),
                  
                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading 
                        ? CircularProgressIndicator(color: Colors.white) 
                        : Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'), 
                    child: Text("Chưa có tài khoản? Đăng ký ngay")
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}