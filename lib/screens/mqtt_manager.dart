import 'dart:convert';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

class MQTTManager {
  late MqttServerClient client;
  String broker = '192.168.137.1';
  int port = 1883;
  String clientId = 'flutter_client';
  String temperature = 'N/A';
  String humidity = 'N/A';

  Function? onDataReceived;

  MQTTManager({this.onDataReceived}) {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
  }

  void onSubscribed(String topic) {
    print('Feliratkozás a témára: $topic');
  }

  void onConnected() {
    print('Kapcsolódva az MQTT szerverhez');
  }

  void onDisconnected() {
    print('Kapcsolat megszakadt az MQTT szerverrel');
  }

  Future<void> connect() async {
    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('Kapcsolódva az MQTT szerverhez');
        subscribe('home/sensor_data');
      }
    } catch (e) {
      print('Hiba az MQTT szerverhez való kapcsolódáskor: $e');
      client.disconnect();
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Üzenet érkezett: $payload');
      final data = jsonDecode(payload);

      temperature = data['temperature']?.toString() ?? 'N/A';
      humidity = data['humidity']?.toString() ?? 'N/A';

      if (onDataReceived != null) {
        onDataReceived!();
      }
    });
  }

  void publishSwitchState(bool state) {
    final payload = state ? "ON" : "OFF";
    Uint8List byteData = Uint8List.fromList(utf8.encode(payload));
    Uint8Buffer buffer = Uint8Buffer()..addAll(byteData);

    client.publishMessage("home/switch", MqttQos.atMostOnce, buffer);
    print("Kapcsoló állapotának küldése: $payload");
  }

  void disconnect() {
    client.disconnect();
  }
}
