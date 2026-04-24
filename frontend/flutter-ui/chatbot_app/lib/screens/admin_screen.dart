import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:fl_chart/fl_chart.dart'; // <-- THÊM DÒNG NÀY

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String baseUrl = "https://chatbot-backend-qjw8.onrender.com"; // Nhớ đổi IP LAN nếu chạy trên điện thoại thật

  Map<String, dynamic> stats = {"total_messages_today": 0, "unanswered_count": 0, "top_docs": [],
  "last_7_days": [] // <-- THÊM MỤC NÀY
  };
  List<dynamic> users = [];
  List<dynamic> unansweredQuestions = [];
  List<dynamic> documents = [];
  List<dynamic> faqs = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadStats(),
      _loadUsers(),
      _loadUnanswered(),
      _loadDocuments(),
      _loadFaqs(), 
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  // ================= API CALLS =================
  Future<void> _loadStats() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/stats"));
      if (res.statusCode == 200 && mounted) setState(() => stats = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (e) { print("Lỗi tải thống kê: $e"); }
  }

  Future<void> _loadUsers() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/users"));
      if (res.statusCode == 200 && mounted) setState(() => users = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (e) { print("Lỗi tải user: $e"); }
  }

  Future<void> _loadUnanswered() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/unanswered"));
      if (res.statusCode == 200 && mounted) setState(() => unansweredQuestions = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (e) { print("Lỗi tải câu hỏi: $e"); }
  }

  Future<void> _loadDocuments() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/documents"));
      if (res.statusCode == 200 && mounted) setState(() => documents = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (e) { print("Lỗi tải tài liệu: $e"); }
  }

  Future<void> _loadFaqs() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/faqs"));
      if (res.statusCode == 200 && mounted) setState(() => faqs = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (e) { print("Lỗi tải FAQ: $e"); }
  }

  // ================= DIALOG XÁC NHẬN CHUNG =================
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2F2F2F),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  // ================= HÀNH ĐỘNG NHÂN VIÊN =================
  Future<void> _changeUserRole(String username, String newRole) async {
    setState(() {
      int index = users.indexWhere((u) => u['username'] == username);
      if (index != -1) users[index]['role'] = newRole;
    });
    try {
      await http.put(Uri.parse("$baseUrl/admin/users/$username/role"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"role": newRole}));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent));
      _loadUsers();
    }
  }

  // ================= HÀNH ĐỘNG HỎI ĐÁP (CÂU HỎI MỒ CÔI) =================
  Future<void> _deleteUnanswered(int id) async {
    bool? confirm = await _showConfirmDialog("Xóa câu hỏi", "Bạn có chắc muốn bỏ qua câu hỏi này?");
    if (confirm == true) {
      try {
        await http.delete(Uri.parse("$baseUrl/admin/unanswered/$id"));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa câu hỏi!"), backgroundColor: Colors.green));
        await _loadUnanswered(); 
      } catch (e) { print(e); }
    }
  }

  Future<void> _answerUnanswered(int id, String questionText) async {
    TextEditingController answerCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2F2F2F),
        title: const Text("Trả lời câu hỏi", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Câu hỏi: $questionText", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 15),
            TextField(
              controller: answerCtrl, maxLines: 4,
              decoration: InputDecoration(
                hintText: "Nhập câu trả lời. Hệ thống sẽ lưu vào Kho FAQ...",
                hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: const Color(0xFF16161E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (answerCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang lưu & Nạp vào AI...")));
                try {
                  var res = await http.post(
                    Uri.parse("$baseUrl/admin/answer_unanswered/$id"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({"question": questionText, "answer": answerCtrl.text.trim()})
                  );
                  if (res.statusCode == 200) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu và đồng bộ cho Nhân viên!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    await _loadAllData(); 
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent));
                }
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Lưu và Nạp AI", style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );
  }

  // ================= HÀNH ĐỘNG KHO FAQ (SỬA & XÓA) =================
  Future<void> _deleteFaq(int index, String faqIdOrFilename) async {
    bool? confirm = await _showConfirmDialog("Xóa kiến thức", "Bạn có chắc chắn muốn xóa kiến thức này khỏi bộ nhớ AI không?");
    if (confirm != true) return;

    try {
      String endpoint = faqIdOrFilename.contains('.') ? "/admin/documents/$faqIdOrFilename" : "/admin/faqs/$faqIdOrFilename";
      final res = await http.delete(Uri.parse("$baseUrl$endpoint"));

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() { faqs.removeAt(index); }); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa kiến thức thành công!"), backgroundColor: Colors.green));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi Server: ${res.statusCode}"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e"), backgroundColor: Colors.redAccent));
    }
  }

  void _showEditDialog(int index, Map<String, dynamic> faq) {
    TextEditingController questionCtrl = TextEditingController(text: faq['question'] ?? "");
    TextEditingController answerCtrl = TextEditingController(text: faq['answer'] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F22),
        title: const Text("Chỉnh sửa kiến thức", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Câu hỏi (Tóm tắt)", labelStyle: TextStyle(color: Colors.blueAccent)),
                maxLines: 2,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: answerCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Câu trả lời chuẩn (AI sẽ học theo)", labelStyle: TextStyle(color: Colors.greenAccent)),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (answerCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang đồng bộ dữ liệu...")));
              
              try {
                final res = await http.put(
                  Uri.parse("$baseUrl/admin/faqs/${faq['id']}"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"question": questionCtrl.text.trim(), "answer": answerCtrl.text.trim()})
                );
                
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (res.statusCode == 200 && mounted) {
                  setState(() {
                    faqs[index]['question'] = questionCtrl.text.trim();
                    faqs[index]['answer'] = answerCtrl.text.trim();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật FAQ và đồng bộ cho User!"), backgroundColor: Colors.green));
                }
              } catch (e) { 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent));
              }
            },
          ),
        ],
      )
    );
  }

  // ================= HÀNH ĐỘNG TÀI LIỆU CHUNG =================
  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt', 'docx'], withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/admin/upload"));
      request.fields['role'] = 'staff'; 
      try {
        if (kIsWeb) request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
        else request.files.add(await http.MultipartFile.fromPath('file', file.path!));
        
        if (!mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tải lên & Nạp vào AI... (Vui lòng đợi)"), duration: Duration(seconds: 30)));
        
        var res = await request.send();
        var resData = await res.stream.bytesToString(); 
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
        
        if (res.statusCode == 200 && !resData.toLowerCase().contains("error")) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tải lên thành công!", style: TextStyle(color: Colors.green))));
          _loadDocuments(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi Server: $resData"), backgroundColor: Colors.redAccent));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _editDocumentRole(String filename, String currentRole) async {
    String newRole = currentRole == 'staff' ? 'admin' : 'staff';
    try {
      await http.post(Uri.parse("$baseUrl/admin/set-permission?file_name=$filename&role=$newRole"));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã đổi quyền $filename thành $newRole"), backgroundColor: Colors.green));
      _loadDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi cập nhật quyền: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _launchSource(String fileName) async {
    final Uri url = Uri.parse("$baseUrl/files/$fileName");
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể mở: $fileName', style: const TextStyle(color: Colors.white))));
    }
  }

  // ================= XÂY DỰNG GIAO DIỆN CHÍNH =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        title: const Text("QUẢN TRỊ HỆ THỐNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        iconTheme: const IconThemeData(color: Colors.blueAccent),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blueAccent), tooltip: "Làm mới dữ liệu", onPressed: _loadAllData),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent, labelColor: Colors.blueAccent, unselectedLabelColor: Colors.grey, isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Thống kê"),
            Tab(icon: Icon(Icons.question_answer), text: "Hỏi & Đáp"), 
            Tab(icon: Icon(Icons.people), text: "Nhân viên"),
            Tab(icon: Icon(Icons.folder), text: "Tài liệu CT"), 
          ],
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildStatsTab(),
              _buildQaTab(), 
              _buildUsersTab(),
              _buildDocumentsTab(),
            ],
          ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // TAB 1: THỐNG KÊ (DASHBOARD)
  // TAB 1: THỐNG KÊ (DASHBOARD) - ĐÃ NÂNG CẤP BIỂU ĐỒ
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hai thẻ Header
          Row(
            children: [
              Expanded(child: _buildStatCard("Tin nhắn hôm nay", stats['total_messages_today'].toString(), Icons.chat, Colors.greenAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard("CH chưa trả lời", stats['unanswered_count'].toString(), Icons.warning_amber, Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 30),
          
          // ==============================
          // BIỂU ĐỒ CỘT (7 NGÀY QUA)
          // ==============================
          const Text("📊 TƯƠNG TÁC 7 NGÀY QUA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildMessageBarChart(),

          const SizedBox(height: 30),
          
          // ==============================
          // BIỂU ĐỒ TRÒN (TÀI LIỆU HOT)
          // ==============================
          const Text("🔥 TOP TÀI LIỆU TRÍCH XUẤT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildTopDocsPieChart(),
          
          const SizedBox(height: 50), // Cách đáy một chút
        ],
      ),
    );
  }

  // WIDGET: VẼ BIỂU ĐỒ CỘT
  Widget _buildMessageBarChart() {
    List<dynamic> days = stats['last_7_days'] ?? [];
    if (days.isEmpty) return _buildEmptyState(Icons.bar_chart, "Đang tải dữ liệu biểu đồ...");

    double maxY = 0;
    for(var d in days) { if(d['count'] > maxY) maxY = d['count'].toDouble(); }
    if (maxY == 0) maxY = 10; // Đáy thấp nhất nếu không có tin nhắn nào

    return Container(
      height: 280,
      padding: const EdgeInsets.only(top: 30, bottom: 10, left: 15, right: 15),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + (maxY * 0.2), // Thêm 20% đệm ở trên chóp
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              // Phiên bản mới dùng getTooltipColor để bo góc và tô màu nền
              getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.9), 
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "${rod.toY.toInt()} tin nhắn",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }
            )
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(days[value.toInt()]['date'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Ẩn cột Y cho mượt
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: days[index]['count'].toDouble(),
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent], // Màu Gradient cực ngầu
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  // WIDGET: VẼ BIỂU ĐỒ TRÒN
  Widget _buildTopDocsPieChart() {
    List<dynamic> docs = stats['top_docs'] ?? [];
    if (docs.isEmpty) return _buildEmptyState(Icons.pie_chart, "Chưa có tài liệu nào được trích xuất.");

    List<Color> colors = [Colors.blueAccent, Colors.redAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent];

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          // Nửa trái: Hình tròn
          Expanded(
            flex: 4,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35, // Lỗ rỗng ở giữa
                sections: List.generate(docs.length, (i) {
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: docs[i]['count'].toDouble(),
                    title: '${docs[i]['count']}',
                    radius: 45,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          // Nửa phải: Chú thích (Legend)
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(docs.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(docs[i]['name'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3), overflow: TextOverflow.ellipsis, maxLines: 2)
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  // TAB 2: HỎI ĐÁP
  Widget _buildQaTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Cần trả lời"), Tab(text: "Kho FAQ (Đã lưu)")],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUnansweredList(),
                _buildFaqList(), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnansweredList() {
    if (unansweredQuestions.isEmpty) return _buildEmptyState(Icons.check_circle, "Tuyệt vời! Không có câu hỏi nào bị bỏ sót.");
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: unansweredQuestions.length,
      itemBuilder: (context, i) {
        var q = unansweredQuestions[i];
        return Card(
          color: const Color(0xFF16161E), margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text(q['question'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Bởi: ${q['username']} • ${q['time']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.question_answer, color: Colors.greenAccent), onPressed: () => _answerUnanswered(q['id'], q['question']), tooltip: "Trả lời"),
                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteUnanswered(q['id']), tooltip: "Xóa"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqList() {
    if (faqs.isEmpty) return _buildEmptyState(Icons.library_books, "Kho FAQ hiện đang trống.");
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      physics: const BouncingScrollPhysics(),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        var faq = faqs[index];

        return Card(
          color: const Color(0xFF16161E),
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(faq['question'] ?? faq['file_name'] ?? "Không có câu hỏi", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(faq['answer'] ?? "Nhấn [Xem file] để đọc nội dung", style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))),
                  ],
                ),
                const Divider(height: 30, color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                      label: const Text("Sửa", style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () => _showEditDialog(index, faq),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      label: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => _deleteFaq(index, faq['id']?.toString() ?? faq['file_name']),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: QUẢN LÝ NHÂN VIÊN
  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: users.length,
      itemBuilder: (context, i) {
        var u = users[i];
        return Card(
          color: const Color(0xFF16161E), margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.purpleAccent.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.purpleAccent)),
            title: Text(u['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: DropdownButton<String>(
              value: u['role'],
              dropdownColor: const Color(0xFF2F2F2F),
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              items: ['admin', 'staff', 'locked'].map((String role) {
                return DropdownMenuItem(value: role, child: Text(role.toUpperCase(), style: TextStyle(color: role == 'locked' ? Colors.redAccent : Colors.blueAccent)));
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) _changeUserRole(u['username'], newRole);
              },
            ),
          ),
        );
      },
    );
  }

  // TAB 4: QUẢN LÝ TÀI LIỆU CÔNG TY
  Widget _buildDocumentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: ElevatedButton.icon(
            onPressed: _uploadDocument,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text("Tải lên Tài liệu Mới (PDF, TXT, DOCX)", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        Expanded(
          child: documents.isEmpty ? _buildEmptyState(Icons.folder_open, "Chưa có tài liệu chính thức nào.") : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: documents.length,
            itemBuilder: (context, i) {
              var d = documents[i];
              return Card(
                color: const Color(0xFF16161E), margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(d['file_name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Quyền truy cập: ${d['role'].toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.visibility, color: Colors.greenAccent), tooltip: "Đọc tài liệu", onPressed: () => _launchSource(d['file_name'])),
                      IconButton(icon: const Icon(Icons.edit_attributes, color: Colors.orangeAccent), tooltip: "Đổi quyền", onPressed: () => _editDocumentRole(d['file_name'], d['role'])),
                      
                      // ==========================================
                      // CẬP NHẬT: NÚT XÓA TÀI LIỆU OPTIMISTIC UI
                      // ==========================================
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent), 
                        tooltip: "Xóa tài liệu", 
                        onPressed: () async {
                          bool? confirm = await _showConfirmDialog("Xóa tài liệu", "Bạn có chắc chắn muốn xóa file ${d['file_name']} không?");
                          
                          if (confirm == true) {
                            // 1. Ẩn ngay lập tức khỏi giao diện
                            setState(() {
                              documents.removeWhere((doc) => doc['file_name'] == d['file_name']);
                            });

                            // 2. Báo thành công
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đã xóa file! Đang cập nhật lại não AI ngầm...", style: TextStyle(color: Colors.white)), 
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2), 
                              )
                            );

                            // 3. Xóa ngầm trên Server
                            http.delete(Uri.parse("$baseUrl/admin/documents/${d['file_name']}")).then((res) {
                              if (res.statusCode != 200) {
                                print("Lỗi xóa server: ${res.body}");
                              }
                            }).catchError((e) => print("Lỗi mạng: $e"));
                          }
                        }
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}