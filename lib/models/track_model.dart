class TrackModel {
  final String id;          // ID lagu dari Spotify
  final String name;        // Judul lagu
  final String artistName;  // Nama artis
  final String albumImageUrl; // URL gambar album

  TrackModel({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumImageUrl,
  });

  // Factory constructor untuk mengubah JSON dari Spotify menjadi objek TrackModel
  factory TrackModel.fromJson(Map<String, dynamic> json) {
    // Ambil nama artis (Spotify mengirimnya sebagai List)
    String artist = (json['artists'] as List).isNotEmpty
        ? json['artists'][0]['name']
        : 'Unknown Artist';

    // Ambil gambar album (Spotify mengirim List gambar berbagai ukuran)
    String imageUrl = (json['album']['images'] as List).isNotEmpty
        ? json['album']['images'][0]['url']
        : 'https://placehold.co/600x600/1E1E2E/FFFFFF?text=No+Art'; // Placeholder

    return TrackModel(
      id: json['id'],
      name: json['name'],
      artistName: artist,
      albumImageUrl: imageUrl,
    );
  }
}
