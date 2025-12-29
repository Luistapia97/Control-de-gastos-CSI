import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExpenseService {
  static const String baseUrl = 'http://192.168.100.53:8000/api'; // Emulador Android -> localhost

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Expense>> getExpenses({
    int? categoryId,
    String? status,
    int? tripId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      var uri = Uri.parse('$baseUrl/expenses/');
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (status != null) queryParams['status'] = status;
      if (tripId != null) queryParams['trip_id'] = tripId.toString();

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('DEBUG ExpenseService - Response body: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        print('DEBUG ExpenseService - Parsed ${data.length} expenses');
        final expenses = data.map((json) => Expense.fromJson(json)).toList();
        print('DEBUG ExpenseService - Converted to ${expenses.length} Expense objects');
        return expenses;
      } else {
        print('DEBUG ExpenseService - Error status: ${response.statusCode}');
        print('DEBUG ExpenseService - Error body: ${response.body}');
        throw Exception('Error al cargar gastos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Expense> createExpense({
    required int categoryId,
    required int amount,
    String currency = 'USD',
    String? merchant,
    String? description,
    required DateTime expenseDate,
    int? tripId,
    File? receiptImage,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final uri = Uri.parse('$baseUrl/expenses/');
      
      // Crear multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Agregar headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Agregar campos
      request.fields['category_id'] = categoryId.toString();
      request.fields['amount'] = amount.toString();
      request.fields['currency'] = currency;
      request.fields['expense_date'] = expenseDate.toIso8601String();
      
      if (merchant != null) {
        request.fields['merchant'] = merchant;
      }
      if (description != null) {
        request.fields['description'] = description;
      }
      if (tripId != null) {
        request.fields['trip_id'] = tripId.toString();
      }
      
      // Agregar imagen si existe
      if (receiptImage != null) {
        var stream = http.ByteStream(receiptImage.openRead());
        var length = await receiptImage.length();
        var multipartFile = http.MultipartFile(
          'receipt',
          stream,
          length,
          filename: receiptImage.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
      
      // Enviar request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return Expense.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al crear gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> scanReceipt(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final uri = Uri.parse('$baseUrl/expenses/scan');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en OCR');
      }
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> updates) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar categorías');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
