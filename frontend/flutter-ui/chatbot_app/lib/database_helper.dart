import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {

    if (kIsWeb) {
    // Trả về một database ảo hoặc xử lý khác. 
    // Nhưng tốt nhất là bạn nên chạy trên Android Emulator để đúng yêu cầu Mobile.
    throw Exception("SQLite không hỗ trợ trên Web. Hãy chạy trên Android Emulator!");
  }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE chat (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT, text TEXT, sources TEXT)');
  }

  Future<void> insertMessage(String role, String text, List<dynamic> sources) async {
    final db = await instance.database;
    await db.insert('chat', {'role': role, 'text': text, 'sources': jsonEncode(sources)});
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await instance.database;
    return await db.query('chat', orderBy: 'id ASC');
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('chat');
  }
}