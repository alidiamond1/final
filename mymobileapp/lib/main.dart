import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'home_screen.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:ui';
import 'dart:isolate';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_downloader
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  // Register the callback
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

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class MyApp extends StatefulWidget {
  static const primaryBlue = Color(0xFF144BA6);

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      final String taskId = data[0];
      final int statusValue = data[1];
      final int progress = data[2];

      final status = DownloadTaskStatus.fromInt(statusValue);

      // Use a post-frame callback to safely access the provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);

        // Find the datasetId associated with this taskId
        String? datasetId;
        String? filePath;
        datasetProvider.downloadStatus.forEach((key, value) {
          if (value.taskId == taskId) {
            datasetId = key;
            filePath = value.filePath;
          }
        });

        // Promote to local variable to solve null-safety analysis issue inside the closure
        final finalDatasetId = datasetId;
        if (finalDatasetId != null) {
          if (status == DownloadTaskStatus.complete) {
            datasetProvider.updateDownloadStatus(finalDatasetId, DownloadState.completed, 1.0, filePath: filePath);
          } else if (status == DownloadTaskStatus.running) {
            datasetProvider.updateDownloadStatus(finalDatasetId, DownloadState.inProgress, progress / 100.0);
          } else if (status == DownloadTaskStatus.failed || status == DownloadTaskStatus.canceled || status == DownloadTaskStatus.undefined) {
            datasetProvider.updateDownloadStatus(finalDatasetId, DownloadState.error, 0.0, error: 'Download failed');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

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
        home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Check if loading
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Redirect based on auth status
          return authProvider.isAuthenticated
              ? const HomeScreen()
              : const AuthScreen();
        },
      ),
//       routes: {
//         '/': (context) => const AuthWrapper(),
//         '/upload-dataset': (context) => const UploadDatasetScreen(),
//       },
//       initialRoute: '/',
//     );
//   }
// }

// // Wrapper to handle authentication state
// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         // Check if loading
//         if (authProvider.isLoading) {
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
        
//         // Redirect based on auth status
//         return authProvider.isAuthenticated
//             ? const HomeScreen()
//             : const AuthScreen();
//       },
    );
  }
}


