import 'package:flutter/material.dart';
import 'package:app/auth/data/auth_api.dart';
import 'package:app/auth/domain/auth_repository.dart';
import 'package:app/auth/presentation/screens/register_screen.dart';
import 'package:app/auth/presentation/screens/profile_screen.dart';
import 'package:app/navigate/presentation/screens/start_screen.dart';

import 'package:app/messenger/presentation/screens/main_screen.dart';
import 'package:app/messenger/presentation/screens/search_screen.dart';

import 'package:app/messenger/data/ws_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = AuthApi('http://192.168.0.105:8080');
  final repo = AuthRepository(api);

  try {
    await WebSocketService().connect();
  } catch (e) {
    print('WebSocket error: $e');
  }

  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  final AuthRepository repo;
  const MyApp({Key? key, required this.repo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      initialRoute: '/',
      routes: {
        '/': (context) => StartScreen(repo: repo),
        '/register': (context) => RegisterScreen(repo: repo),
        '/profile': (context) => ProfileScreen(),
        '/main': (context) => const MainScreen(),
        '/search': (context) => const SearchScreen(),
      },
      // Можно убрать builder вообще, если не нужен глобальный stream listen
    );
  }
}
