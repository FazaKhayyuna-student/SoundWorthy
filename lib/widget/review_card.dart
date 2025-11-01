import 'package:flutter/material.dart';
import 'package:reviewmusik/services/time_converter_screen.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../screens/review/review_detail_screen.dart';
import '../services/auth_service.dart'; // [BARU]

class ReviewCard extends StatefulWidget {
  final ReviewModel review;
  // [PERBAIKAN] Hapus currentUser dari constructor

  const ReviewCard({Key? key, required this.review}) : super(key: key);

  @override
  _ReviewCardState createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final TimeConverterService _timeService = TimeConverterService();
  User? _author;
  bool _isLoadingAuthor = true;

  // [BARU] Ambil user dari AuthService
  User? get currentUser => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _loadAuthorData();
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
      print('Error loading author data: $e');
      if (mounted) {
        setState(() {
          _isLoadingAuthor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = _timeService.formatReviewTimeSimple(
      widget.review.createdAtUtc,
    );
    final String authorName = _isLoadingAuthor
        ? 'Memuat...'
        : (_author?.firstName ?? 'Pengguna');
    final String locationText =
        widget.review.locationName != null &&
            widget.review.locationName!.isNotEmpty
        ? 'di ${widget.review.locationName}'
        : '';

    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // [PERBAIKAN] Pastikan currentUser tidak null saat kirim
          if (currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewDetailScreen(
                  review: widget.review,
                  currentUser: currentUser!, // Kirim user dari getter
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.review.albumArtUrl ??
                          'https://placehold.co/100x100/1E1E2E/FFFFFF?text=No+Art',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.review.trackName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.review.artistName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Teks Ulasan
              if (widget.review.reviewText != null &&
                  widget.review.reviewText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    widget.review.reviewText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Divider
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 6),
              // Baris Bawah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: Text(
                      'Oleh: $authorName $locationText',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
