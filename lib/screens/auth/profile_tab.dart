import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'kesan_pesan_screen.dart';

class ProfileTab extends StatefulWidget {
  final bool showBackButton;
  const ProfileTab({super.key, this.showBackButton = false});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final NotificationService _notificationService = NotificationService();
  final NumberFormat _foreignFormatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 2,
  );

  final Map<String, double> _exchangeRates = const {
    'USD': 0.000061,
    'EUR': 0.000057,
    'JPY': 0.0095,
  };

  double _idrAmount = 0.0;
  double _usdAmount = 0.0;
  double _eurAmount = 0.0;
  double _jpvAmount = 0.0;

  final TextEditingController _donationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _handleDonationInput("0");
  }

  @override
  void dispose() {
    _donationController.dispose();
    super.dispose();
  }

  // --- Fungsi Donasi ---
  void _convertIdrToForeign(double idr) {
    setState(() {
      _usdAmount = idr * (_exchangeRates['USD'] ?? 0);
      _eurAmount = idr * (_exchangeRates['EUR'] ?? 0);
      _jpvAmount = idr * (_exchangeRates['JPY'] ?? 0);
    });
  }

  void _handleDonationInput(String text) {
    final cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');
    final double? amount = double.tryParse(cleanedText);
    if (amount != null && amount >= 0) {
      _idrAmount = amount;
      _convertIdrToForeign(amount);
    } else {
      _idrAmount = 0;
      _usdAmount = 0;
      _eurAmount = 0;
      _jpvAmount = 0;
    }
    setState(() {});
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF7A00FF),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return _buildSessionExpired();
    }

    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7A00FF),
        secondary: Color(0xFF03DAC6),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.showBackButton,
          title: const Text('Profil Saya'),
          backgroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              // 👆 padding bawah 100 biar aman dari navbar melayang
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSection(user),
                  const SizedBox(height: 28),
                  _buildDonationSection(theme),
                  const SizedBox(height: 28),
                  _buildNotificationTest(theme),
                  const SizedBox(height: 28),
                  _buildFeedbackSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(user) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white, size: 45),
        ),
        const SizedBox(height: 10),
        Text(
          '${user.firstName} ${user.lastName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user.email,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDonationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dukung Pengembang',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jika Anda menikmati aplikasi ini, Anda dapat memberikan donasi:',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank ABC: 123-456-7890',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'a/n Pengembang Aplikasi',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Jumlah Donasi (IDR)',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _donationController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Masukkan jumlah dalam IDR',
            prefixIcon: Icon(Icons.money, color: Colors.white70),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsFormatter(),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _handleDonationInput(_donationController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: const Text(
            'Konversi Mata Uang',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Setara dengan:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildCurrencyRow('USD', _usdAmount, '\$'),
        _buildCurrencyRow('EUR', _eurAmount, '€'),
        _buildCurrencyRow('JPY', _jpvAmount, '¥'),
      ],
    );
  }

  Widget _buildCurrencyRow(String currency, double amount, String symbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          currency,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        Text(
          '$symbol ${_foreignFormatter.format(amount)}',
          style: const TextStyle(
            color: Color(0xFF03DAC6),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTest(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uji Notifikasi',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tekan tombol di bawah ini untuk menguji notifikasi instan.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          icon: const Icon(Icons.notifications_active, color: Colors.black),
          label: const Text(
            'Kirim Notifikasi Tes',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
          ),
          onPressed: () async {
            await _notificationService.showNotification(
              'Tes Notifikasi',
              'Notifikasi percobaan dari SoundWorthy!',
              id: 99,
            );
            _showSnackbar('Notifikasi tes berhasil dikirim!');
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return ListTile(
      leading: const Icon(Icons.feedback, color: Colors.white70),
      title: const Text(
        'Kesan & Pesan',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KesanPesanScreen()),
        );
      },
    );
  }

  Widget _buildSessionExpired() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Center(
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Ke Halaman Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Formatter ribuan
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final number = int.tryParse(newText);
    if (number == null) return oldValue;
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number).replaceAll(',', '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
