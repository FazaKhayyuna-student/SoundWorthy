import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Impor semua model yang kita butuhkan
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/track_model.dart';

class DatabaseHelper {
  static const String _databaseName = "soundworthy.db";
  static const int _databaseVersion = 1;

  static const String _userTable = "users";
  static const String _reviewTable = "reviews";
  static const String _bookmarkTable = "bookmarks";
  // [HAPUS] Nama tabel notifikasi

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);
      print("Database path: $path");
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      print("===== DATABASE INIT FAILED =====");
      print(e);
      throw Exception('Could not initialize database: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    print("Membuat tabel database baru...");
    // 1. Tabel User
    await db.execute('''
      CREATE TABLE $_userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL
      )
    ''');
    print("Tabel $_userTable dibuat.");

    // 2. Tabel Review
    await db.execute('''
      CREATE TABLE $_reviewTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        spotify_track_id TEXT NOT NULL,
        track_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        album_art_url TEXT,
        rating INTEGER NOT NULL,
        review_text TEXT,
        created_at_utc TEXT NOT NULL,
        latitude REAL NULL, 
        longitude REAL NULL,
        location_name TEXT NULL, 
        FOREIGN KEY (user_id) REFERENCES $_userTable (id) ON DELETE CASCADE
      )
    ''');
    print("Tabel $_reviewTable dibuat.");

    // 3. Tabel Bookmark
    await db.execute('''
      CREATE TABLE $_bookmarkTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        spotify_track_id TEXT NOT NULL,
        track_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        album_art_url TEXT,
        created_at_utc TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_userTable (id) ON DELETE CASCADE
      )
    ''');
    print("Tabel $_bookmarkTable dibuat.");

    // [HAPUS] Perintah CREATE TABLE untuk notifikasi

    print("Semua tabel berhasil dibuat.");
  }
  // --- FUNGSI UNTUK USER (AUTH) ---

  // Dipanggil oleh AuthService.register
  Future<int> registerUser(User user) async {
    final db = await database;
    print("DB: Mendaftarkan user ${user.email}");
    return await db.insert(_userTable, user.toMap());
  }

  // Dipanggil oleh AuthService.register (untuk cek)
  Future<bool> checkEmailExists(String email) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Dipanggil oleh AuthService.login
  Future<User?> loginUser(String email, String passwordHash) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _userTable,
      where: 'email = ? AND passwordHash = ?',
      whereArgs: [email, passwordHash],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Dipanggil oleh ReviewCard untuk mendapatkan nama penulis
  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // --- FUNGSI UNTUK REVIEW ---

  // Dipanggil oleh AddReviewScreen
  Future<int> insertReview(ReviewModel review) async {
    final db = await database;
    print("DB: Menyimpan review baru untuk ${review.trackName}");
    return await db.insert(_reviewTable, review.toMap());
  }

  // Dipanggil oleh AddReviewScreen (mode edit)
  Future<int> updateReview(ReviewModel review) async {
    final db = await database;
    print("DB: Mengupdate review ID ${review.id}");
    return await db.update(
      _reviewTable,
      review.toMap(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  // Dipanggil oleh ReviewDetailScreen
  Future<int> deleteReview(int reviewId) async {
    final db = await database;
    print("DB: Menghapus review ID $reviewId");
    return await db.delete(
      _reviewTable,
      where: 'id = ?',
      whereArgs: [reviewId],
    );
  }

  // Dipanggil oleh HomeTab (Linimasa Publik)
  Future<List<ReviewModel>> getAllReviews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _reviewTable,
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return ReviewModel.fromMap(maps[i]);
    });
  }

  // Dipanggil oleh MyReviewsTab
  Future<List<ReviewModel>> getReviewsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _reviewTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return ReviewModel.fromMap(maps[i]);
    });
  }

  // --- FUNGSI UNTUK FAVORIT (BOOKMARK) ---

  // Dipanggil oleh ReviewDetailScreen
  Future<void> addFavorite(int userId, TrackModel track) async {
    final db = await database;
    await db.insert(_bookmarkTable, {
      'user_id': userId,
      'spotify_track_id': track.id,
      'track_name': track.name,
      'artist_name': track.artistName,
      'album_art_url': track.albumImageUrl,
      'created_at_utc': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Dipanggil oleh ReviewDetailScreen
  Future<void> removeFavorite(int userId, String trackId) async {
    final db = await database;
    await db.delete(
      _bookmarkTable,
      where: 'user_id = ? AND spotify_track_id = ?',
      whereArgs: [userId, trackId],
    );
  }

  // Dipanggil oleh ReviewDetailScreen
  Future<bool> isFavorite(int userId, String trackId) async {
    final db = await database;
    final result = await db.query(
      _bookmarkTable,
      where: 'user_id = ? AND spotify_track_id = ?',
      whereArgs: [userId, trackId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Dipanggil oleh FavoritesTab
  Future<List<TrackModel>> getFavoritesByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _bookmarkTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return TrackModel(
        id: maps[i]['spotify_track_id'],
        name: maps[i]['track_name'],
        artistName: maps[i]['artist_name'],
        albumImageUrl:
            maps[i]['album_art_url'] ??
            'https://placehold.co/100x100/1E1E2E/FFFFFF?text=No+Art',
      );
    });
  }
}
