import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/refund.dart';

class RefundService {
  static const String baseUrl = 'http://192.168.100.53:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Refund>> getRefunds({
    String? status,
    int? userId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      var uri = Uri.parse('$baseUrl/refunds/');
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (userId != null) queryParams['user_id'] = userId.toString();

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Refund.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar devoluciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Refund> getRefund(int refundId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/refunds/$refundId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Refund.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al cargar devolución');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Refund> recordPayment({
    required int refundId,
    required int amount,
    required String refundMethod,
    String? notes,
    String? receiptUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/refunds/$refundId/record-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'refund_method': refundMethod,
          if (notes != null) 'notes': notes,
          if (receiptUrl != null) 'receipt_url': receiptUrl,
        }),
      );

      if (response.statusCode == 200) {
        return Refund.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al registrar pago');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Refund> confirmRefund({
    required int refundId,
    String? adminNotes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/refunds/$refundId/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (adminNotes != null) 'admin_notes': adminNotes,
        }),
      );

      if (response.statusCode == 200) {
        return Refund.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al confirmar devolución');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Refund> waiveRefund({
    required int refundId,
    required String waiveReason,
    String? adminNotes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/refunds/$refundId/waive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'waive_reason': waiveReason,
          if (adminNotes != null) 'admin_notes': adminNotes,
        }),
      );

      if (response.statusCode == 200) {
        return Refund.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al exonerar devolución');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Refund> updateRefund({
    required int refundId,
    String? notes,
    String? refundMethod,
    String? receiptUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.put(
        Uri.parse('$baseUrl/refunds/$refundId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (notes != null) 'notes': notes,
          if (refundMethod != null) 'refund_method': refundMethod,
          if (receiptUrl != null) 'receipt_url': receiptUrl,
        }),
      );

      if (response.statusCode == 200) {
        return Refund.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar devolución');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteRefund(int refundId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.delete(
        Uri.parse('$baseUrl/refunds/$refundId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar devolución');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
