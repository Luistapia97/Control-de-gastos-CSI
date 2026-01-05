import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://control-de-gastos-csi.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? adminCode,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'full_name': fullName,
      };
      
      if (adminCode != null && adminCode.isNotEmpty) {
        body['admin_code'] = adminCode;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al registrar');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await _saveToken(token);
        return token;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> logout() async {
    await _removeToken();
  }

  Future<User> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener usuario');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }
}
