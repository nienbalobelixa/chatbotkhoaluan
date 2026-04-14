import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  final String displayUsername;
  final String role; 
  final bool isDarkMode;
  final double chatFontSize;
  final String Function(String, String) t;
  final Function(String) onSend;

  const WelcomeView({
    Key? key,
    required this.displayUsername,
    required this.role, 
    required this.isDarkMode,
    required this.chatFontSize,
    required this.t,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // ĐÃ FIX LỖI SỐ 3: Tách biệt gợi ý rành mạch cho Admin và Nhân viên
    List<Map<String, String>> bilingualSuggestions = role == 'admin' 
      ? [
          {"vi": "Soạn thông báo nghỉ lễ 30/4", "en": "Draft holiday notice"},
          {"vi": "Lên dàn ý Team Building", "en": "Team Building outline"},
          {"vi": "Viết email nhắc nhở giờ giấc", "en": "Write punctuality email"}
        ]
      : [
          {"vi": "Quy trình nghỉ phép?", "en": "Leave process?"},
          {"vi": "Lịch trực IT?", "en": "IT Duty Roster?"},
          {"vi": "Chính sách bảo mật?", "en": "Privacy Policy?"}
        ];

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1F22) : Colors.blue[50], shape: BoxShape.circle),
          child: Icon(role == 'admin' ? Icons.campaign : Icons.auto_awesome, size: 40, color: Colors.blueAccent),
        ),
        const SizedBox(height: 20),
        Text(t("Xin chào, $displayUsername", "Hello, $displayUsername"), style: TextStyle(color: textColor, fontSize: chatFontSize * 1.5, fontWeight: FontWeight.bold)),
        if (role == 'admin') 
           Padding(
             padding: const EdgeInsets.only(top: 8, bottom: 20),
             child: Text("Trợ lý HR Copilot đã sẵn sàng!", style: TextStyle(color: Colors.orangeAccent, fontSize: chatFontSize * 0.9, fontStyle: FontStyle.italic)),
           )
        else 
           const SizedBox(height: 30),
        
        Wrap(
          alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
          children: bilingualSuggestions.map((s) => ActionChip(
            backgroundColor: isDarkMode ? const Color(0xFF1E1F22) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12)),
            label: Text(t(s['vi']!, s['en']!), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: chatFontSize * 0.9)),
            onPressed: () => onSend(t(s['vi']!, s['en']!))
          )).toList(),
        )
      ]),
    );
  }
}
