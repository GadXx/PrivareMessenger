// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:app/auth/domain/auth_repository.dart';
import 'package:app/auth/signal_key_util.dart';
import 'package:app/auth/data/models/register_request.dart';
import 'package:app/storage/secure_storage.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepository repo;
  const RegisterScreen({required this.repo, super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final loginController = TextEditingController();
  bool loading = false;
  String? error;
  String? success;

  void register() async {
    setState(() {
      loading = true;
      error = null;
    });
    final storage = SecureStorageKeys();

    try {
      // 1. Генерация ключей
      final keys = await SimpleKeyUtil.generateAllKeys();

      // 2. Резервирование логина
      try {
        await widget.repo.reservLogin(loginController.text, keys['identityPublic']!);
      } catch (e) {
        // Логин занят или другая ошибка
        setState(() {
          error = 'Логин "${loginController.text}" занят, попробуйте другой.';
        });
        return;
      }

      // 3. Регистрация
      final req = RegisterRequest(
        username: usernameController.text,
        login: loginController.text,
        identityKey: keys['identityPublic']!,
        xIdentityKey: keys['xIdentityPublic']!,
        signedPreKeyId: keys['signedPreKeyId']!,
        signedPreKey: keys['signedPrePublic']!,
        signedPreKeySig: keys['signedPreSignature']!,
        registrationId: keys['registrationId']!,
      );
      final id = await widget.repo.register(req);

      // 4. Сохраняем всё только после регистрации
      await storage.write('id', id);
      await storage.write('login', loginController.text);
      await storage.write('username', usernameController.text);

      await storage.write('identityPublic', keys['identityPublic']!);
      await storage.write('identityPrivate', keys['identityPrivate']!);
      await storage.write('xIdentityPublic', keys['xIdentityPublic']!);
      await storage.write('xIdentityPrivate', keys['xIdentityPrivate']!);
      await storage.write('signedPrePrivate', keys['signedPrePrivate']!);
      await storage.write('signedPrePublic', keys['signedPrePublic']!);
      await storage.write('signedPreSignature', keys['signedPreSignature']!);
      await storage.write('signedPreKeyId', keys['signedPreKeyId']!);
      await storage.write('registrationId', keys['registrationId']!);      

      // 5. Переход на профиль
      Navigator.pushReplacementNamed(context, '/profile');

    } catch (e) {
      setState(() {
        error = 'Ошибка при регистрации: ${e.toString()}';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Имя пользователя'),
            ),
            TextField(
              controller: loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
            const SizedBox(height: 20),
            if (loading) CircularProgressIndicator(),
            if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
            if (success != null) Text(success!, style: TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: loading ? null : register,
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
