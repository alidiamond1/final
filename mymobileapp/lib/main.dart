import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'home_screen.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:ui';
import 'dart:isolate';
import 'welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_downloader
  await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: true);

  // Register the standalone callback
  FlutterDownloader.registerCallback(downloadCallback);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DatasetProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Standalone download callback
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class MyApp extends StatelessWidget {
  static const primaryBlue = Color(0xFF144BA6);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somali Dataset Repository',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: MyApp.primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: MyApp.primaryBlue),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      // Always start with welcome screen
      home: const WelcomeScreen(),
    );
  }
}


