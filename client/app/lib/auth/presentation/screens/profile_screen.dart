// lib/features/auth/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:app/common/widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Твой контент профиля здесь'),
      ),
    );
  }
}
