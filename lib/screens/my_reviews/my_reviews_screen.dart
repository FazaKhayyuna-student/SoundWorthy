import 'package:flutter/material.dart';
import 'package:reviewmusik/screens/screens/review/review_card.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/database_helper.dart';
import '../search/search_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class MyReviewsTab extends StatefulWidget {
  const MyReviewsTab({Key? key}) : super(key: key);

  @override
  State<MyReviewsTab> createState() => _MyReviewsTabState();
}

class _MyReviewsTabState extends State<MyReviewsTab> {
  late Future<List<ReviewModel>> _myReviewsFuture;
  User? get currentUser => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      // Start loading immediately and set the future so FutureBuilder has a value
      _myReviewsFuture = DatabaseHelper.instance.getReviewsByUserId(
        currentUser!.id!,
      );
    } else {
      _myReviewsFuture = Future.value([]);
    }
  }

  Future<void> _loadMyReviews() async {
    if (currentUser?.id != null) {
      // Await the DB call so callers (like RefreshIndicator) can wait for completion
      final reviews = await DatabaseHelper.instance.getReviewsByUserId(
        currentUser!.id!,
      );
      setState(() {
        _myReviewsFuture = Future.value(reviews);
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
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ulasan Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            tooltip: 'Tulis Ulasan Baru',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ).then((_) => _loadMyReviews());
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E2E),
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
          // Ensure RefreshIndicator waits for the async load to finish
          onRefresh: _loadMyReviews,
          color: const Color(0xFF7A00FF),
          child: FutureBuilder<List<ReviewModel>>(
            future: _myReviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat ulasan Anda.\n${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Make the empty state scrollable so RefreshIndicator can trigger
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
                          'Anda belum menulis ulasan apapun.\nKlik ikon di kanan atas untuk memulai.',
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final reviews = snapshot.data!;
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
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
                    child: ReviewCard(
                      review: review,
                      currentUser: currentUser!,
                      onDeleted: _loadMyReviews,
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
