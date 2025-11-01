import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    return _instance;
  }
  AuthService._internal();

  User? currentUser;

  static const String _kLastUserIdKey = 'lastLoggedInUserId';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // [HAPUS] Fungsi loadUserFromDb
  // Future<void> loadUserFromDb(int userId) async { ... }

  Future<String> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final emailExists = await DatabaseHelper.instance.checkEmailExists(email);
      if (emailExists) {
        return 'Email sudah terdaftar. Silakan login.';
      }

      final hashedPassword = _hashPassword(password);
      final newUser = User(
        firstName: firstName,
        lastName: lastName,
        email: email,
        passwordHash: hashedPassword,
      );

      await DatabaseHelper.instance.registerUser(newUser);
      return 'Registrasi berhasil!';
    } catch (e) {
      print('Error saat registrasi: $e');
      return 'Registrasi gagal: Terjadi kesalahan.';
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      final user = await DatabaseHelper.instance.loginUser(
        email,
        hashedPassword,
      );

      if (user != null) {
        currentUser = user;
        // Persist last logged-in user id
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_kLastUserIdKey, user.id!);
        } catch (e) {
          // non-fatal
          print('Warning: failed to persist last user id: $e');
        }
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print('Error saat login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastUserIdKey);
    } catch (e) {
      print('Warning: failed to clear saved user id: $e');
    }
  }

  /// Loads the saved user (if any) from SharedPreferences and sets [currentUser].
  /// Returns true if a user was loaded.
  Future<bool> loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_kLastUserIdKey);
      if (id != null) {
        final user = await DatabaseHelper.instance.getUserById(id);
        if (user != null) {
          currentUser = user;
          print('Loaded saved user id=$id');
          return true;
        }
      }
    } catch (e) {
      print('Failed to load saved user: $e');
    }
    return false;
  }
}
