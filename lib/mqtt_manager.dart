import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager {
  late MqttServerClient client;
  String broker = '192.168.137.1'; // Replace with your MQTT broker IP
  int port = 1883;
  String clientId = 'flutter_client';

  // Define callback for updating UI
  Function(String, String)? onDataReceived;

  MQTTManager() {
    client = MqttServerClient(broker, clientId);
    client.port = port;

    // Set keep alive interval
    client.keepAlivePeriod = 20; // Set to your desired value

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
        // Subscribe to topics
        subscribe('home/sensor_data');
      }
    } catch (e) {
      print('Error connecting to the MQTT Broker: $e');
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttReceivedMessage<MqttMessage> message = c[0];
      final MqttMessage mqttMessage = message.payload;

      // Assuming the payload is a JSON string with temperature and humidity
      final payload = mqttMessage as MqttPublishMessage; // Cast to MqttPublishMessage
      final String messagePayload = utf8.decode(payload.payload.message);

      if (topic == 'home/sensor_data') {
        final data = jsonDecode(messagePayload);
        String temperature = data['temperature'].toString();
        String humidity = data['humidity'].toString();

        // Notify the UI about new data
        if (onDataReceived != null) {
          onDataReceived!(temperature, humidity);
        }
      }
      print('Received message: $messagePayload');
    });
  }
}
