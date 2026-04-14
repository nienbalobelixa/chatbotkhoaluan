import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// --- IMPORT CÁC MÀN HÌNH KHÁC ---
import 'admin_screen.dart';
import 'package:chatbot_app/widgets/onboarding_chat_widget.dart';



// --- IMPORT CÁC WIDGET MỚI TÁCH LÀM CLEAN CODE ---
import 'package:chatbot_app/widgets/chat_input_area.dart';
import 'package:chatbot_app/widgets/chat_sidebar.dart'; 
import 'package:chatbot_app/widgets/welcome_view.dart';
import 'package:chatbot_app/widgets/chat_message_list.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String role;
  final bool? isOnboarded; 

  const ChatScreen({
    Key? key, 
    required this.username, 
    required this.role, 
    this.isOnboarded
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  PlatformFile? _selectedFile;
  List<Map<String, dynamic>> messages = [];
  List<dynamic> chatSessions = []; 
  Map<String, List<dynamic>> groupedSessions = {}; 
  
  List<dynamic> notifications = [];
  int get unreadCount => notifications.where((n) => n['is_read'] == false).length;
  
  // ==========================================
  // CÁC BIẾN QUẢN LÝ TÍCH CHỌN & THÙNG RÁC
  // ==========================================
  bool _isEditingNotifs = false; 
  Set<int> _selectedNotifs = {}; 
  bool _showTrash = false; 
  List<dynamic> trashNotifications = []; 
  // ==========================================

  bool isTyping = false;
  String? currentSessionId; 
  String? currentAvatarUrl;
  
  final String baseUrl = "http://127.0.0.1:8000"; 
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _wasVoiceInput = false; 
  Timer? _speechTimeout;
  Timer? _pollingTimer; 

  bool isDarkMode = true;
  double chatFontSize = 16.0;
  double brightnessLevel = 1.0; 
  String currentLanguage = 'Tiếng Việt';
  late String displayUsername;

  bool isSidebarOpen = true;
  FlutterTts flutterTts = FlutterTts();
  int? currentlySpeakingIndex; 
  int unansweredCount = 0; 
  Timer? _notificationTimer;
  
  @override
  void initState() {
    super.initState();
    displayUsername = widget.username;
    _speech = stt.SpeechToText();
    _initTts(); 
    _loadSessions(); 
    _loadNotifications(); 
    _loadAvatar();
    
    _controller.addListener(() {
      setState(() {}); 
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadNotifications();
    });
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadNotifications();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); 
    flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    _notificationTimer?.cancel(); 
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/users/${widget.username}/avatar"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['avatar_url'] != null) {
          setState(() {
            currentAvatarUrl = "$baseUrl/avatars/${data['avatar_url']}?v=${DateTime.now().millisecondsSinceEpoch}";
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _changeAvatar(StateSetter setModalState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/users/${widget.username}/avatar"));
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tải ảnh lên...")));
      try {
        var streamedRes = await request.send();
        var res = await http.Response.fromStream(streamedRes);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'success') {
            String newUrl = "$baseUrl/avatars/${data['avatar_url']}?v=${DateTime.now().millisecondsSinceEpoch}";
            setState(() => currentAvatarUrl = newUrl);
            setModalState(() {}); 
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật ảnh đại diện!", style: TextStyle(color: Colors.green))));
          }
        }
      } catch (e) {}
    }
  }

  Future<void> _broadcastMessage(String text) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
        title: const Text("Xác nhận gửi thông báo", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc chắn muốn gửi nội dung này đến TOÀN BỘ nhân viên không?", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Gửi đi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/broadcast"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text})
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Đã bắn thông báo thành công!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${data['message']}", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi mạng: $e")));
    }
  }

  // ==========================================
  // LOGIC XỬ LÝ THÔNG BÁO & THÙNG RÁC CHUẨN MỰC
  // ==========================================
  Future<void> _loadNotifications() async {
    try {
      if (widget.role == 'admin') {
        final res = await http.get(Uri.parse("$baseUrl/admin/unanswered"));
        if (res.statusCode == 200 && mounted) {
          final List data = jsonDecode(utf8.decode(res.bodyBytes));
          setState(() => unansweredCount = data.length);
        }
      } 
      
      // 1. Tải thông báo đang hoạt động (Chưa xóa)
      final res2 = await http.get(Uri.parse("$baseUrl/notifications/${widget.username}"));
      if (res2.statusCode == 200 && mounted) {
        List decodedList = jsonDecode(utf8.decode(res2.bodyBytes));
        List unread = decodedList.where((n) => n['is_read'] == false).toList();
        List read = decodedList.where((n) => n['is_read'] == true).toList();
        setState(() => notifications = [...unread, ...read]);
      }

      // 2. Tải thông báo trong Thùng Rác
      final resTrash = await http.get(Uri.parse("$baseUrl/notifications/${widget.username}/trash"));
      if (resTrash.statusCode == 200 && mounted) {
        setState(() => trashNotifications = jsonDecode(utf8.decode(resTrash.bodyBytes)));
      }
    } catch (e) {
      print("Lỗi load thông báo: $e");
    }
  }

  Future<void> _moveToTrash(int notifId) async {
    try {
      await http.put(Uri.parse("$baseUrl/notifications/$notifId/trash"));
      await _loadNotifications();
    } catch (e) {}
  }

  Future<void> _restoreNotification(int notifId) async {
    try {
      await http.put(Uri.parse("$baseUrl/notifications/$notifId/restore"));
      await _loadNotifications();
    } catch (e) {}
  }

  Future<void> _deletePermanently(int notifId) async {
    try {
      await http.delete(Uri.parse("$baseUrl/notifications/$notifId"));
      await _loadNotifications();
    } catch (e) {}
  }

  void _showNotificationSheet() {
    _isEditingNotifs = false;
    _selectedNotifs.clear();
    _showTrash = false; 

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            List currentList = _showTrash ? trashNotifications : notifications;

            Future<void> handleMassAction(String action) async {
              if (_selectedNotifs.isEmpty) return;
              
              if (action == 'trash') {
                await Future.wait(_selectedNotifs.map((id) => http.put(Uri.parse("$baseUrl/notifications/$id/trash"))));
              } else if (action == 'restore') {
                await Future.wait(_selectedNotifs.map((id) => http.put(Uri.parse("$baseUrl/notifications/$id/restore"))));
              } else if (action == 'delete_forever') {
                await Future.wait(_selectedNotifs.map((id) => http.delete(Uri.parse("$baseUrl/notifications/$id"))));
              }
              
              await _loadNotifications();
              setSheetState(() {
                _selectedNotifs.clear();
                _isEditingNotifs = false;
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1F22) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
              child: Column(
                children: [
                  Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
                  
                  // HEADER: CHUYỂN ĐỔI TAB & NÚT QUẢN LÝ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _showTrash ? t("Thùng rác", "Trash") : t("Thông báo", "Notifications"), 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _showTrash ? Colors.redAccent : (isDarkMode ? Colors.white : Colors.black))
                            ),
                            const SizedBox(width: 15),
                            if (!_isEditingNotifs)
                              InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    _showTrash = !_showTrash;
                                    _selectedNotifs.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: isDarkMode ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(15)),
                                  child: Row(
                                    children: [
                                      Icon(_showTrash ? Icons.arrow_back : Icons.delete_outline, size: 16, color: isDarkMode ? Colors.white70 : Colors.black87),
                                      const SizedBox(width: 5),
                                      Text(
                                        _showTrash ? t("Quay lại", "Back") : "${t("Thùng rác", "Trash")} (${trashNotifications.length})", 
                                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black87)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        if (!_isEditingNotifs && currentList.isNotEmpty)
                          TextButton(onPressed: () => setSheetState(() => _isEditingNotifs = true), child: Text(t("Quản lý", "Manage"), style: const TextStyle(color: Colors.blueAccent)))
                        else if (_isEditingNotifs)
                          TextButton(onPressed: () => setSheetState(() { _isEditingNotifs = false; _selectedNotifs.clear(); }), child: Text(t("Hủy", "Cancel"), style: const TextStyle(color: Colors.grey)))
                      ],
                    ),
                  ),

                  // THANH CÔNG CỤ CHECKBOX
                  if (_isEditingNotifs)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedNotifs.length == currentList.length && currentList.isNotEmpty,
                            activeColor: Colors.blueAccent,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) _selectedNotifs = currentList.map<int>((n) => n['id'] as int).toSet();
                                else _selectedNotifs.clear();
                              });
                            },
                          ),
                          Text(t("Chọn tất cả", "Select All"), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          const Spacer(),
                          if (_selectedNotifs.isNotEmpty)
                            Row(
                              children: [
                                if (_showTrash)
                                  IconButton(
                                    icon: const Icon(Icons.restore, color: Colors.greenAccent),
                                    tooltip: "Khôi phục",
                                    onPressed: () => handleMassAction('restore'),
                                  ),
                                ElevatedButton.icon(
                                  icon: Icon(_showTrash ? Icons.delete_forever : Icons.delete, color: Colors.white, size: 16),
                                  label: Text(_showTrash ? "Xóa vĩnh viễn (${_selectedNotifs.length})" : "Xóa (${_selectedNotifs.length})", style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                  onPressed: () => handleMassAction(_showTrash ? 'delete_forever' : 'trash'),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),

                  const Divider(height: 1, color: Colors.grey),

                  // DANH SÁCH THÔNG BÁO / THÙNG RÁC
                  Expanded(
                    child: currentList.isEmpty
                        ? Center(child: Text(_showTrash ? t("Thùng rác trống", "Trash is empty") : t("Không có thông báo mới", "No new notifications"), style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: currentList.length,
                            itemBuilder: (ctx, i) {
                              var n = currentList[i];
                              bool isRead = n['is_read'];
                              bool isBroadcast = n['session_id'] == 'broadcast'; 
                              int notifId = n['id'];

                              return Dismissible(
                                key: Key(notifId.toString()),
                                direction: _isEditingNotifs ? DismissDirection.none : DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: _showTrash ? Colors.red[900] : Colors.redAccent,
                                  child: Icon(_showTrash ? Icons.delete_forever : Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) async {
                                  setSheetState(() => currentList.removeAt(i));
                                  if (_showTrash) {
                                    await _deletePermanently(notifId);
                                  } else {
                                    await _moveToTrash(notifId);
                                  }
                                },
                                child: Row(
                                  children: [
                                    if (_isEditingNotifs)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: Checkbox(
                                          value: _selectedNotifs.contains(notifId),
                                          activeColor: Colors.blueAccent,
                                          onChanged: (val) {
                                            setSheetState(() {
                                              if (val == true) _selectedNotifs.add(notifId);
                                              else _selectedNotifs.remove(notifId);
                                            });
                                          },
                                        ),
                                      ),
                                    
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.only(left: _isEditingNotifs ? 5 : 20, right: 20, top: 8, bottom: 8),
                                        leading: Icon(isBroadcast ? Icons.campaign : Icons.mail, color: isRead ? Colors.grey : (isBroadcast ? Colors.orangeAccent : Colors.blueAccent), size: 28),
                                        title: Text(
                                          n['message'].replaceAll(RegExp(r'\*\*|\*'), ''), 
                                          maxLines: 2, overflow: TextOverflow.ellipsis, 
                                          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, color: _showTrash ? Colors.grey : (isDarkMode ? Colors.white : Colors.black), fontSize: 14)
                                        ),
                                        subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(n['time'], style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                        
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isRead && !_showTrash) const CircleAvatar(radius: 5, backgroundColor: Colors.blueAccent),
                                            
                                            // NÚT THAO TÁC CÁ NHÂN (Ẩn khi đang edit)
                                            if (!_isEditingNotifs) ...[
                                              const SizedBox(width: 8),
                                              if (_showTrash) ...[
                                                IconButton(icon: const Icon(Icons.restore, color: Colors.green, size: 18), tooltip: "Khôi phục", onPressed: () async { setSheetState(() => currentList.removeAt(i)); await _restoreNotification(notifId); }),
                                                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18), tooltip: "Xóa vĩnh viễn", onPressed: () async { setSheetState(() => currentList.removeAt(i)); await _deletePermanently(notifId); }),
                                              ] else ...[
                                                IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), tooltip: "Bỏ vào thùng rác", onPressed: () async { setSheetState(() => currentList.removeAt(i)); await _moveToTrash(notifId); }),
                                              ]
                                            ]
                                          ],
                                        ),
                                        onTap: _isEditingNotifs 
                                          ? () => setSheetState(() { if (_selectedNotifs.contains(notifId)) _selectedNotifs.remove(notifId); else _selectedNotifs.add(notifId); })
                                          : (_showTrash ? null : () => _markNotificationRead(notifId, n['session_id'], n['message'])),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showBroadcastDialog(String fullMessage) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1F22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.orangeAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(t("Thông báo", "Announcement"), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              MarkdownBody(
                data: fullMessage,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 15, height: 1.6),
                  strong: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            label: const Text("Đã đọc & Nắm rõ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () => Navigator.pop(ctx),
          )
        ],
      )
    );
  }

  Future<void> _markNotificationRead(int notifId, String sessionId, String message) async {
    try {
      await http.put(Uri.parse("$baseUrl/notifications/$notifId/read"));
      await _loadNotifications(); 
      if (!mounted) return;
      Navigator.pop(context); 

      if (sessionId == "broadcast") {
        _showBroadcastDialog(message);
      } else {
        await _loadChatHistory(sessionId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chuyển đến cuộc trò chuyện"), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {}
  }

  void _initTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5); 
    await flutterTts.setVolume(1.0);    
    await flutterTts.setPitch(1.0);      
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => currentlySpeakingIndex = null);
    });
  }

  Future<void> _toggleSpeak(String text, int index) async {
    if (currentlySpeakingIndex == index) {
      await flutterTts.stop();
      setState(() => currentlySpeakingIndex = null);
    } else {
      await flutterTts.stop();
      await flutterTts.setLanguage(currentLanguage == 'English' ? "en-US" : "vi-VN");
      setState(() => currentlySpeakingIndex = index);
      String cleanText = text.replaceAll(RegExp(r'[*#_]'), '');
      await flutterTts.speak(cleanText);
    }
  }

  String t(String vi, String en) => currentLanguage == 'English' ? en : vi;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("Đã sao chép!", "Copied!")), backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.blueAccent, duration: const Duration(seconds: 2)));
  }

  void _retryMessage(int index) {
    if (index > 0 && messages[index - 1]['role'] == 'user') {
      send(messages[index - 1]['text']); 
    }
  }

  Future<void> _submitFeedback(int index, String rating) async {
    String reason = "";
    if (rating == 'down') {
      TextEditingController reasonCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
          title: Text(t("AI trả lời chưa tốt?", "Poor answer?"), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          content: TextField(controller: reasonCtrl, decoration: InputDecoration(hintText: t("Lý do...", "Why..."), hintStyle: const TextStyle(color: Colors.grey)), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t("Bỏ qua", "Skip"))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(t("Gửi", "Send"))),
          ],
        )
      );
      reason = reasonCtrl.text;
    }
    setState(() => messages[index]['feedback'] = rating); 
    try {
      await http.post(Uri.parse("$baseUrl/feedback?username=${widget.username}"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"session_id": currentSessionId ?? "", "bot_response": messages[index]['text'], "rating": rating, "reason": reason}));
    } catch (e) {}
  }

  Stream<String> _typewriterStream(String fullText) async* {
    String currentText = "";
    for (int i = 0; i < fullText.length; i++) {
      currentText += fullText[i];
      yield currentText;
      await Future.delayed(const Duration(milliseconds: 15)); 
    }
  }

  void _groupSessionsByDate() {
    groupedSessions = {"Hôm nay": [], "Hôm qua": [], "7 ngày trước": [], "Cũ hơn": []};
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    for (var session in chatSessions) {
      if (session['last_active'] == null || session['last_active'].toString().isEmpty) {
        groupedSessions["Cũ hơn"]!.add(session);
        continue;
      }
      try {
        DateTime lastActive = DateTime.parse(session['last_active'].toString());
        DateTime d = DateTime(lastActive.year, lastActive.month, lastActive.day);

        if (d == today) groupedSessions["Hôm nay"]!.add(session);
        else if (d == yesterday) groupedSessions["Hôm qua"]!.add(session);
        else if (now.difference(lastActive).inDays <= 7) groupedSessions["7 ngày trước"]!.add(session);
        else groupedSessions["Cũ hơn"]!.add(session);
      } catch (e) { groupedSessions["Cũ hơn"]!.add(session); }
    }
  }

  Future<void> _loadSessions() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/sessions/${widget.username}"));
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          chatSessions = jsonDecode(utf8.decode(res.bodyBytes)) as List? ?? [];
          _groupSessionsByDate();
        });
      }
    } catch (e) {}
  }

  Future<void> _loadChatHistory(String sessionId) async {
    setState(() { currentSessionId = sessionId; isTyping = true; messages.clear(); });
    try {
      final res = await http.get(Uri.parse("$baseUrl/history/$sessionId"));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          messages = data.map((m) => {
            "role": m['role'] ?? "bot",
            "text": m['content'] ?? m['text'] ?? m['question'] ?? m['answer'] ?? t("Lỗi nội dung", "Content error"),
            "sources": m['sources'] ?? [],
            "feedback": "none",
            "time": m['time'] ?? "",
            "isTyping": false 
          }).toList();
          isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) { setState(() => isTyping = false); }
  }

  void _createNewChat() {
    setState(() { currentSessionId = null; messages.clear(); });
  }

  Future<void> _pickFile({required bool isImage}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: isImage ? FileType.image : FileType.custom, allowedExtensions: isImage ? null : ['pdf', 'txt', 'docx', 'csv'], withData: true);
      if (result != null) setState(() => _selectedFile = result.files.first);
    } catch (e) {}
  }

  void _removeSelectedFile() => setState(() => _selectedFile = null);

  void _continueInNewChat(String summary) {
    setState(() { currentSessionId = null; messages.clear(); });
    Future.delayed(const Duration(milliseconds: 500), () {
      send("Dưới đây là tóm tắt từ cuộc trò chuyện trước. Hãy ghi nhớ làm ngữ cảnh:\n\n👉 $summary");
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() { _isListening = true; _wasVoiceInput = true; });
        _speech.listen(
          onResult: (val) {
            setState(() => _controller.text = val.recognizedWords);
            _speechTimeout?.cancel();
            if (val.finalResult) _finalizeSpeechAndSend();
            else _speechTimeout = Timer(const Duration(seconds: 3), () { if (_isListening) _finalizeSpeechAndSend(); });
          }, 
          localeId: currentLanguage == 'English' ? 'en_US' : 'vi_VN'
        );
      }
    } else {
      _speechTimeout?.cancel();
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _finalizeSpeechAndSend() {
    _speechTimeout?.cancel();
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      if (_controller.text.trim().isNotEmpty) send(_controller.text);
      else _wasVoiceInput = false; 
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty && _selectedFile == null) return;
    PlatformFile? fileToSend = _selectedFile; 
    String uiMessage = text;
    if (fileToSend != null) uiMessage = text.trim().isEmpty ? "📎 Đã gửi tệp: ${fileToSend.name}" : "$text\n\n📎 Đính kèm: ${fileToSend.name}";

    setState(() { 
      messages.add({"role": "user", "text": uiMessage, "time": t("Vừa xong", "Just now"), "isTyping": false}); 
      isTyping = true; 
    });
    _controller.clear(); 
    _removeSelectedFile(); 
    _scrollToBottom();

    try {
      http.Response res;
      if (fileToSend != null) {
        var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/ask_with_file?username=${widget.username}&role=${widget.role}"));
        request.fields['question'] = text; 
        request.fields['session_id'] = currentSessionId ?? "";
        if (kIsWeb) request.files.add(http.MultipartFile.fromBytes('file', fileToSend.bytes!, filename: fileToSend.name));
        else request.files.add(await http.MultipartFile.fromPath('file', fileToSend.path!));
        var streamedRes = await request.send();
        res = await http.Response.fromStream(streamedRes);
      } else {
        res = await http.post(
          Uri.parse("$baseUrl/ask?username=${widget.username}&role=${widget.role}"), 
          headers: {"Content-Type": "application/json"}, 
          body: jsonEncode({"question": text, "session_id": currentSessionId ?? ""})
        );
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        if (currentSessionId == null && data['session_id'] != null) {
          currentSessionId = data['session_id'].toString();
          _loadSessions(); 
        }
        String botAnswer = data['answer'] ?? t("Lỗi!", "Error!");
        messages.add({
          "role": "bot", "text": botAnswer, "sources": data['sources'] ?? [], 
          "follow_ups": data['follow_ups'] ?? [], "feedback": "none", 
          "time": data['time'] ?? "", "isTyping": true, "stream": _typewriterStream(botAnswer) 
        });
        isTyping = false;
      });
    } catch (e) {
      setState(() { isTyping = false; messages.add({"role": "bot", "text": "❌ Lỗi: $e", "time": "", "isTyping": false}); });
    }
    _scrollToBottom();
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/sessions/$sessionId"));
      if (res.statusCode == 200) {
        if (currentSessionId == sessionId) _createNewChat();
        _loadSessions();
      }
    } catch (e) {}
  }

  Future<void> _showSummaryDialog(String sessionId) async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
      title: Text(t("Tóm tắt nhanh", "Quick Summary"), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 15), Text(t("Đang nhờ AI...", "Summarizing..."), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))])
    ));
    try {
      final res = await http.get(Uri.parse("$baseUrl/sessions/$sessionId/summarize"));
      Navigator.pop(context); 
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        String summaryText = data['summary'] ?? "Lỗi tóm tắt";
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
          title: Text(t("Tóm tắt", "Summary"), style: const TextStyle(color: Colors.blueAccent)),
          content: Text(summaryText, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: chatFontSize)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t("Đóng", "Close"))),
            ElevatedButton(onPressed: () { Navigator.pop(ctx); _continueInNewChat(summaryText); }, child: Text(t("Tiếp nối", "Continue")))
          ],
        ));
      }
    } catch (e) { Navigator.pop(context); }
  }

  void _showRenameDialog(String sessionId, String currentTitle) {
    TextEditingController renameCtrl = TextEditingController(text: currentTitle);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
      title: Text(t("Đổi tên", "Rename"), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      content: TextField(controller: renameCtrl, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t("Hủy", "Cancel"))),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          if (renameCtrl.text.isNotEmpty) {
            await http.put(Uri.parse("$baseUrl/sessions/$sessionId/rename"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"title": renameCtrl.text}));
            _loadSessions();
          }
        }, child: Text(t("Lưu", "Save"))),
      ],
    ));
  }

  void _openProfileSettings() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Color sheetBg = isDarkMode ? const Color(0xFF1E1F22) : Colors.white;
            Color textColor = isDarkMode ? Colors.white : Colors.black87;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: sheetBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _changeAvatar(setModalState),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: currentAvatarUrl != null ? NetworkImage(currentAvatarUrl!) : null,
                              child: currentAvatarUrl == null 
                                  ? Text(displayUsername[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 14, color: Colors.blueAccent))
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayUsername, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          Text("${t("Vai trò:", "Role:")} ${widget.role.toUpperCase()}", style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 40, color: Colors.grey),
                  SwitchListTile(title: Text(t("Chế độ tối", "Dark Mode"), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), value: isDarkMode, onChanged: (val) { setState(() => isDarkMode = val); setModalState(() {}); }),
                  ListTile(title: Text("${t("Cỡ chữ:", "Font Size:")} ${chatFontSize.toInt()}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), subtitle: Slider(value: chatFontSize, min: 12.0, max: 24.0, divisions: 6, onChanged: (val) { setState(() => chatFontSize = val); setModalState(() {}); })),
                  ListTile(title: Text(t("Độ sáng màn hình", "Screen Brightness"), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), subtitle: Slider(value: brightnessLevel, min: 0.1, max: 1.0, onChanged: (val) { setState(() => brightnessLevel = val); setModalState(() {}); })),
                  ListTile(
                    title: Text(t("Ngôn ngữ", "Language"), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    trailing: DropdownButton<String>(
                      value: currentLanguage, dropdownColor: sheetBg,
                      style: TextStyle(color: isDarkMode ? Colors.blueAccent : Colors.blue), underline: const SizedBox(),
                      items: ['Tiếng Việt', 'English'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) { if (v != null) { setState(() => currentLanguage = v); setModalState(() {}); } },
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.logout, color: Colors.white), label: Text(t("Đăng Xuất", "Logout"), style: const TextStyle(color: Colors.white)),
                      onPressed: () { Navigator.pushReplacementNamed(context, '/'); },
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == 'locked') {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_person, size: 80, color: Colors.redAccent), const SizedBox(height: 20),
          const Text("TÀI KHOẢN ĐÃ BỊ KHÓA", style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          ElevatedButton(onPressed: () { Navigator.pushReplacementNamed(context, '/'); }, child: const Text("Đăng xuất"))
        ])),
      );
    }
    
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 800;
    Color mainBg = isDarkMode ? const Color(0xFF131314) : const Color(0xFFFFFFFF);
    Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: mainBg,
          key: _scaffoldKey,
          drawer: isDesktop ? null : Drawer(
            child: ChatSidebar(
              isDarkMode: isDarkMode, isDesktop: false, isSidebarOpen: isSidebarOpen,
              groupedSessions: groupedSessions, currentSessionId: currentSessionId,
              role: widget.role, unansweredCount: unansweredCount, t: t,
              onToggleSidebar: () => Navigator.pop(context),
              onNewChat: () { _createNewChat(); Navigator.pop(context); },
              onLoadChatHistory: (id) { _loadChatHistory(id); Navigator.pop(context); },
              onRename: _showRenameDialog, onSummarize: _showSummaryDialog, onDelete: _deleteSession,
              onOpenSettings: () { Navigator.pop(context); _openProfileSettings(); },
              onOpenAdmin: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen())).then((_) => _loadNotifications()); },
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                // SIDEBAR CHO DESKTOP ĐÃ ĐƯỢC CHỐNG LAG/VỠ KHUNG
                if (isDesktop)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut, // Thêm curve này cho nó mượt mà có trớn
                    width: isSidebarOpen ? 280 : 0, 
                    clipBehavior: Clip.antiAlias, // Quan trọng: Cắt phần thừa
                    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1F22) : const Color(0xFFF0F4F9)),
                    
                    // THỦ THUẬT Ở ĐÂY: Bọc trong SingleChildScrollView nằm ngang
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(), // Khóa không cho người dùng tự lấy tay lướt ngang
                      child: SizedBox(
                        width: 280, // Giữ cứng chiều rộng bên trong để các nút/chữ không bị ép vỡ
                        child: ChatSidebar(
                          isDarkMode: isDarkMode, isDesktop: true, isSidebarOpen: isSidebarOpen,
                          groupedSessions: groupedSessions, currentSessionId: currentSessionId,
                          role: widget.role, unansweredCount: unansweredCount, t: t,
                          onToggleSidebar: () => setState(() => isSidebarOpen = !isSidebarOpen),
                          onNewChat: _createNewChat, onLoadChatHistory: _loadChatHistory,
                          onRename: _showRenameDialog, onSummarize: _showSummaryDialog, onDelete: _deleteSession,
                          onOpenSettings: _openProfileSettings,
                          onOpenAdmin: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen())).then((_) => _loadNotifications()),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 60, padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 10),
                        child: Row(
                          children: [
                            if (!isDesktop) IconButton(icon: const Icon(Icons.menu), color: textColor, onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                            if (isDesktop && !isSidebarOpen) IconButton(icon: const Icon(Icons.menu), color: textColor, onPressed: () => setState(() => isSidebarOpen = true)),
                            const SizedBox(width: 5),
                            Expanded(child: Text("ABC TECH AI", style: TextStyle(color: textColor, fontSize: isDesktop ? 18 : 16, fontWeight: FontWeight.bold))),
                            
                            Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.redAccent, offset: const Offset(-5, 5), child: IconButton(icon: Icon(Icons.notifications_none_outlined, color: textColor), onPressed: _showNotificationSheet)),
                            const SizedBox(width: 10),
                            
                            GestureDetector(
                              onTap: _openProfileSettings,
                              child: CircleAvatar(
                                radius: isDesktop ? 18 : 16, 
                                backgroundColor: Colors.blueAccent, 
                                backgroundImage: currentAvatarUrl != null ? NetworkImage(currentAvatarUrl!) : null,
                                child: currentAvatarUrl == null ? Text(displayUsername[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                              )
                            )
                          ],
                        ),
                      ),
                      
                      if (widget.role != 'admin') OnboardingChatWidget(userId: widget.username, onAskAI: send),

                      Expanded(
                        child: messages.isEmpty 
                          ? WelcomeView(
                              displayUsername: displayUsername,
                              role: widget.role,
                              isDarkMode: isDarkMode,
                              chatFontSize: chatFontSize,
                              t: t,
                              onSend: send,
                            ) 
                          : ChatMessageList(
                              scrollController: _scrollController, messages: messages, role: widget.role,
                              isTyping: isTyping, isDarkMode: isDarkMode, displayUsername: displayUsername,
                              chatFontSize: chatFontSize, currentlySpeakingIndex: currentlySpeakingIndex,
                              t: t, onToggleSpeak: _toggleSpeak, onCopy: _copyToClipboard, onRetry: _retryMessage,
                              onSubmitFeedback: _submitFeedback, onFollowUpClick: send, onBroadcast: _broadcastMessage, 
                              onLaunchSource: (url) async {
                                final Uri uri = Uri.parse("$baseUrl/files/$url");
                                if (!await launchUrl(uri)) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $url')));
                              },
                              onTypingDone: (index) {
                                if (mounted) setState(() { messages[index]['isTyping'] = false; });
                              },
                            )
                      ),

                      ChatInputArea(
                        isDarkMode: isDarkMode, isListening: _isListening, selectedFile: _selectedFile, controller: _controller,
                        chatFontSize: chatFontSize, t: t, onPickFile: (isImage) => _pickFile(isImage: isImage),
                        onRemoveFile: _removeSelectedFile, onListen: _listen, onSend: send,
                      ),
                      
                      Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(t("ABC TECH AI có thể mắc sai sót.", "AI can make mistakes."), style: TextStyle(color: isDarkMode ? Colors.white24 : Colors.black38, fontSize: 11)))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IgnorePointer(child: Container(color: Colors.black.withOpacity(1.0 - brightnessLevel))),
      ],
    );
  }
}