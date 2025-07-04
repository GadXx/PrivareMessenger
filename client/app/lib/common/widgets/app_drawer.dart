// lib/common/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:app/storage/secure_storage.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void logout(BuildContext context) async {
    final storage = SecureStorageKeys();
    await storage.delete('id');
    await storage.delete('login');
    await storage.delete('username');
    await storage.delete('identityPrivate');
    await storage.delete('identityPublic');
    await storage.delete('signedPrePrivate');
    await storage.delete('signedPrePublic');
    await storage.delete('signedPreSignature');
    await storage.delete('signedPreKeyId');
    await storage.delete('registrationId');

    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Text('Меню', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Профиль'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Поиск'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/search');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Чаты'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/main');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () => logout(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
