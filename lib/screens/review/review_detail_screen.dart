import 'package:flutter/material.dart';
import 'package:reviewmusik/services/time_converter_screen.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../models/track_model.dart';
import '../../services/database_helper.dart';
import '../review/add_review_screen.dart';
import '../../services/notification_service.dart';

class ReviewDetailScreen extends StatefulWidget {
  final ReviewModel review;
  final User currentUser;

  const ReviewDetailScreen({
    Key? key,
    required this.review,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final TimeConverterService _timeService = TimeConverterService();
  final NotificationService _notificationService = NotificationService();

  User? _author;
  bool _isLoadingAuthor = true;

  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  late final TrackModel _trackData;

  @override
  void initState() {
    super.initState();
    _loadAuthorData();
    _checkFavoriteStatus();
    _trackData = TrackModel(
      id: widget.review.spotifyTrackId,
      name: widget.review.trackName,
      artistName: widget.review.artistName,
      albumImageUrl:
          widget.review.albumArtUrl ??
          'https://placehold.co/100x100/1E1E2E/FFFFFF?text=No+Art',
    );
  }

  Future<void> _loadAuthorData() async {
    if (!mounted) return;
    setState(() => _isLoadingAuthor = true);
    try {
      final user = await DatabaseHelper.instance.getUserById(
        widget.review.userId,
      );
      if (mounted) {
        setState(() {
          _author = user;
          _isLoadingAuthor = false;
        });
      }
    } catch (e) {
      print('Error loading author data for detail: $e');
      if (mounted) setState(() => _isLoadingAuthor = false);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingFavorite = true);
    try {
      bool isFav = await DatabaseHelper.instance.isFavorite(
        widget.currentUser.id!,
        widget.review.spotifyTrackId,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    if (!mounted) return;

    setState(() => _isLoadingFavorite = true);

    String trackName = widget.review.trackName;

    try {
      if (_isFavorite) {
        await DatabaseHelper.instance.removeFavorite(
          widget.currentUser.id!,
          widget.review.spotifyTrackId,
        );
      } else {
        await DatabaseHelper.instance.addFavorite(
          widget.currentUser.id!,
          _trackData,
        );
      }

      bool newStatus = !_isFavorite;
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _isLoadingFavorite = false;
        });

        await _notificationService.showNotification(
          newStatus ? 'Lagu Disimpan!' : 'Lagu Dihapus!',
          '${trackName} ${newStatus ? "telah ditambahkan ke" : "dihapus dari"} Favorit Anda.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Ditambahkan ke Favorit' : 'Dihapus dari Favorit',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui favorit.')),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          contentTextStyle: const TextStyle(color: Colors.white70),
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus ulasan ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await DatabaseHelper.instance.deleteReview(widget.review.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ulasan berhasil dihapus')),
          );
          // Return `true` so callers know something changed and can refresh
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Gagal menghapus ulasan: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus ulasan.')),
          );
        }
      }
    }
  }

  void _editReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          user: widget.currentUser,
          track: _trackData,
          reviewToEdit: widget.review,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = _timeService.formatReviewTime(
      widget.review.createdAtUtc,
    );
    final String authorName = _isLoadingAuthor
        ? 'Memuat...'
        : (_author?.firstName ?? 'Pengguna');

    final bool isOwner = widget.currentUser.id == widget.review.userId;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Ulasan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isLoadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  tooltip: 'Simpan ke Favorit',
                  onPressed: _toggleFavorite,
                ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Ulasan',
              onPressed: _editReview,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Hapus Ulasan',
              onPressed: _deleteReview,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Detail Lagu ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.review.albumArtUrl ??
                        'https://placehold.co/100x100/1E1E2E/FFFFFF?text=No+Art',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.review.trackName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.review.artistName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Rating: ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < widget.review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          Text(
                            ' (${widget.review.rating}/5)',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // === Info Penulis dan Waktu ===
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oleh: $authorName'
                    '${(widget.review.locationName?.isNotEmpty ?? false) ? " di ${widget.review.locationName}" : ""}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),

            // === Teks Ulasan ===
            const Text(
              'Ulasan:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.review.reviewText ?? '(Tidak ada teks ulasan)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
