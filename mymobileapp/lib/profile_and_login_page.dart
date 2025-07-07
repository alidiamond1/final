import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';

class ProfileAndLoginPage extends StatelessWidget {
  const ProfileAndLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return authProvider.isAuthenticated ? const ProfileScreen() : const AuthScreen();
  }
}