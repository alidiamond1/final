import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_and_login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'home_screen.dart';
import 'upload_dataset_screen.dart';

void main() {
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

class MyApp extends StatelessWidget {
  static const primaryBlue = Color(0xFF144BA6);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somali Dataset Repository',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
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

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileAndLoginPage(
      onTabChange: (_) {},
      isAuthScreen: true,
    );
  }
}
