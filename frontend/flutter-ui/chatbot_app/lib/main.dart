import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_docs_screen.dart';
import 'screens/admin_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved session data
  final prefs = await SharedPreferences.getInstance();
  final savedUsername = prefs.getString('username');
  final savedRole = prefs.getString('role');
  final savedIsOnboarded = prefs.getBool('is_onboarded') ?? false;
  
  runApp(KnowledgeApp(
    savedUsername: savedUsername,
    savedRole: savedRole,
    savedIsOnboarded: savedIsOnboarded,
  ));
}

class KnowledgeApp extends StatelessWidget {
  final String? savedUsername;
  final String? savedRole;
  final bool savedIsOnboarded;

  const KnowledgeApp({
    this.savedUsername,
    this.savedRole,
    this.savedIsOnboarded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine initial route based on saved session
    String initialRoute = '/login';
    if (savedUsername != null && savedUsername!.isNotEmpty) {
      initialRoute = '/chat';
    }

    return MaterialApp(
      title: 'ABC TECH AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), 
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          // Get arguments or use saved data
          final args = settings.arguments as Map<String, dynamic>?;
          
          final username = args?["username"] ?? savedUsername ?? "Guest";
          final role = args?["role"] ?? savedRole ?? "staff";
          final isOnboarded = args?["isOnboarded"] ?? savedIsOnboarded;

          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              username: username.toString(),
              role: role.toString(),
              isOnboarded: isOnboarded as bool,
            ),
          );
        }
        
        return null; 
      },
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/admin': (context) => AdminScreen(),
        '/admin_docs': (context) => AdminDocsScreen(),
      },
    );
  }
}