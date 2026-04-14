import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> messages;
  final String role; 
  final bool isTyping;
  final bool isDarkMode;
  final String displayUsername;
  final double chatFontSize;
  final int? currentlySpeakingIndex;
  
  final String Function(String, String) t;
  final Function(String, int) onToggleSpeak;
  final Function(String) onCopy;
  final Function(int) onRetry;
  final Function(int, String) onSubmitFeedback;
  final Function(String) onFollowUpClick;
  final Function(String) onLaunchSource;
  final Function(int) onTypingDone;
  
  // 1. ĐÃ THÊM KHAI BÁO HÀM ONBROADCAST Ở ĐÂY
  final Function(String) onBroadcast; 

  const ChatMessageList({
    Key? key,
    required this.scrollController,
    required this.messages,
    required this.isTyping,
    required this.role, 
    required this.isDarkMode,
    required this.displayUsername,
    required this.chatFontSize,
    required this.currentlySpeakingIndex,
    required this.t,
    required this.onToggleSpeak,
    required this.onCopy,
    required this.onRetry,
    required this.onSubmitFeedback,
    required this.onFollowUpClick,
    required this.onLaunchSource,
    required this.onTypingDone,
    
    // 2. ĐÃ YÊU CẦU TRUYỀN HÀM VÀO CONSTRUCTOR
    required this.onBroadcast, 
  }) : super(key: key);

  Widget _buildSources(List sources) {
    return Container(
      margin: const EdgeInsets.only(top: 15), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1F22) : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(t("📌 Nguồn tham khảo:", "📌 Sources:"), style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: sources.map((s) => ActionChip(avatar: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white), label: Text(s.toString(), style: const TextStyle(fontSize: 12, color: Colors.white)), backgroundColor: isDarkMode ? const Color(0xFF2A2A35) : Colors.blueAccent.withOpacity(0.8), onPressed: () => onLaunchSource(s.toString()))).toList())
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width >= 800 ? MediaQuery.of(context).size.width * 0.15 : 15.0;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color actionIconColor = isDarkMode ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController, 
            padding: const EdgeInsets.only(top: 20), 
            itemCount: messages.length,
            itemBuilder: (context, i) {
              bool isBot = messages[i]['role'] == 'bot';
              bool isAdminReply = messages[i]['text'].toString().contains("[Cập nhật từ Quản trị viên]");

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: paddingHorizontal),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16, 
                      backgroundColor: isBot ? (isAdminReply ? Colors.green : Colors.blueAccent) : Colors.redAccent, 
                      child: Icon(isBot ? (isAdminReply ? Icons.support_agent : Icons.auto_awesome) : Icons.person, color: Colors.white, size: 18)
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBot ? "ABC AI" : displayUsername, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: chatFontSize * 0.9)),
                          const SizedBox(height: 8),
                          (!isBot || messages[i]['isTyping'] != true)
                              ? MarkdownBody(
                                  data: messages[i]['text'] ?? "", 
                                  styleSheet: MarkdownStyleSheet(p: TextStyle(color: textColor, fontSize: chatFontSize, height: 1.6), code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent), codeblockDecoration: BoxDecoration(color: const Color(0xFF0A0A0F), borderRadius: BorderRadius.circular(8))), 
                                  onTapLink: (text, href, title) { if (href != null) onLaunchSource(href); }
                                )
                              : StreamBuilder<String>(
                                  stream: messages[i]['stream'], 
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) => onTypingDone(i));
                                    }
                                    return MarkdownBody(data: snapshot.data ?? "", styleSheet: MarkdownStyleSheet(p: TextStyle(color: textColor, fontSize: chatFontSize, height: 1.6), code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent)));
                                  },
                                ),
                          
                          if (isBot && messages[i]['sources'] != null && (messages[i]['sources'] as List).isNotEmpty && messages[i]['isTyping'] != true) 
                            _buildSources(messages[i]['sources']),
                          
                          if (isBot) ...[
                            const SizedBox(height: 10),
                            
                            // 3. ĐÃ THAY THẾ ROW + SPACER BẰNG WRAP (Chống tràn màn hình tuyệt đối)
                            Wrap(
                              spacing: 5, // Khoảng cách ngang giữa các nút
                              runSpacing: 5, // Khoảng cách dọc nếu bị rớt dòng
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(icon: Icon(currentlySpeakingIndex == i ? Icons.volume_up : Icons.volume_down, size: 18), color: currentlySpeakingIndex == i ? Colors.blueAccent : actionIconColor, onPressed: () => onToggleSpeak(messages[i]['text'] ?? "", i)),
                                IconButton(icon: const Icon(Icons.content_copy, size: 18), color: actionIconColor, onPressed: () => onCopy(messages[i]['text'] ?? "")),
                                IconButton(icon: const Icon(Icons.refresh, size: 18), color: actionIconColor, onPressed: () => onRetry(i)),
                                
                                if (isBot && role == 'admin')
                                  TextButton.icon(
                                    icon: const Icon(Icons.campaign, size: 16, color: Colors.orangeAccent),
                                    label: Text(t("Gửi toàn công ty", "Broadcast"), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => onBroadcast(messages[i]['text']),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), backgroundColor: Colors.orangeAccent.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
                                  
                                // Gộp 2 nút like/dislike lại để nó luôn đi chung với nhau
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: Icon(messages[i]['feedback'] == 'up' ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 16), color: messages[i]['feedback'] == 'up' ? Colors.green : actionIconColor, onPressed: () => onSubmitFeedback(i, 'up')),
                                    IconButton(icon: Icon(messages[i]['feedback'] == 'down' ? Icons.thumb_down : Icons.thumb_down_alt_outlined, size: 16), color: messages[i]['feedback'] == 'down' ? Colors.redAccent : actionIconColor, onPressed: () => onSubmitFeedback(i, 'down')),
                                  ],
                                )
                              ],
                            ),
                            
                            if (i == messages.length - 1 && messages[i]['follow_ups'] != null && (messages[i]['follow_ups'] as List).isNotEmpty && messages[i]['isTyping'] != true) 
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: (messages[i]['follow_ups'] as List).map((question) => ActionChip(
                                    label: Text(question.toString(), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 12)), 
                                    backgroundColor: isDarkMode ? const Color(0xFF2A2A35) : Colors.blue[50], 
                                    onPressed: () => onFollowUpClick(question.toString())
                                  )).toList(),
                                ),
                              ),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        
        if (isTyping) 
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 10), 
            child: Row(children: [const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blueAccent)), const SizedBox(width: 15), Text(t("AI đang suy nghĩ...", "AI is thinking..."), style: const TextStyle(color: Colors.blueAccent, fontStyle: FontStyle.italic))])
          )
      ],
    );
  }
}