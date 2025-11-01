import 'package:intl/intl.dart';

class TimeConverterService {
  
  // Fungsi LAMA (Lengkap) - untuk Halaman Detail
  // Menampilkan: 31 Okt 2025, 04:14 WIB • 31 Okt 2025, 05:14 WITA • ... GMT
  String formatReviewTime(String utcTimestamp) {
    try {
      final DateTime utcTime = DateTime.parse(utcTimestamp);
      final DateTime wibTime = utcTime.add(const Duration(hours: 7));
      final DateTime witaTime = utcTime.add(const Duration(hours: 8));
      final DateTime witTime = utcTime.add(const Duration(hours: 9));
      final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');

      return '${formatter.format(wibTime)} WIB  •  '
          '${formatter.format(witaTime)} WITA  •  '
          '${formatter.format(witTime)} WIT  •  '
          '${formatter.format(utcTime)} GMT'; // GMT (London)
    } catch (e) {
      print('Error parsing time ($utcTimestamp): $e');
      return 'Invalid time format';
    }
  }

  // [FUNGSI BARU] - untuk Halaman Beranda (ReviewCard)
  // Hanya menampilkan: 31 Okt 2025, 04:14 WIB
  String formatReviewTimeSimple(String utcTimestamp) {
     try {
      final DateTime utcTime = DateTime.parse(utcTimestamp);
      // Hanya butuh WIB
      final DateTime wibTime = utcTime.add(const Duration(hours: 7));
      // Format yang sedikit lebih singkat
      final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm'); 

      return '${formatter.format(wibTime)} WIB';
    } catch (e) {
      print('Error parsing simple time ($utcTimestamp): $e');
      return 'Invalid time';
    }
  }
}

