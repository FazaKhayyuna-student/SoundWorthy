import 'package:flutter/material.dart';

class KesanPesanScreen extends StatelessWidget {
  const KesanPesanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          'Kesan & Pesan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          // ↑ tambahkan padding bawah biar teks gak ketutup navbar
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang Aplikasi SoundWorthy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'SoundWorthy adalah aplikasi mobile yang dirancang untuk para pecinta musik berbagi ulasan dan rating lagu favorit mereka. Aplikasi ini mengambil data lagu dari Spotify Web API dan menyimpan ulasan pengguna secara lokal menggunakan SQLite.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Fitur Unggulan:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '- Pencarian lagu via Spotify\n'
                '- Penulisan ulasan dan rating bintang\n'
                '- Tampilan waktu ulasan dalam WIB, WITA, WIT\n'
                '- Penyimpanan lokasi ulasan (opsional)\n'
                '- Simulasi donasi dengan konversi mata uang (offline)\n'
                '- Notifikasi lokal\n'
                '- Detail ulasan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Dikembangkan Oleh:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Muhammad Faza Khayyuna\n124230018\nSistem Informasi\nUniversitas Pembangunan Nasional "Veteran" Yogyakarta',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Kesan Pesan Selama Perkuliahan:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Terima kasih saya ucapkan sebelumnya kepada Bapak Bagus sebagai dosen mata kuliah PAM.\nSehubungan dengan kesan dan yang akan saya berikan, sebenarnya saya berpikir keras untuk ini pak.\nMungkin pertama karena kelas kami di hari senin banyak kosongnya,\ndan dari bapak sendiri tidak sepenuhnya menjelaskan banyak hal kepada kami\nMungkin memang menjadi tugas mahasiswa untuk belajar sendiri dan bapak sendiri sudah mention hal itu di awal.\njadi bukan berarti menyalahkan, tapi kebiasaan mahasiswa sendiri tidak sepenuh nya rely on praktikum pak,\n dan tidak sepenuhnya bisa koding\nTapi tetap berkesan pak karena baru pertama merasakan jadi single army dalam satu minggu membuat project.\n\nJadi mungkin pesannya lebih membersamai mahasiswa untuk matakuliah koding yang susah ini pak. \n\nMohon maaf bila tidak sopan pak, terima kasih pak.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
