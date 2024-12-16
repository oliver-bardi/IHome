import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

final int livingRoomWindowsSwitchId = 1;
final int bedroomWindowsSwitchId = 3;
final int shuttersSwitchId = 4;
final int garageDoorSwitchId = 5;
final int powerCutSwitchId = 6;
final int outsideLighting = 7;
final int vacationModeSwitchId = 8;
final int securitySystemSwitchId = 9;
final int coffeMachineId = 10;
final int gadrenWateringId = 11;
final int carChargingId = 12;
final int heatingId = 13;
final int coolingId = 14;
final int motionDetectorsId = 15;

Map<String, ValueNotifier<bool>> switchStates = {
  'Living Room Windows': ValueNotifier(false),
  'Bedroom Windows': ValueNotifier(false),
  'Shutters': ValueNotifier(false),
  'Garage Door': ValueNotifier(false),
  'Power Cut': ValueNotifier(false),
  'Outside Lighting': ValueNotifier(false),
  'Vacation Mode': ValueNotifier(false),
  'Security System': ValueNotifier(false),
  'Coffee Machine': ValueNotifier(false),
  'Garden Watering': ValueNotifier(false),
  'Car Charging': ValueNotifier(false),
  'Heating': ValueNotifier(false),
  'Cooling': ValueNotifier(false),
  'Motion Detectors': ValueNotifier(false),
};

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  @override
  void initState() {
    super.initState();
    _fetchSwitchStates(); // Kezdeti állapotlekérés
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchSwitchStates(); // 1 másodpercenként frissítjük az állapotokat
    });
  }

  int _getSwitchId(String name) {
    switch (name) {
      case 'Living Room Windows': return livingRoomWindowsSwitchId;
      case 'Bedroom Windows': return bedroomWindowsSwitchId;
      case 'Shutters': return shuttersSwitchId;
      case 'Garage Door': return garageDoorSwitchId;
      case 'Power Cut': return powerCutSwitchId;
      case 'Outside Lighting': return outsideLighting;
      case 'Vacation Mode': return vacationModeSwitchId;
      case 'Security System': return securitySystemSwitchId;
      case 'Coffee Machine': return coffeMachineId;
      case 'Garden Watering': return gadrenWateringId;
      case 'Car Charging': return carChargingId;
      case 'Heating': return heatingId;
      case 'Cooling': return coolingId;
      case 'Motion Detectors': return motionDetectorsId;
      default: return -1;
    }
  }

  Future<void> _fetchSwitchStates() async {
    final url = Uri.parse('http://192.168.137.1:5000/switch_states');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> states = jsonDecode(response.body);

        for (var entry in switchStates.keys) {
          int id = _getSwitchId(entry);
          switchStates[entry]!.value = states['$id'] == 'ON';
        }
      } else {
        print('Failed to fetch switch states: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching switch states: $e');
    }
  }

  Future<void> _toggleControlSwitch(String controlName) async {
    int switchId = _getSwitchId(controlName);
    if (switchId == -1) return;

    final currentState = switchStates[controlName]!.value;

    // Optimistic update: Frissítjük előre az állapotot
    switchStates[controlName]!.value = !currentState;

    try {
      final url = Uri.parse('http://192.168.137.1:5000/switches/$switchId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': currentState ? 'OFF' : 'ON'}),
      );

      if (response.statusCode != 200) {
        print('Failed to toggle $controlName: ${response.statusCode}');
        // Ha a szerver nem sikeres, visszaállítjuk az előző állapotot
        switchStates[controlName]!.value = currentState;
      }
    } catch (e) {
      print('Error toggling $controlName: $e');
      // Hiba esetén visszaállítjuk az állapotot
      switchStates[controlName]!.value = currentState;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ControlWidget(onToggle: _toggleControlSwitch),
      ),
    );
  }
}

class ControlWidget extends StatelessWidget {
  final Function(String) onToggle;

  const ControlWidget({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          title: Text(
            'Smart Controls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Manage your home devices'),
        ),
        const Divider(),
        for (var entry in switchStates.keys)
          _buildSwitchRow(entry, _getIcon(entry)),
      ],
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'Living Room Windows': return Icons.window;
      case 'Shutters': return Icons.shutter_speed;
      case 'Garage Door': return Icons.garage;
      case 'Power Cut': return Icons.power_off;
      case 'Outside Lighting': return Icons.lightbulb_outline;
      case 'Vacation Mode': return Icons.beach_access;
      case 'Security System': return Icons.security;
      case 'Coffee Machine': return Icons.coffee;
      case 'Garden Watering': return Icons.grass;
      case 'Car Charging': return Icons.electric_car;
      case 'Heating': return Icons.whatshot;
      case 'Cooling': return Icons.ac_unit;
      case 'Motion Detectors': return Icons.motion_photos_on;
      default: return Icons.device_unknown;
    }
  }

  Widget _buildSwitchRow(String name, IconData icon) {
    return ValueListenableBuilder<bool>(
      valueListenable: switchStates[name]!,
      builder: (context, value, _) {
        return ListTile(
          leading: Icon(icon, size: 30),
          title: Text(name),
          trailing: Switch(
            value: value,
            onChanged: (bool newValue) => onToggle(name),
          ),
        );
      },
    );
  }
}
