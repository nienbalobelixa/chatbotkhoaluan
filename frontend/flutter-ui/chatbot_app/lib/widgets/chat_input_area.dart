import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ChatInputArea extends StatelessWidget {
  final bool isDarkMode;
  final bool isListening;
  final bool isTyping;
  final PlatformFile? selectedFile;
  final TextEditingController controller;
  final double chatFontSize;
  final String Function(String, String) t; 

  final Function(bool) onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onListen;
  final VoidCallback onStop;   
  final Function(String) onSend;

  const ChatInputArea({
    Key? key,
    required this.isDarkMode,
    required this.isListening,
    required this.isTyping,    
    required this.selectedFile,
    required this.controller,
    required this.chatFontSize,
    required this.t,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onListen,
    required this.onStop,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width >= 800 ? MediaQuery.of(context).size.width * 0.15 : 15.0;
    Color inputBg = isDarkMode ? const Color(0xFF1E1F22) : const Color(0xFFF0F4F9); 
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color hintColor = isDarkMode ? Colors.white54 : Colors.black54;

    // 🔥 ĐỊNH DẠNG STYLE CHO TOOLTIP CHUẨN GEMINI 🔥
    final tooltipDecoration = BoxDecoration(
      color: const Color(0xFFEAEAEA), // Màu nền sáng (trắng xám)
      borderRadius: BorderRadius.circular(6), // Bo góc nhẹ
    );
    final tooltipTextStyle = const TextStyle(
      color: Colors.black87, // Chữ màu đen
      fontSize: 12, 
      fontWeight: FontWeight.w500
    );

    return Padding(
      padding: EdgeInsets.only(left: paddingHorizontal, right: paddingHorizontal, bottom: 5, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PREVIEW FILE KHI ĐÃ CHỌN
          if (selectedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A35) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ['png', 'jpg', 'jpeg'].contains(selectedFile!.extension?.toLowerCase()) 
                        ? Icons.image : Icons.insert_drive_file,
                    color: Colors.blueAccent, size: 20
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      selectedFile!.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRemoveFile, 
                    child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  ),
                ],
              ),
            ),

          // Ô NHẬP TEXT CHÍNH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(35)), 
            child: Row(
              children: [
                // MENU DẤU CỘNG (+) CÓ TOOLTIP
                Tooltip(
                  message: t("Thêm tệp đính kèm", "Add attachment"),
                  decoration: tooltipDecoration,
                  textStyle: tooltipTextStyle,
                  preferBelow: false,
                  verticalOffset: 25,
                  child: PopupMenuButton<String>(
                    enabled: true, 
                    tooltip: "", // Tắt tooltip mặc định của PopupMenu để dùng Custom Tooltip
                    icon: Icon(Icons.add_circle_outline, color: textColor),
                    color: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
                    offset: const Offset(0, -120), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) {
                      if (value == 'document') onPickFile(false);
                      else if (value == 'image') onPickFile(true);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'document',
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(t("Tải tệp lên", "Upload file"), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'image',
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(t("Tải ảnh lên", "Upload image"), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: TextField(
                    controller: controller, 
                    style: TextStyle(color: textColor, fontSize: chatFontSize), 
                    enabled: true, 
                    onSubmitted: (text) {
                      if (!isTyping) onSend(text); 
                    }, 
                    decoration: InputDecoration(
                      hintText: isListening ? t("Đang nghe...", "Listening...") : t("Hỏi ABC AI...", "Ask ABC AI..."),
                      hintStyle: TextStyle(color: hintColor), 
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10)
                    )
                  )
                ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isTyping)
                      // 🔥 NÚT MIC CÓ TOOLTIP 🔥
                      Tooltip(
                        message: isListening ? t("Dừng micrô", "Stop microphone") : t("Sử dụng micrô", "Use microphone"),
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        preferBelow: false, // Ép Tooltip nổi lên trên nút
                        verticalOffset: 25, // Đẩy lên một khoảng cho đẹp
                        child: IconButton(
                          icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                          color: isListening ? Colors.redAccent : textColor,
                          onPressed: onListen,
                        ),
                      ),
                    
                    if (isTyping)
                      // 🔥 NÚT DỪNG CÓ TOOLTIP 🔥
                      Tooltip(
                        message: t("Dừng tạo", "Stop generating"),
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        preferBelow: false,
                        verticalOffset: 25,
                        child: IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 30),
                          onPressed: onStop, 
                        ),
                      )
                    else if (controller.text.trim().isNotEmpty || selectedFile != null)
                      // 🔥 NÚT GỬI CÓ TOOLTIP 🔥
                      Tooltip(
                        message: t("Gửi tin nhắn", "Send message"),
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        preferBelow: false,
                        verticalOffset: 25,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.blueAccent),
                          onPressed: () => onSend(controller.text),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}