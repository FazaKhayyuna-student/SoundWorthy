import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/track_model.dart';
import '../../services/database_helper.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../review/add_review_screen.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({Key? key}) : super(key: key);

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  late Future<List<TrackModel>> _favoritesFuture;
  User? get currentUser => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      // Set initial future so FutureBuilder has a value immediately
      _favoritesFuture = DatabaseHelper.instance.getFavoritesByUserId(
        currentUser!.id!,
      );
    } else {
      _favoritesFuture = Future.value([]);
    }
  }

  Future<void> _loadFavorites() async {
    if (currentUser?.id != null) {
      final tracks = await DatabaseHelper.instance.getFavoritesByUserId(
        currentUser!.id!,
      );
      setState(() {
        _favoritesFuture = Future.value(tracks);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sesi berakhir. Silakan login kembali.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A00FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ke Halaman Login'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lagu Favorit Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.9],
            colors: [Color(0xFF2A1446), Color(0xFF1E1E2E)],
          ),
        ),
        child: RefreshIndicator(
          // Return the Future so the RefreshIndicator spinner waits for completion
          onRefresh: _loadFavorites,
          color: const Color(0xFF7A00FF),
          child: FutureBuilder<List<TrackModel>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat favorit Anda.\n${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Empty state must still be scrollable so RefreshIndicator works
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 80,
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada lagu favorit.\nTambahkan lagu ke favorit untuk mulai membangun koleksi Anda!',
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final favoriteTracks = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: favoriteTracks.length,
                itemBuilder: (context, index) {
                  final track = favoriteTracks[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.albumImageUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 55,
                                height: 55,
                                color: Colors.white.withOpacity(0.1),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                ),
                              ),
                        ),
                      ),
                      title: Text(
                        track.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artistName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Hapus dari Favorit',
                            onPressed: () async {
                              if (currentUser?.id == null) return;
                              final userId = currentUser!.id!;
                              try {
                                await DatabaseHelper.instance.removeFavorite(
                                  userId,
                                  track.id,
                                );
                                // reload list
                                await _loadFavorites();
                                // show snackbar with undo
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"${track.name}" dihapus dari favorit',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Batal',
                                      onPressed: () async {
                                        // Re-add favorite
                                        await DatabaseHelper.instance
                                            .addFavorite(userId, track);
                                        await _loadFavorites();
                                      },
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal menghapus favorit: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddReviewScreen(
                              track: track,
                              user: currentUser!,
                            ),
                          ),
                        ).then((_) => _loadFavorites());
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
