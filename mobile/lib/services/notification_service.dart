import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      relatedId: json['related_id'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationService {
  final String baseUrl = 'http://192.168.100.53:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final url = unreadOnly
          ? '$baseUrl/notifications/?unread_only=true'
          : '$baseUrl/notifications/';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar notificaciones');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      await http.put(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
