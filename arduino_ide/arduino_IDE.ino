#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

#define DHTPIN 2         // Pin where the DHT11 is connected
#define DHTTYPE DHT11    // DHT 11
#define RELAY_PIN 4      // GPIO pin for relay control

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "FRANKIE 9564";   // Your Wi-Fi SSID
const char* password = "y008<D19";    // Your Wi-Fi Password
const char* mqtt_server = "192.168.137.1"; // MQTT Broker IP

WiFiClient espClient;
PubSubClient client(espClient);

bool switchState = false; // Kapcsoló állapota (alapértelmezés szerint kikapcsolt állapot)
String state = "OFF";

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

void callback(char* topic, byte* message, unsigned int length) {
  String receivedMessage;
  for (int i = 0; i < length; i++) {
    receivedMessage += (char)message[i];
  }
  Serial.print("Message received on topic ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(receivedMessage);

  // Ha az üzenet a "home/switch" témában jön, akkor frissítjük a kapcsoló állapotát
  if (String(topic) == "home/switch") {
    if (receivedMessage == "ON") {
      switchState = true;
      digitalWrite(RELAY_PIN, HIGH); // Relé bekapcsolása
    } else if (receivedMessage == "OFF") {
      switchState = false;
      digitalWrite(RELAY_PIN, LOW); // Relé kikapcsolása
    }
    Serial.print("Switch state set to: ");
    Serial.println(switchState ? "ON" : "OFF");
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
      client.subscribe("home/sensor_data"); // Szenzor adatokat küld
      client.subscribe("home/switch");      // Kapcsoló üzeneteket fogad
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
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Kezdetben kikapcsolva tartja a relét

  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
  dht.begin();
}

unsigned long previousMillis = 0;
const long interval = 3000; // 3 másodperc az adatküldés intervalluma

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Ellenőrzi az időt, hogy mikor kell újra adatot küldeni
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // Szenzoradatokat olvasunk
    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (isnan(h) || isnan(t)) {
      Serial.println("Hiba a DHT szenzor olvasásakor!");
      return;
    }

    Serial.print("Hőmérséklet: ");
    Serial.print(t);
    Serial.print(" °C, Páratartalom: ");
    Serial.print(h);
    Serial.println(" %");

    // Adatok küldése MQTT-n keresztül
    String payload = "{\"temperature\":" + String(t) + ",\"humidity\":" + String(h) + "}";
    client.publish("home/sensor_data", payload.c_str());

    String hum = String(h, 1);
    Serial.print("Humidity: ");
    Serial.println(hum);
    client.publish("Humidity", hum.c_str());

      String temp = String(t, 1);
    Serial.print("Temperature: ");
    Serial.println(temp);
    client.publish("Temperature", temp.c_str());

    if (switchState == true ){
         state  = "ON";
    }
    else  {
         state  = "OFF";
    }


    Serial.print("State: ");
    Serial.println(state);
    client.publish("State", state.c_str());
    
   

  }


}