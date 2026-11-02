
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Alamat server untuk Android Emulator.
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Mengambil data dari server.
  Future<Map<String, dynamic>> getData() async {
    final url = Uri.parse('$baseUrl/api/data');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Gagal mengambil data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }
}
