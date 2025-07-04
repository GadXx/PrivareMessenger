import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app/common/widgets/app_drawer.dart';
import 'package:app/messenger/domain/chat_repository.dart';
import 'package:app/messenger/data/chat_api.dart';
import 'package:app/messenger/data/models/chat_request.dart';
import 'package:app/storage/secure_storage.dart';
import 'package:app/messenger/utils/chat_util.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String login;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.login,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final repo = ChatRepository(ChatApi('http://192.168.0.105:8080'));
  final messageController = TextEditingController();

  late ChatRequest bundle;

  // Функция для сокращенного отображения base64
  String short(String? v) => v == null ? 'null' : (v.length <= 20 ? v : v.substring(0, 20) + '...');

  void debugKey(String name, List<int> bytes) {
    print('$name: ${base64Encode(bytes)} (${bytes.length} bytes)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(radius: 18, child: Icon(Icons.person)),
            SizedBox(width: 10),
            Text(widget.username),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<ChatRequest>(
              future: repo.getKeyBundle(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('Нет данных'));
                }

                bundle = snapshot.data!;
                print(bundle);

                return FutureBuilder<Map<String, String?>>(
                  future: () async {
                    final storage = SecureStorageKeys();
                    return {
                      'identityPrivate':      await storage.read('identityPrivate'),
                      'identityPublic':       await storage.read('identityPublic'),
                      'xIdentityPrivate':      await storage.read('xIdentityPrivate'),
                      'xIdentityPublic':       await storage.read('xIdentityPublic'),
                      'signedPrePrivate':     await storage.read('signedPrePrivate'),
                      'signedPrePublic':      await storage.read('signedPrePublic'),
                      'signedPreSignature':   await storage.read('signedPreSignature'),
                      'signedPreKeyId':       await storage.read('signedPreKeyId'),
                      'registrationId':       await storage.read('registrationId'),
                    };
                  }(),
                  builder: (context, senderSnapshot) {
                    if (senderSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (senderSnapshot.hasError) {
                      return Center(child: Text('Ошибка чтения ключей: ${senderSnapshot.error}'));
                    }
                    final senderKeys = senderSnapshot.data ?? {};

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('=== Бандл ключей получателя (${widget.username}) ===', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('UserID:           ${widget.userId}'),
                            Text('IdentityKey:      ${short(bundle.identityKey)}'),
                            Text('SignedPreKey:     ${short(bundle.signedPreKey)}'),
                            Text('SignedPreKeyId:   ${bundle.signedPreKeyId}'),
                            Text('SignedPreKeySig:  ${short(bundle.signedPreKeySig)}'),
                            Text('RegistrationId:   ${bundle.registrationId}'),
                            SizedBox(height: 16),
                            Text('=== Ключи отправителя (вы) ===', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('identityPrivate:      ${short(senderKeys['identityPrivate'])}'),
                            Text('identityPublic:       ${short(senderKeys['identityPublic'])}'),
                            Text('xIdentityPrivate:      ${short(senderKeys['xIdentityPrivate'])}'),
                            Text('xIdentityPublic:       ${short(senderKeys['xIdentityPublic'])}'),
                            Text('signedPrePrivate:     ${short(senderKeys['signedPrePrivate'])}'),
                            Text('signedPrePublic:      ${short(senderKeys['signedPrePublic'])}'),
                            Text('signedPreSignature:   ${short(senderKeys['signedPreSignature'])}'),
                            Text('signedPreKeyId:       ${senderKeys['signedPreKeyId']}'),
                            Text('registrationId:       ${senderKeys['registrationId']}'),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Сообщение",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final message = messageController.text.trim();
                    if (message.isEmpty) return;
                    messageController.clear();

                    final mess = await sendFirstMessage(message, widget.userId, bundle);
                    print('mess: $mess');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Сообщение отправлено через WebSocket')),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
