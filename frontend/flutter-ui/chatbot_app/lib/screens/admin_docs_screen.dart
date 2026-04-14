import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Nhớ thêm: flutter pub add file_picker

class AdminDocsScreen extends StatefulWidget {
  @override
  _AdminDocsScreenState createState() => _AdminDocsScreenState();
}

class _AdminDocsScreenState extends State<AdminDocsScreen> {
  List<dynamic> docs = [];
  bool isLoading = false;
  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  // 1. Lấy danh sách file từ Backend
  Future<void> _fetchDocs() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/documents"));
      if (res.statusCode == 200) {
        setState(() => docs = jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      print("Lỗi lấy docs: $e");
    }
    setState(() => isLoading = false);
  }

  // 2. Upload file PDF mới
  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => isLoading = true);
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload"));
      
      // Xử lý cho Web (Dùng bytes thay vì path)
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        result.files.first.bytes!,
        filename: result.files.first.name,
      ));

      var res = await request.send();
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã nạp kiến thức mới thành công!")));
        _fetchDocs();
      }
    }
    setState(() => isLoading = false);
  }

  // 3. Xóa file
  Future<void> _deleteDoc(String name) async {
    final res = await http.delete(Uri.parse("$baseUrl/documents/$name"));
    if (res.statusCode == 200) {
      _fetchDocs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171717),
      appBar: AppBar(
        title: Text("Quản lý tài liệu Nội bộ"),
        backgroundColor: Color(0xFF212121),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchDocs),
        ],
      ),
      body: Column(
        children: [
          // Banner hướng dẫn
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Thêm file PDF vào đây để AI 'học' và trả lời câu hỏi dựa trên nội dung đó.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadFile,
                  icon: Icon(Icons.upload_file),
                  label: Text("Thêm File"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                )
              ],
            ),
          ),
          
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    return Card(
                      color: Color(0xFF2F2F2F),
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        title: Text(docs[i]['name'], style: TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _deleteDoc(docs[i]['name']),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}