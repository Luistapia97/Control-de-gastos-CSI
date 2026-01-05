import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'https://control-de-gastos-csi.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener usuario actual');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/users/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al cargar usuarios');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
