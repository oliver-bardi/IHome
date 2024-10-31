import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager {
  late MqttServerClient client;
  String broker = '192.168.137.1'; // Replace with your MQTT broker IP
  int port = 1883;
  String clientId = 'flutter_client';
  String temperature = 'N/A';
  String humidity = 'N/A';

  // Callback for UI updates
  Function? onDataReceived;

  MQTTManager({this.onDataReceived}) {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 20;

    // Set up callbacks
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void onConnected() {
    print('Connected to MQTT Broker');
  }

  void onDisconnected() {
    print('Disconnected from MQTT Broker');
  }

  Future<void> connect() async {
    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('Connected to the MQTT Broker');
        subscribe('home/sensor_data');
      }
    } catch (e) {
      print('Error connecting to the MQTT Broker: $e');
      client.disconnect();
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message: $payload');
      final data = jsonDecode(payload);

      // Parse temperature and humidity, then trigger callback
      temperature = data['temperature']?.toString() ?? 'N/A';
      humidity = data['humidity']?.toString() ?? 'N/A';

      if (onDataReceived != null) {
        onDataReceived!();
      }
    });
  }

  void disconnect() {
    client.disconnect();
  }
}
