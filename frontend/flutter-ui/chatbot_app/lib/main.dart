import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'admin_docs_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KnowledgeApp());
}

class KnowledgeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ABC TECH AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/chat': (context) => ChatScreen(),
        '/admin': (context) => AdminDocsScreen(),
      },
    );
  }
}

// ================= LOGIN =================
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _u = TextEditingController();
  final TextEditingController _p = TextEditingController();
  bool _isLogining = false;

  String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    return "http://10.0.2.2:8000";
  }

  Future<void> _login() async {
    if (_u.text.isEmpty) return;

    setState(() => _isLogining = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _u.text,
          "password": _p.text
        }),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200 && data['status'] == 'success') {
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sai tài khoản!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối Backend")),
      );
    }

    setState(() => _isLogining = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 60, color: Colors.blue),
              const Text(
                "ABC TECH AI",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _u,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _p,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              _isLogining
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _login,
                      child: const Text("ĐĂNG NHẬP"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CHAT =================
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    return "http://10.0.2.2:8000";
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      if (!kIsWeb) {
        final data = await DatabaseHelper.instance.getMessages();

        setState(() {
          messages = data.map((m) {
            return {
              "role": m['role'] ?? "bot",
              "text": m['text'] ?? "",
              "sources": _safeDecode(m['sources'])
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Load history lỗi: $e");
    }
  }

  List _safeDecode(dynamic raw) {
    try {
      if (raw == null) return [];
      return jsonDecode(raw);
    } catch (_) {
      return [];
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text, "sources": []});
      isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": text}),
      );

      print("RAW: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        String botText =
            data['answer'] ??
            data['response'] ??
            data['message'] ??
            "⚠️ Không có dữ liệu";

        List sources = data['sources'] ?? [];

        setState(() {
          messages.add({
            "role": "bot",
            "text": botText,
            "sources": sources
          });
          isLoading = false;
        });

        if (!kIsWeb) {
          await DatabaseHelper.instance.insertMessage(
            "bot",
            botText,
            sources,
          );
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "bot",
          "text": "❌ Không kết nối được Backend",
          "sources": []
        });
        isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Widget _buildMessage(String text, bool isUser) {
    if (text.trim().isEmpty) {
      return const Text("⚠️ Không có nội dung");
    }

    try {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      );
    } catch (_) {
      return Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trợ lý AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.orange),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("🤖 AI đang suy nghĩ..."),
                  );
                }

                final msg = messages[i];
                bool isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessage(msg["text"] ?? "", isUser),
                        if (!isUser && msg["sources"].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "Nguồn: ${msg["sources"].join(", ")}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => sendMessage(_controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}