// messenger/presentation/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:app/common/widgets/app_drawer.dart';
import 'chat_screen.dart';

class ChatUser {
  final String id;
  final String username;
  final String login;
  // final SignalChatKeys? keys; // Тут будут ключи для чата

  ChatUser({
    required this.id,
    required this.username,
    required this.login,
    // this.keys,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<ChatUser> chats = [
    // Пока тестовые данные
    ChatUser(id: '1', username: 'Alice', login: 'alice'),
    ChatUser(id: '2', username: 'Bob', login: 'bob'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои чаты')),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(chat.username),
            subtitle: Text('@${chat.login}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ChatScreen(
                        userId: chat.id,
                        username: chat.username,
                        login: chat.login,
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () {
          Navigator.pushNamed(context, '/search');
        },
        tooltip: 'Найти пользователя',
      ),
    );
  }
}
