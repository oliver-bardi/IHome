#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

#define DHTPIN 2      // Pin where the DHT11 is connected
#define DHTTYPE DHT11 // DHT 11

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "FRANKIE 9564";   // Your Wi-Fi SSID
const char* password = "y008<D19";    // Your Wi-Fi Password
const char* mqtt_server = "192.168.137.1"; // MQTT Broker IP

WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Attempt to connect
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
      client.subscribe("home/sensor_data");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" trying again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, 1883);
  dht.begin();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Read humidity and temperature
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // Check if any reads failed and exit early (to try again).
  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }

  Serial.print("Temperature: ");
  Serial.print(t);
  Serial.print(" °C, Humidity: ");
  Serial.print(h);
  Serial.println(" %");

  // Create JSON payload with both temperature and humidity
  String payload = "{\"temperature\":" + String(t) + ",\"humidity\":" + String(h) + ",\"switch_1_state\":0,\"switch_2_state\":0,\"switch_3_state\":0}";
  client.publish("home/sensor_data", payload.c_str());

  delay(3000); // Send data every 3 seconds
}
