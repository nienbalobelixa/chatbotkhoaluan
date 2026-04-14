import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = "http://127.0.0.1:8000"; // Android

  static String? token;

  static Future login(String u, String p) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": u, "password": p}),
    );

    final data = jsonDecode(res.body);

    if (data['status'] == 'success') {
      token = data['token'];
    }

    return data;
  }

  static Future register(String u, String p) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": u, "password": p}),
    );

    return jsonDecode(res.body);
  }

  static Future ask(String question) async {
    final res = await http.post(
      Uri.parse("$baseUrl/ask"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"question": question}),
    );

    return jsonDecode(res.body);
  }
}