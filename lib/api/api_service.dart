// lib/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://<backend_url>:8000';

  Future<void> controlDevice(int switchId, String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/control'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'switch_id': switchId, 'action': action}),
    );

    if (response.statusCode == 200) {
      print('Switch control successful');
    } else {
      print('Failed to control switch');
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/status'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get status');
    }
  }
}
