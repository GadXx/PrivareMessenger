// messenger/presentation/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? user;
  String? error;
  bool loading = false;

  Future<void> searchUser() async {
    setState(() {
      loading = true;
      error = null;
      user = null;
    });

    final login = _controller.text.trim();
    if (login.isEmpty) {
      setState(() {
        error = "Введите логин";
        loading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('http://192.168.0.105:8080/api/get-user-by-login/$login');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          user = data;
          error = null;
        });
      } else if (resp.statusCode == 404) {
        setState(() {
          error = "Пользователь не найден";
        });
      } else {
        setState(() {
          error = "Ошибка сервера: ${resp.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = "Ошибка запроса: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск пользователей')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Логин пользователя',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => searchUser(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : searchUser,
              child: loading ? const CircularProgressIndicator() : const Text('Найти'),
            ),
            const SizedBox(height: 24),
            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            if (user != null) ...[
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user!['username'] ?? ''),
                  subtitle: Text('@${user!['login']}'),
                  trailing: ElevatedButton(
                    child: const Text('Открыть чат'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            userId: user!['id'],
                            username: user!['username'],
                            login: user!['login'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
