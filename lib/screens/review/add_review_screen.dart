import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/track_model.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/database_helper.dart';
import '../../services/notification_service.dart';

class AddReviewScreen extends StatefulWidget {
  final TrackModel track;
  final User user;
  final ReviewModel? reviewToEdit;

  const AddReviewScreen({
    Key? key,
    required this.track,
    required this.user,
    this.reviewToEdit,
  }) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  double _rating = 0;
  bool _isLoading = false;
  String _locationStatus = '';
  bool _isGettingLocation = false;

  bool get _isEditing => widget.reviewToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _reviewController.text = widget.reviewToEdit!.reviewText ?? '';
      _rating = widget.reviewToEdit!.rating.toDouble();
      if (widget.reviewToEdit!.locationName != null &&
          widget.reviewToEdit!.locationName!.isNotEmpty) {
        _locationStatus = 'Lokasi: ${widget.reviewToEdit!.locationName}';
      }
    }
  }

  Future<Map<String, dynamic>?> _getCurrentLocationAndPlacemark() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (mounted) {
      setState(() {
        _isGettingLocation = true;
        _locationStatus = 'Mendeteksi lokasi...';
      });
    }

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = 'Layanan lokasi mati.';
        _isGettingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktifkan layanan lokasi di perangkat.')),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = 'Izin lokasi ditolak.';
          _isGettingLocation = false;
        });
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus = 'Izin lokasi ditolak permanen.';
        _isGettingLocation = false;
      });
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Lokasi tidak diketahui';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        locationName =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Lokasi tidak diketahui';
      }

      setState(() {
        _locationStatus = 'Lokasi: $locationName';
        _isGettingLocation = false;
      });

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': locationName,
      };
    } catch (e) {
      setState(() {
        _locationStatus = 'Gagal mendapatkan lokasi.';
        _isGettingLocation = false;
      });
      return null;
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan tidak boleh kosong')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beri rating dulu, ya!')));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic>? locationData;
    if (!_isEditing ||
        widget.reviewToEdit?.locationName == null ||
        widget.reviewToEdit!.locationName!.isEmpty) {
      locationData = await _getCurrentLocationAndPlacemark();
    } else {
      locationData = {
        'latitude': widget.reviewToEdit!.latitude,
        'longitude': widget.reviewToEdit!.longitude,
        'locationName': widget.reviewToEdit!.locationName,
      };
    }

    try {
      final reviewData = ReviewModel(
        id: _isEditing ? widget.reviewToEdit!.id : null,
        userId: widget.user.id!,
        spotifyTrackId: widget.track.id,
        trackName: widget.track.name,
        artistName: widget.track.artistName,
        albumArtUrl: widget.track.albumImageUrl,
        rating: _rating.toInt(),
        reviewText: _reviewController.text.trim(),
        createdAtUtc: _isEditing
            ? widget.reviewToEdit!.createdAtUtc
            : DateTime.now().toUtc().toIso8601String(),
        latitude: locationData?['latitude'],
        longitude: locationData?['longitude'],
        locationName: locationData?['locationName'],
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateReview(reviewData);
      } else {
        await DatabaseHelper.instance.insertReview(reviewData);
      }

      await _notificationService.showNotification(
        _isEditing ? 'Ulasan Diperbarui!' : 'Ulasan Terkirim!',
        'Ulasan Anda untuk ${widget.track.name} telah disimpan.',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan ulasan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Ulasan' : 'Tulis Ulasan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Image.network(
                widget.track.albumImageUrl,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              widget.track.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.track.artistName,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Rating pakai Bintang
            const Text(
              'Beri Rating:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isFilled = index < _rating;
                return IconButton(
                  icon: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: isFilled ? Colors.amber : Colors.white30,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),
            const SizedBox(height: 20),

            // Input Ulasan
            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            // Lokasi
            if (_locationStatus.isNotEmpty || _isGettingLocation)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationStatus,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isGettingLocation)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 30),

            // Tombol Kirim
            _isLoading || _isGettingLocation
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A00FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Ulasan' : 'Kirim Ulasan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'Tulis ulasan Anda di sini...',
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
