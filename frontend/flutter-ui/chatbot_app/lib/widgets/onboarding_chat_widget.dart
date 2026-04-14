import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OnboardingChatWidget extends StatefulWidget {
  final String userId;
  final Function(String) onAskAI; // Hàm này sẽ kích hoạt chat
  
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

  @override
  void initState() {
    super.initState();
    _fetchOnboardingTask();
  }

  Future<void> _fetchOnboardingTask() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/onboarding/${widget.userId}'); 
    
    print("🌐 Đang gọi API Onboarding: $url"); // <-- Gắn máy nghe lén số 1
    
    try {
      final response = await http.get(url);
      
      print("📦 Kết quả Backend trả về: ${response.body}"); // <-- Gắn máy nghe lén số 2

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['status'] == 'completed') {
            isCompleted = true;
          } else {
            currentTask = data['current_task'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi mạng: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsCompleted(int day) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/onboarding/${widget.userId}/complete?day=$day');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        _fetchOnboardingTask(); // Gọi lại để lấy nhiệm vụ ngày tiếp theo hoặc ẩn đi
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator());
    if (isCompleted || currentTask == null) return const SizedBox.shrink();

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
          
          // 1. DÒNG TIÊU ĐỀ
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded( // Dùng Expanded để chữ dài tự xuống dòng, không bị tràn
                child: Text(
                  "Nhiệm vụ ngày ${currentTask!['day']}: ${currentTask!['title']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // 2. NỘI DUNG NHIỆM VỤ
          Text(
            currentTask!['message'], 
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5)
          ),
          const SizedBox(height: 15),
          
          // 3. CỤM NÚT BẤM (Dùng Wrap chống tràn viền trên Mobile)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10, // Khoảng cách ngang giữa 2 nút
              runSpacing: 10, // Khoảng cách dọc nếu bị đẩy xuống dòng
              alignment: WrapAlignment.end,
              children: [
                
                // Nút Hỏi AI
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                  label: const Text("Hỏi AI bài này"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    widget.onAskAI(currentTask!['suggested_prompt']);
                  },
                ),
                
                // Nút Đã Nắm Rõ
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