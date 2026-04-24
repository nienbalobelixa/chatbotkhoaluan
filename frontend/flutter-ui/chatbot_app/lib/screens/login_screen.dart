import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Nhớ import ChatScreen của bạn vào đây
import 'chat_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final String baseUrl = "https://chatbot-backend-qjw8.onrender.com"; 
  
  bool _isLogin = true; // True: Đăng nhập | False: Đăng ký
  bool _isLoading = false;
  bool _obscurePassword = true; // Ẩn/hiện mật khẩu

  // HÀM GỌI API ĐĂNG NHẬP / ĐĂNG KÝ
  Future<void> _submitForm() async {
    // 1. Kiểm tra Validation ở Frontend trước (Đỡ tốn băng thông)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String endpoint = _isLogin ? "/login" : "/register";
    
    try {
      final res = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim()
        }),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      setState(() => _isLoading = false);

      if (res.statusCode == 200 && data['status'] == 'success') {
        if (_isLogin) {
          // ĐĂNG NHẬP THÀNH CÔNG -> Lưu thông tin và chuyển sang màn hình Chat
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Đăng nhập thành công!", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          
          // Save credentials to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', data['username'] ?? '');
          await prefs.setString('role', data['role'] ?? 'staff');
          await prefs.setBool('is_onboarded', data['is_onboarded'] ?? false);
          
          // Navigate to ChatScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                username: data['username'],
                role: data['role'],
                isOnboarded: data['is_onboarded'],
              ),
            ),
          );
        } else {
          // ĐĂNG KÝ THÀNH CÔNG -> Chuyển về form Đăng nhập
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          setState(() {
            _isLogin = true;
            _passwordController.clear(); // Xóa pass đi cho an toàn bắt nhập lại
          });
        }
      } else {
        // BÁO LỖI TỪ BACKEND (Sai pass, trùng tên, v.v...)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Có lỗi xảy ra!", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối máy chủ: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131314), // Nền tối ngầu
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400), // Không cho phình to quá trên Desktop
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO & TIÊU ĐỀ
                    const Icon(Icons.auto_awesome, size: 60, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? "Đăng Nhập Hệ Thống" : "Đăng Ký Tài Khoản",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ABC TECH AI COPILOT",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2),
                    ),
                    const SizedBox(height: 40),

                    // Ô NHẬP TÊN ĐĂNG NHẬP
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Tên đăng nhập",
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Không được để trống tên đăng nhập!";
                        if (value.trim().length < 3) return "Tên phải dài ít nhất 3 ký tự!";
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) return "Không chứa dấu cách hoặc ký tự đặc biệt!";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Ô NHẬP MẬT KHẨU CÓ NÚT ẨN/HIỆN
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Không được để trống mật khẩu!";
                        if (value.trim().length < 6) return "Mật khẩu phải từ 6 ký tự trở lên!";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // NÚT XÁC NHẬN (Có Loading)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // NÚT CHUYỂN ĐỔI ĐĂNG NHẬP / ĐĂNG KÝ
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset(); // Xóa báo lỗi đỏ khi đổi tab
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? ",
                          style: const TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: _isLogin ? "Đăng ký ngay" : "Đăng nhập",
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}