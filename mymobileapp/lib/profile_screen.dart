import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'providers/dataset_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final datasetProvider = Provider.of<DatasetProvider>(context);
    final user = authProvider.user;
    final downloadCount = datasetProvider.downloadStatus.values
        .where((status) => status.status == DownloadState.completed)
        .length;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          _buildHeader(context, authProvider, user),
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.28),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoCards(context, user, downloadCount),
                const SizedBox(height: 20),
                _buildMenu(context, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider, Map<String, dynamic>? user) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final imageUrl = user?['profileImage'] != null
        ? '${AuthService.serverBaseUrl}/${user!['profileImage'].replaceAll('\\', '/')}?v=${authProvider.profileImageKey.hashCode}'
        : null;

    return Container(
      height: screenHeight * 0.3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  key: authProvider.profileImageKey, // Force rebuild when image changes
                  radius: screenWidth * 0.11,
                  backgroundColor: Colors.white,
                  backgroundImage: (imageUrl != null
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/profile.jpg')) as ImageProvider,
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  user?['name'] ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?['email'] ?? 'email@example.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, Map<String, dynamic>? user, int downloadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(context, Icons.person_pin_outlined, 'Role', user?['role']?.toUpperCase() ?? 'N/A'),
          _infoItem(context, Icons.dataset_outlined, 'Downloads', downloadCount.toString()),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6A1B9A), size: screenWidth * 0.07),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.03)),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _menuItem(
            context,
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
          const Divider(),
          _menuItem(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),
          _menuItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Logout',
            color: Colors.red,
            onTap: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04, color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
    );
  }
}


