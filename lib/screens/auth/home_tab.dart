import 'package:flutter/material.dart';
import 'package:reviewmusik/screens/screens/review/review_card.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../models/track_model.dart';
import '../../services/database_helper.dart';
import '../../services/spotify_api_service.dart';
import '../search/search_screen.dart';
import '../review/add_review_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final SpotifyApiService _spotifyService = SpotifyApiService();
  late Future<List<ReviewModel>> _reviewsFuture;
  late Future<List<TrackModel>> _newReleasesFuture;

  User? get currentUser => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (currentUser == null) {
      _reviewsFuture = Future.value([]);
      _newReleasesFuture = Future.value([]);
    } else {
      _reviewsFuture = DatabaseHelper.instance.getAllReviews();
      _newReleasesFuture = _spotifyService.getNewReleases();
    }
  }

  Future<void> _onRefresh() async {
    setState(_loadData);
  }

  void _navigateToSearch() {
    if (currentUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    ).then((_) => setState(_loadData));
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return _buildSessionExpired();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Text(
          'SoundWorthy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Cari Lagu',
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7A00FF),
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _sectionTitle('Rilisan Baru Minggu Ini'),
            _newReleases(),
            _sectionTitle('Ulasan Terbaru'),
            _reviewsList(),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // --- UI SECTION TITLE ---
  Widget _sectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // --- NEW RELEASES SECTION ---
  Widget _newReleases() {
    return FutureBuilder<List<TrackModel>>(
      future: _newReleasesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7A00FF)),
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Tidak dapat memuat rilisan baru.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          );
        }

        final releases = snapshot.data!;
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: releases.length,
              itemBuilder: (context, index) =>
                  _buildRecommendationCard(releases[index]),
            ),
          ),
        );
      },
    );
  }

  // --- REVIEWS SECTION ---
  Widget _reviewsList() {
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF7A00FF)),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Gagal memuat ulasan.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Belum ada ulasan.\nJadilah yang pertama!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          );
        }

        final reviews = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) =>
                ReviewCard(review: reviews[i], currentUser: currentUser!),
            childCount: reviews.length,
          ),
        );
      },
    );
  }

  // --- RECOMMENDATION CARD ---
  Widget _buildRecommendationCard(TrackModel track) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddReviewScreen(track: track, user: currentUser!),
            ),
          ).then((_) => setState(_loadData));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.network(
                track.albumImageUrl,
                height: 110,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  width: 150,
                  color: Colors.white.withOpacity(0.08),
                  child: const Icon(Icons.music_note, color: Colors.white38),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artistName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SESSION EXPIRED SCREEN ---
  Widget _buildSessionExpired() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, color: Colors.white54, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Sesi kamu telah berakhir.\nSilakan login kembali untuk melanjutkan.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A00FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: const Text(
                  "Ke Halaman Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
