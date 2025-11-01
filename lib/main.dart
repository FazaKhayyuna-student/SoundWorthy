import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  // Pastikan semua plugin Flutter terinisialisasi (WAJIB untuk sqflite dan notifikasi)
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi service notifikasi (versi sederhana)
  final notificationService = NotificationService();
  await notificationService.init();

  // Try to restore saved user session (if any)
  await AuthService().loadSavedUser();

  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tema gelap (didefinisikan sekali di sini)
    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      primaryColor: const Color(0xFF7A00FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7A00FF),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF1E1E2E),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E2E),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white.withOpacity(0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIconColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7A00FF), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2E),
        selectedItemColor: Color(0xFF7A00FF),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );

    return MaterialApp(
      title: 'SoundWorthy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      // Halaman utama selalu LoginScreen
      home: LoginScreen(),
    );
  }
}
