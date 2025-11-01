import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // Menggunakan package yang benar
// Database lookup for notification settings was removed/refactored.
// If you re-add DB-based scheduling later, import the helper and model again.

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // [BARU] ID unik untuk notifikasi 'Terima Kasih'
  static const int _thanksNotificationId = 999;

  Future<void> init() async {
    tz.initializeTimeZones();

    String locationName;
    try {
      // flutter_timezone returns a TimezoneInfo object; convert to String
      final locationInfo = await FlutterTimezone.getLocalTimezone();
      locationName = locationInfo.toString();
    } catch (e) {
      print(
        "Gagal mendapatkan timezone device: $e, using default 'Asia/Jakarta'",
      );
      locationName = 'Asia/Jakarta';
    }

    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      print("Error setLocalLocation, fallback ke 'Asia/Jakarta': $e");
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _requestAndroidPermission();
  }

  void _requestAndroidPermission() async {
    final plugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (plugin != null) {
      await plugin.requestExactAlarmsPermission();
      await plugin.requestNotificationsPermission();
    }
  }

  // Fungsi notifikasi instan
  Future<void> showNotification(String title, String body, {int id = 0}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'review_channel_id',
          'Review Notifications',
          channelDescription: 'Notifikasi saat ulasan berhasil dikirim',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  // Fungsi membatalkan semua jadwal
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print("Semua notifikasi terjadwal dibatalkan.");
  }

  // [BARU] Fungsi untuk membatalkan HANYA notifikasi 'Terima Kasih'
  Future<void> cancelThanksNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_thanksNotificationId);
    print("DEBUG: Notifikasi 'Terima Kasih' dibatalkan.");
  }

  // [BARU] Fungsi untuk menjadwalkan notifikasi 'Terima Kasih'
  Future<void> scheduleThanksNotification({int seconds = 1}) async {
    // Pastikan jadwal lama (jika ada) dibatalkan dulu
    await cancelThanksNotification();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'thanks_channel_id',
          'Terima Kasih',
          channelDescription: 'Notifikasi yang muncul saat aplikasi ditutup.',
          importance: Importance.low, // Set rendah agar tidak mengganggu
          priority: Priority.low,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _thanksNotificationId, // Gunakan ID unik
      'Sampai Jumpa Lagi!',
      'Terima kasih telah menggunakan SoundWorthy hari ini. 🎵',
      // Jadwalkan untuk X detik dari sekarang
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
    print("DEBUG: Notifikasi 'Terima Kasih' dijadwalkan untuk $seconds detik.");
  }

  // Helper untuk scheduling (Tidak berubah)
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails notificationDetails,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print("Notifikasi terjadwal (ID: $id) untuk $hour:$minute setiap hari.");
  }

  // Fungsi penjadwalan kustom (Tidak berubah)
  Future<void> scheduleCustomNotification(int hour, int minute) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'custom_reminder_channel',
        'Pengingat Ulasan Kustom',
        channelDescription: 'Pengingat kustom untuk menulis ulasan.',
        importance: Importance.low,
        priority: Priority.low,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _scheduleNotification(
      id: 1, // ID kustom
      title: 'SoundWorthy Menunggumu!',
      body: 'Kamu dengar lagu apa hari ini? Ayo tulis ulasanmu!',
      hour: hour,
      minute: minute,
      notificationDetails: notificationDetails,
    );
  }

  // Fungsi yang dipanggil di main.dart (Tidak berubah)
  Future<void> scheduleNotificationsFromDb(int userId) async {
    print("Mencoba menjadwalkan notifikasi dari DB untuk user $userId...");
    await cancelAllNotifications();

    // Saat ini kita tidak mengambil pengaturan dari DB di sini.
    // Jika ingin mengaktifkan pengambilan dari DB nanti, panggil DatabaseHelper
    // dan gunakan scheduleCustomNotification(...) saat pengaturan ada.

    // Tidak ada pengaturan kustom: jadwalkan default (09:00 & 21:00).
    {
      print(
        "Tidak ada pengaturan kustom. Menjadwalkan default (09:00 & 21:00).",
      );
      print(
        "Tidak ada pengaturan kustom. Menjadwalkan default (09:00 & 21:00).",
      );
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Pengingat Ulasan Harian',
          channelDescription: 'Pengingat untuk menulis ulasan.',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      // Jadwal Pagi 9:00
      await _scheduleNotification(
        id: 10,
        title: 'Selamat Pagi!',
        body: 'Saatnya menulis ulasan. Lagu apa yang Anda dengar hari ini?',
        hour: 9,
        minute: 0,
        notificationDetails: notificationDetails,
      );
      // Jadwal Malam 21:00
      await _scheduleNotification(
        id: 11,
        title: 'Waktu Bersantai!',
        body: 'Jangan lupa berikan rating pada lagu yang Anda dengarkan.',
        hour: 21,
        minute: 0,
        notificationDetails: notificationDetails,
      );
    }
  }
}
