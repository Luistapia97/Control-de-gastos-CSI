import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import '../models/expense.dart';

class ReportService {
  static const String baseUrl = 'https://control-de-gastos-csi.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Report>> getReports({String? status}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      var uri = Uri.parse('$baseUrl/reports/');
      if (status != null) {
        uri = uri.replace(queryParameters: {'status': status});
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar reportes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getReport(int reportId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'report': Report.fromJson(data),
          'expenses': (data['expenses'] as List?)
                  ?.map((e) => Expense.fromJson(e))
                  .toList() ??
              [],
        };
      } else {
        throw Exception('Error al cargar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> createReport({
    required String name,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al crear reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> updateReport({
    required int reportId,
    String? name,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final body = <String, dynamic>{};
      if (name != null) body['title'] = name;
      if (description != null) body['description'] = description;

      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al actualizar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> addExpenseToReport({
    required int reportId,
    required int expenseId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/add-expense/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al agregar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> removeExpenseFromReport({
    required int reportId,
    required int expenseId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId/remove-expense/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al quitar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> submitReport(int reportId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al enviar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> generateReportFromTrip(int tripId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/generate-report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al generar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Report>> getPendingReports() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar reportes pendientes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> approveReport(int reportId, {String? comments}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'comments': comments ?? '',
        }),
      );

      if (response.statusCode == 200) {
        // Solo intentar decodificar si el content-type es JSON
        if (response.headers['content-type']?.contains('application/json') ?? false) {
          return Report.fromJson(jsonDecode(response.body));
        } else {
          throw Exception('Respuesta inesperada del servidor');
        }
      } else {
        // Intentar decodificar el error, si no es JSON mostrar texto plano
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Error al aprobar reporte');
        } catch (_) {
          throw Exception(response.body);
        }
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Report> rejectReport(int reportId, {String? comments}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'comments': comments ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al rechazar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
