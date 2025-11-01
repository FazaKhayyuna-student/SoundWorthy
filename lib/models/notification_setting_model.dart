class NotificationSettingModel {
  final int? id; // ID bisa null saat membuat objek baru
  final int userId;
  final int hour; // Jam (0-23)
  final int minute; // Menit (0-59)
  
  NotificationSettingModel({
    this.id,
    required this.userId,
    required this.hour,
    required this.minute,
  });

  // Untuk menyimpan ke DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'hour': hour,
      'minute': minute,
    };
  }

  // Untuk mengambil dari DB
  factory NotificationSettingModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingModel(
      id: map['id'],
      userId: map['user_id'],
      hour: map['hour'],
      minute: map['minute'],
    );
  }
}
