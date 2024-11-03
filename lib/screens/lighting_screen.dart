import 'package:flutter/material.dart';
import 'mqtt_manager.dart';

class LightingScreen extends StatefulWidget {
  @override
  _LightingScreenState createState() => _LightingScreenState();
}

class _LightingScreenState extends State<LightingScreen> {
  late MQTTManager mqttManager;
  bool nappaliSwitchState = false; // Nappali kapcsoló állapota

  @override
  void initState() {
    super.initState();
    mqttManager = MQTTManager(onDataReceived: () {
      setState(() {});
    });
    mqttManager.connect();
  }

  void _toggleNappaliSwitch(bool value) {
    setState(() {
      nappaliSwitchState = value;
    });
    mqttManager.publishSwitchState(nappaliSwitchState); // Relé vezérlés a Nappali kapcsolóval
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Világítás")),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          SwitchListTile(
            title: Text("Nappali"),
            value: nappaliSwitchState,
            onChanged: _toggleNappaliSwitch, // Nappali kapcsoló a reléhez
          ),
          _buildLightSwitch("Hálószoba"),
          _buildLightSwitch("Konyha"),
          _buildLightSwitch("Fürdőszoba"),
        ],
      ),
    );
  }

  Widget _buildLightSwitch(String room) {
    return SwitchListTile(
      title: Text(room),
      value: false,
      onChanged: (value) {},
    );
  }

  @override
  void dispose() {
    mqttManager.disconnect();
    super.dispose();
  }
}
