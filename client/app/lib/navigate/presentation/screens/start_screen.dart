import 'package:flutter/material.dart';
import 'package:app/auth/domain/auth_repository.dart';
import 'package:app/storage/secure_storage.dart';

class StartScreen extends StatelessWidget {
  final AuthRepository repo;
  final SecureStorageKeys _storageService = SecureStorageKeys();
  StartScreen({Key? key, required this.repo}) : super(key: key);

  Future<bool> isAuthorized() async {
    final id = await _storageService.read('id');
    return id != null && id.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAuthorized(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.data == true) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else {
            Navigator.pushReplacementNamed(context, '/register');
          }
        });

        return Scaffold();
      },
    );
  }
}
