// ... (Bagian atas file _clientId, _clientSecret, _getAccessToken, searchTrack TIDAK BERUBAH) ...
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class SpotifyApiService {
  final String _clientId = "9ed5e3a9e86e4bd7b57a9e6fa3760bc0";
  final String _clientSecret = "0fb8d36420a94b89b81c7f9d9188e930";
  String? _accessToken;
  DateTime _tokenExpiryTime = DateTime.now();

  Future<bool> _getAccessToken() async {
    // ... (KODE TIDAK BERUBAH) ...
    if (_accessToken != null && DateTime.now().isBefore(_tokenExpiryTime)) {
      return true;
    }
    try {
      var response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiryTime = DateTime.now().add(
          Duration(seconds: data['expires_in'] - 300),
        );
        print("Spotify Token Berhasil Didapatkan!");
        return true;
      } else {
        print('Gagal mendapatkan token Spotify: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error _getAccessToken: $e');
      return false;
    }
  }

  Future<List<TrackModel>> searchTrack(String query) async {
    // ... (KODE TIDAK BERUBAH) ...
    bool hasToken = await _getAccessToken();
    if (!hasToken || _accessToken == null) {
      throw Exception('Gagal otentikasi dengan Spotify');
    }
    try {
      var response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=10',
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['tracks']['items'];
        return items.map((item) => TrackModel.fromJson(item)).toList();
      } else {
        print('Gagal mencari lagu: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searchTrack: $e');
      return [];
    }
  }

  // [PERUBAHAN DI SINI] Ganti nama fungsi dan endpoint
  // Kita ganti dari /recommendations ke /browse/new-releases
  Future<List<TrackModel>> getNewReleases() async {
    // 1. Pastikan kita punya token
    bool hasToken = await _getAccessToken();
    if (!hasToken || _accessToken == null) {
      throw Exception('Gagal otentikasi dengan Spotify');
    }

    // 2. Buat request Rilisan Baru (endpoint ini lebih sederhana)
    try {
      var response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/browse/new-releases?limit=10', // Endpoint baru
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Endpoint ini mengembalikan data di dalam 'albums' -> 'items'
        final List items = data['albums']['items'];
        print("Rilisan Baru berhasil didapat: ${items.length} album");

        // Ubah setiap item JSON (Album Object) menjadi TrackModel
        // Kita akan ambil lagu pertama dari setiap album (ini sedikit 'hack')
        return items.map((item) {
          // Karena ini adalah Album Object, kita perlu sedikit adaptasi
          // Kita akan gunakan data album untuk membuat TrackModel
          String imageUrl = (item['images'] as List).isNotEmpty
              ? item['images'][0]['url']
              : 'https://placehold.co/100x100/1E1E2E/FFFFFF?text=No+Art';
          String artistName = (item['artists'] as List).isNotEmpty
              ? item['artists'][0]['name']
              : 'Unknown Artist';

          return TrackModel(
            id: item['id'], // Kita pakai ID album
            name: item['name'], // Nama album
            artistName: artistName,
            albumImageUrl: imageUrl,
          );
        }).toList();
      } else {
        // [GANTI PRINT ERROR]
        print('Gagal mendapatkan Rilisan Baru: ${response.body}');
        return [];
      }
    } catch (e) {
      // [GANTI PRINT ERROR]
      print('Error getNewReleases: $e');
      return [];
    }
  }
}
