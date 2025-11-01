import 'dart:async';
// import 'dart:math'; // not used
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/spotify_api_service.dart';
import '../../models/track_model.dart';
import '../review/add_review_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../auth/login_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool showBackButton; // [BARU] Bisa diatur true/false
  const SearchScreen({Key? key, this.showBackButton = false}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SpotifyApiService _spotifyService = SpotifyApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  User? get currentUser => AuthService().currentUser;

  List<TrackModel> _searchResults = [];
  bool _isLoading = false;
  String _message = 'Cari lagu atau artis untuk diulas...';
  Timer? _debounce;
  // Cache of favorite track IDs for the current user to show heart icon quickly
  final Set<String> _favoriteIds = {};

  // 🔍 Debounced search biar gak spam API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _message = 'Cari lagu atau artis untuk diulas...';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final results = await _spotifyService.searchTrack(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          if (results.isEmpty) {
            _message = 'Tidak ada hasil untuk "$query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Gagal terhubung ke Spotify. Cek koneksi Anda.';
        });
      }
      print('Error saat mencari lagu: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load user's favorites once so we can show heart icons in search results
    _loadUserFavorites();
  }

  Future<void> _loadUserFavorites() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final favs = await DatabaseHelper.instance.getFavoritesByUserId(user.id!);
      setState(() {
        _favoriteIds.clear();
        _favoriteIds.addAll(favs.map((t) => t.id));
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load favorites for search: $e');
    }
  }

  Future<void> _toggleFavoriteForTrack(TrackModel track) async {
    final user = currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk menggunakan favorit.'),
        ),
      );
      return;
    }

    final isFav = _favoriteIds.contains(track.id);
    setState(() {
      // optimistic update
      if (isFav)
        _favoriteIds.remove(track.id);
      else
        _favoriteIds.add(track.id);
    });

    try {
      if (isFav) {
        await DatabaseHelper.instance.removeFavorite(user.id!, track.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${track.name}" dihapus dari favorit')),
        );
      } else {
        await DatabaseHelper.instance.addFavorite(user.id!, track);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${track.name}" ditambahkan ke favorit')),
        );
      }
    } catch (e) {
      // Revert optimistic change on error
      setState(() {
        if (isFav)
          _favoriteIds.add(track.id);
        else
          _favoriteIds.remove(track.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui favorit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(backgroundColor: const Color(0xFF1E1E2E), elevation: 0),
        body: _buildSessionExpired(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Text(
          'Cari Lagu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(Icons.search),
              textInputAction: TextInputAction.search,
              autofocus: true,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSessionExpired() {
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
            child: const Text('Ke Halaman Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_message.isNotEmpty) {
      return Center(
        child: Text(
          _message,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final isFav = _favoriteIds.contains(track.id);
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              track.albumImageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.music_note, color: Colors.white54),
            ),
          ),
          title: Text(
            track.name,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artistName,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.white70,
                ),
                onPressed: () => _toggleFavoriteForTrack(track),
                tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
          onTap: () {
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddReviewScreen(track: track, user: currentUser!),
                ),
              );
            }
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      hintText: 'Cari di Spotify...',
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      prefixIcon: Icon(icon, color: Colors.white70, size: 22),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                  _message = 'Cari lagu atau artis untuk diulas...';
                });
                _focusNode.requestFocus();
              },
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7A00FF), width: 1.5),
      ),
    );
  }
}
