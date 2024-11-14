import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = "http://172.20.0.1:8000";

  Future<void> controlDevice(String module, String state) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/control/$module"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"state": state}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to control $module");
    }
  }

  Future<String> getDeviceStatus(String module) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/status/$module"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"];
    } else {
      throw Exception("Failed to fetch $module status");
    }
  }
}
