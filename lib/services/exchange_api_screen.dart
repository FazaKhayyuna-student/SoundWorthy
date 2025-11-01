import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeApiService {
  final String _baseUrl = 'https://api.exchangerate.host/latest';

  // [PERUBAHAN DI SINI]: Ubah tipe return Map menjadi Map<String, double>
  Future<Map<String, double>?> getRates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?base=IDR&symbols=USD,EUR,JPY'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['rates'] is Map) {
          // Periksa juga tipe 'rates'
          final ratesData = data['rates'] as Map<String, dynamic>;

          // Pastikan konversi ke double aman
          try {
            final rates = ratesData.map(
              (key, value) => MapEntry(
                key,
                (value as num).toDouble(),
              ), // Konversi num ke double
            );
            return rates;
          } catch (e) {
            print('Error converting rates to double: $e');
            return null;
          }
        } else {
          print(
            'Format response API nilai tukar tidak valid (key "rates" hilang atau bukan Map).',
          );
          return null;
        }
      } else {
        print(
          'Gagal mengambil nilai tukar: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getRates (Network or Parsing): $e');
      return null;
    }
  }
}
