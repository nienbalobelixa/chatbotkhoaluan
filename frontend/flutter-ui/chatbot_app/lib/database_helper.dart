import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, 'chat.db'), version: 1, onCreate: (db, v) {
      db.execute('CREATE TABLE messages(id INTEGER PRIMARY KEY, role TEXT, text TEXT)');
    });
  }
}