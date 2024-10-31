import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
  late MQTTManager mqttManager;

  @override
  void initState() {
    super.initState();
    mqttManager = MQTTManager(
      onDataReceived: () {
        setState(() {}); // Updates UI on new data
      },
    );
    mqttManager.connect();
  }

  @override
  Widget build(BuildContext context) {
    // Convert temperature and humidity values to double, with default as 0
    double temperatureValue = double.tryParse(mqttManager.temperature) ?? 0;
    double humidityValue = double.tryParse(mqttManager.humidity) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Sensor Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Circular indicator for temperature
            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 13.0,
              animation: true,
              percent: (temperatureValue / 100).clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${mqttManager.temperature}°C",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Temperature',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.orangeAccent,
              backgroundColor: Colors.orange[100]!,
            ),
            SizedBox(height: 30),
            // Circular indicator for humidity
            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 13.0,
              animation: true,
              percent: (humidityValue / 100).clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${mqttManager.humidity}%",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Humidity',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.blueAccent,
              backgroundColor: Colors.blue[100]!,
            ),
            SizedBox(height: 30),
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
    mqttManager.disconnect();
    super.dispose();
  }
}
