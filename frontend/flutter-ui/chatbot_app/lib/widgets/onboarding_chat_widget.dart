import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OnboardingChatWidget extends StatefulWidget {
  final String userId;
  final Function(String) onAskAI; 
  
  const OnboardingChatWidget({
    Key? key, 
    required this.userId, 
    required this.onAskAI
  }) : super(key: key);

  @override
  _OnboardingChatWidgetState createState() => _OnboardingChatWidgetState();
}

class _OnboardingChatWidgetState extends State<OnboardingChatWidget> {
  Map<String, dynamic>? currentTask;
  bool isLoading = true;
  bool isCompleted = false;

  final String apiBaseUrl = "https://chatbot-backend-qjw8.onrender.com/api";

  @override
  void initState() {
    super.initState();
    // Vừa vào là hỏi thẳng Backend (Supabase) xem trạng thái thế nào
    _fetchOnboardingStatus();
  }

  // 🚀 LẤY TRẠNG THÁI TỪ SUPABASE QUA BACKEND
  Future<void> _fetchOnboardingStatus() async {
    final url = Uri.parse('$apiBaseUrl/onboarding/${widget.userId}'); 
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Nếu Backend báo 'completed', isCompleted = true sẽ làm Widget biến mất
          if (data['status'] == 'completed') {
            isCompleted = true;
          } else {
            currentTask = data['current_task'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi kết nối Supabase: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🚀 CẬP NHẬT TRẠNG THÁI HOÀN THÀNH LÊN SUPABASE
  Future<void> _markAsCompleted(int day) async {
    setState(() => isLoading = true);

    final url = Uri.parse('$apiBaseUrl/onboarding/${widget.userId}/complete?day=$day');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        // Sau khi báo thành công, tải lại để kiểm tra xem đã xong hết 3 ngày chưa
        _fetchOnboardingStatus(); 
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu Supabase xác nhận đã xong hoặc không có nhiệm vụ, ẩn Widget ngay
    if (isCompleted || currentTask == null) return const SizedBox.shrink();
    
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20), 
        child: Center(child: CircularProgressIndicator(strokeWidth: 2))
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded( 
                child: Text(
                  "Nhiệm vụ ngày ${currentTask!['day']}: ${currentTask!['title']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentTask!['message'], 
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5)
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                  label: const Text("Hỏi AI bài này"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => widget.onAskAI(currentTask!['suggested_prompt']),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  label: const Text("Đã Nắm Rõ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => _markAsCompleted(currentTask!['day']),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}