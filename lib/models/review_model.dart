class ReviewModel {
  final int? id; // ID bisa null saat membuat objek baru sebelum disimpan
  final int userId;
  final String spotifyTrackId;
  final String trackName;
  final String artistName;
  final String? albumArtUrl; // Bisa null
  final int rating; // Rating 1-5
  final String? reviewText; // Bisa null
  final String createdAtUtc; // Wajib ada, format ISO 8601 UTC

  // [BARU] Field untuk LBS (semua nullable)
  final double? latitude;
  final double? longitude;
  final String? locationName; // Nama kota/tempat

  ReviewModel({
    this.id,
    required this.userId,
    required this.spotifyTrackId,
    required this.trackName,
    required this.artistName,
    this.albumArtUrl,
    required this.rating,
    this.reviewText,
    required this.createdAtUtc,
    // [BARU] Tambahkan di constructor
    this.latitude,
    this.longitude,
    this.locationName,
  });

  // Fungsi untuk mengubah objek ReviewModel menjadi Map (untuk disimpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'spotify_track_id': spotifyTrackId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_art_url': albumArtUrl,
      'rating': rating,
      'review_text': reviewText,
      'created_at_utc': createdAtUtc,
      // [BARU] Tambahkan ke map
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  // Factory constructor untuk membuat objek ReviewModel dari Map (dari DB)
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      userId: map['user_id'],
      spotifyTrackId: map['spotify_track_id'],
      trackName: map['track_name'],
      artistName: map['artist_name'],
      albumArtUrl: map['album_art_url'],
      rating: map['rating'],
      reviewText: map['review_text'],
      createdAtUtc: map['created_at_utc'],
      // [BARU] Ambil dari map (jika ada)
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
    );
  }
}

