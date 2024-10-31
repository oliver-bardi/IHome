import 'package:flutter/material.dart';
import 'mqtt_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MQTTManager mqttManager = MQTTManager();
  String temperature = 'N/A';
  String humidity = 'N/A';

  @override
  void initState() {
    super.initState();

    // Set the onDataReceived callback
    mqttManager.onDataReceived = (String newTemperature, String newHumidity) {
      setState(() {
        temperature = newTemperature;
        humidity = newHumidity;
      });
    };

    mqttManager.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Sensor Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Temperature: $temperature °C',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Humidity: $humidity %',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                mqttManager.connect();
              },
              child: Text('Reconnect to MQTT Broker'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mqttManager.client.disconnect();
    super.dispose();
  }
}
