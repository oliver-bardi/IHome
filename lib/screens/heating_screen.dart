import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'mqtt_manager.dart';
import 'dart:async';

class HeatingScreen extends StatefulWidget {
  @override
  _HeatingScreenState createState() => _HeatingScreenState();
}

class _HeatingScreenState extends State<HeatingScreen> with SingleTickerProviderStateMixin {
  late MQTTManager mqttManager;
  late AnimationController _controller;
  late Animation<double> temperatureAnimation;
  late Animation<double> humidityAnimation;
  double currentTemperaturePercent = 0.0;
  double currentHumidityPercent = 0.0;
  static const double minTemperature = -40.0;
  static const double maxTemperature = 40.0;

  String temperatureDisplay = 'N/A';
  String humidityDisplay = 'N/A';

  DateTime lastUpdate = DateTime.now();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    mqttManager = MQTTManager(onDataReceived: () {
      _updateValuesIfChanged();
    });
    mqttManager.connect();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    temperatureAnimation = Tween<double>(begin: currentTemperaturePercent, end: currentTemperaturePercent)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    humidityAnimation = Tween<double>(begin: currentHumidityPercent, end: currentHumidityPercent)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Időzítő indítása a frissítések ellenőrzéséhez
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkForSensorTimeout();
    });
  }

  void _updateValuesIfChanged() {
    double? temperature = double.tryParse(mqttManager.temperature);
    double? humidity = double.tryParse(mqttManager.humidity);

    if (temperature == null || humidity == null || temperature.isNaN || humidity.isNaN) {
      // Ha nincs adat, akkor "N/A" érték jelenik meg, és a százalék 0 lesz
      setState(() {
        temperatureDisplay = 'N/A';
        humidityDisplay = 'N/A';
        currentTemperaturePercent = 0.0;
        currentHumidityPercent = 0.0;
      });
    } else {
      temperatureDisplay = "${mqttManager.temperature}°C";
      humidityDisplay = "${mqttManager.humidity}%";

      // Százalékos érték kiszámítása a -40 és 40 közötti tartományra
      double newTemperaturePercent = ((temperature - minTemperature) / (maxTemperature - minTemperature)).clamp(0.0, 1.0);
      double newHumidityPercent = (humidity / 100).clamp(0.0, 1.0);

      if (newTemperaturePercent != currentTemperaturePercent || newHumidityPercent != currentHumidityPercent) {
        temperatureAnimation = Tween<double>(
          begin: currentTemperaturePercent,
          end: newTemperaturePercent,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

        humidityAnimation = Tween<double>(
          begin: currentHumidityPercent,
          end: newHumidityPercent,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

        setState(() {
          currentTemperaturePercent = newTemperaturePercent;
          currentHumidityPercent = newHumidityPercent;
          lastUpdate = DateTime.now(); // Frissítjük az utolsó frissítés időpontját
        });
        _controller.forward(from: 0);
      }
    }
  }

  void _checkForSensorTimeout() {
    final currentTime = DateTime.now();
    final timeSinceLastUpdate = currentTime.difference(lastUpdate).inSeconds;

    if (timeSinceLastUpdate > 1) { // Ha több mint 5 másodperc telt el
      setState(() {
        temperatureDisplay = 'N/A';
        humidityDisplay = 'N/A';
        currentTemperaturePercent = 0.0;
        currentHumidityPercent = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fűtés/Hűtés")),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: temperatureAnimation,
              builder: (context, child) {
                bool isNegativeTemperature = (double.tryParse(mqttManager.temperature) ?? 0) < 0;
                return CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 10.0,
                  animation: false,
                  reverse: isNegativeTemperature,
                  percent: temperatureDisplay == 'N/A' ? 0.0 : temperatureAnimation.value,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        temperatureDisplay,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Temp', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: isNegativeTemperature ? Colors.blueAccent : Colors.orangeAccent,
                  backgroundColor: Colors.grey[300]!,
                );
              },
            ),
            SizedBox(width: 20),
            AnimatedBuilder(
              animation: humidityAnimation,
              builder: (context, child) {
                return CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 10.0,
                  animation: false,
                  percent: humidityDisplay == 'N/A' ? 0.0 : humidityAnimation.value,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        humidityDisplay,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Humidity', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: Colors.blueAccent,
                  backgroundColor: Colors.blue[100]!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel(); // Timer leállítása kilépéskor
    mqttManager.disconnect();
    _controller.dispose();
    super.dispose();
  }
}
