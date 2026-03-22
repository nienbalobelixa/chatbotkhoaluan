import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class AdminDocsScreen extends StatefulWidget {
  @override
  _AdminDocsScreenState createState() => _AdminDocsScreenState();
}

class _AdminDocsScreenState extends State<AdminDocsScreen> {
  List<dynamic> _docs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  // 1. Lấy danh sách file PDF từ Server
  Future<void> _fetchDocs() async {
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/documents'));
      if (res.statusCode == 200) {
        setState(() => _docs = jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      print("Lỗi tải danh sách: $e");
    }
  }

  // 2. Chọn file từ máy và Tải lên Server
  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/upload'));
      
      // Hỗ trợ cả Web và Mobile
      if (result.files.single.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file', result.files.single.bytes!,
          filename: result.files.single.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', result.files.single.path!));
      }

      var res = await request.send();
      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tải lên và cập nhật AI thành công!")));
        _fetchDocs(); // Load lại danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi tải lên")));
      }
    }
  }

  // 3. Xóa tài liệu
  Future<void> _deleteDoc(String name) async {
    final res = await http.delete(Uri.parse('http://127.0.0.1:8000/documents/$name'));
    if (res.statusCode == 200) {
      _fetchDocs();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa file và cập nhật lại AI")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý tài liệu nội bộ"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          if (_isLoading) LinearProgressIndicator(color: Colors.orange),
          Expanded(
            child: _docs.isEmpty
                ? Center(child: Text("Chưa có tài liệu nào trong hệ thống"))
                : ListView.builder(
                    itemCount: _docs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(_docs[index]['name']),
                        subtitle: Text(_docs[index]['size'] ?? ""),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_sweep, color: Colors.grey),
                          onPressed: () => _deleteDoc(_docs[index]['name']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndUpload,
        label: Text("Tải PDF mới lên AI"),
        icon: Icon(Icons.upload_file),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}