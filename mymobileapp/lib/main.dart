import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => DatasetProvider()),
      ],
      child: MaterialApp(
        title: 'Dataset App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
          // Use Noto Sans which has good support for Somali characters
          fontFamily: GoogleFonts.notoSans().fontFamily,
          textTheme: TextTheme(
            // Ensure all text uses the right font family
            bodyMedium: TextStyle(
              fontFamily: GoogleFonts.notoSans().fontFamily,
              fontSize: 14,
            ),
            bodyLarge: TextStyle(
              fontFamily: GoogleFonts.notoSans().fontFamily,
              fontSize: 16,
            ),
            titleMedium: TextStyle(
              fontFamily: GoogleFonts.notoSans().fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: TextStyle(
              fontFamily: GoogleFonts.notoSans().fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            labelLarge: TextStyle(
              fontFamily: GoogleFonts.notoSans().fontFamily,
              fontSize: 14,
            ),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return authProvider.isAuthenticated ? const HomeScreen() : const AuthScreen();
          },
        ),
      ),
    );
  }
}


