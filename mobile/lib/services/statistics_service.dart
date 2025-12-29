import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  static const String baseUrl = 'http://192.168.100.53:8000/api/statistics';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getOverview({
    String? startDate,
    String? endDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    String url = baseUrl + '/overview';
    
    List<String> params = [];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    
    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load overview: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory({
    String? startDate,
    String? endDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    String url = baseUrl + '/by-category';
    
    List<String> params = [];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    
    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend({
    int months = 6,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/monthly-trend?months=$months'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load trend: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/top-users?limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load top users: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getBudgetCompliance() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/budget-compliance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load compliance: ${response.body}');
    }
  }
}
