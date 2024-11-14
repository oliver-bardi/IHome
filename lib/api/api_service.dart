import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000"; // A backend API IP-címe és portja

  // Metódus az összes kapcsoló állapotának lekérdezéséhez
  Future<Map<int, String>?> getAllSwitchStatuses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/switches/statuses'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Konvertálás Map<int, String> típusra a kapcsolóindexekhez és állapotokhoz
        return data.map((key, value) => MapEntry(int.parse(key), value as String));
      } else {
        print("Failed to load switch statuses");
        return null;
      }
    } catch (e) {
      print("Error fetching switch statuses: $e");
      return null;
    }
  }

  // Metódus egy adott kapcsoló vezérléséhez (kapcsoló be- vagy kikapcsolása)
  Future<bool> controlSwitch(int switchIndex, String newState) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/switch/$switchIndex/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"state": newState}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error controlling switch: $e");
      return false;
    }
  }

  // Egy adott eszköz állapotának lekérdezése
  Future<String?> getDeviceStatus(String device) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/device/$device/status'));

      if (response.statusCode == 200) {
        return json.decode(response.body)['status'];
      } else {
        print("Failed to load device status");
        return null;
      }
    } catch (e) {
      print("Error fetching device status: $e");
      return null;
    }
  }

  // Egy adott eszköz vezérlése
  Future<bool> controlDevice(String device, String newState) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device/$device/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"state": newState}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error controlling device: $e");
      return false;
    }
  }

  // Új metódus a szenzoradatok lekérdezéséhez
  Future<Map<String, double>?> getSensorData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sensors/data'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        print("Failed to load sensor data");
        return null;
      }
    } catch (e) {
      print("Error fetching sensor data: $e");
      return null;
    }
  }
}
