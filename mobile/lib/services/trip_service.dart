import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import '../models/report.dart';

class TripService {
  static const String baseUrl = 'https://control-de-gastos-csi.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Trip>> getTrips({String? status}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    var url = '$baseUrl/trips/';
    if (status != null) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trips');
    }
  }

  Future<Trip> createTrip({
    required String name,
    String? destination,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    int? budget,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/trips/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'destination': destination,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'description': description,
        'budget': budget,
      }),
    );

    if (response.statusCode == 200) {
      return Trip.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create trip');
    }
  }

  Future<Trip> getTrip(int tripId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Trip.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load trip');
    }
  }

  Future<Trip> updateTrip(int tripId, Map<String, dynamic> updates) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return Trip.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update trip');
    }
  }

  Future<void> deleteTrip(int tripId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete trip');
    }
  }

  Future<Trip> completeTrip(int tripId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/complete'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Trip.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to complete trip');
    }
  }

  Future<Report?> getTripReport(int tripId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId/report'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Report.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null; // No hay reporte para este viaje
    } else {
      throw Exception('Failed to get trip report');
    }
  }
}
