#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

// Define pins for the DHT11 sensors
#define DHTPIN1 2    // First DHT11 sensor connected to GPIO 2
#define DHTPIN2 4    // Second DHT11 sensor connected to GPIO 4
#define DHTTYPE DHT11 // DHT 11 type

// Define pins for 15 relays (switches)
const int RELAY_PINS[15] = {5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27};

// Create DHT sensor objects
DHT dht1(DHTPIN1, DHTTYPE);
DHT dht2(DHTPIN2, DHTTYPE);

//const char* ssid = "FRANKIE 9564";         // Your Wi-Fi SSID
//const char* password = "y008<D19";          // Your Wi-Fi Password
//const char* mqtt_server = "192.168.137.1";  // MQTT Broker IP

const char* ssid = "DESKTOP-8RI5QJ9";         // Your Wi-Fi SSID
const char* password = "45,i527H";          // Your Wi-Fi Password
const char* mqtt_server = "192.168.137.1";

WiFiClient espClient;
PubSubClient client(espClient);

// Array to hold the state of each switch (default OFF)
bool switchStates[15] = {false}; // All switches off initially

void setup_wifi() {
    delay(10);
    Serial.begin(115200);
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

    // Handle switch topics by parsing the index from the topic
    if (String(topic).startsWith("home/switch/")) {
        int switchIndex = String(topic).substring(12).toInt(); // Extract switch number from topic

        // Check if the switchIndex is within bounds
        if (switchIndex >= 0 && switchIndex < 15) {
            switchStates[switchIndex] = (receivedMessage == "ON");
            digitalWrite(RELAY_PINS[switchIndex], switchStates[switchIndex] ? HIGH : LOW);
            Serial.print("Switch ");
            Serial.print(switchIndex);
            Serial.print(" state set to: ");
            Serial.println(switchStates[switchIndex] ? "ON" : "OFF");
        }
    }
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Attempting MQTT connection...");
        if (client.connect("ESP32Client")) {
            Serial.println("connected");

            // Subscribe to all switch commands using wildcard
            client.subscribe("home/switch/+/set");
        } else {
            Serial.print("failed, rc=");
            Serial.print(client.state());
            Serial.println(" trying again in 5 seconds");
            delay(5000);
        }
    }
}

void setup() {
    setup_wifi();
    client.setServer(mqtt_server, 1883);
    client.setCallback(callback);

    // Initialize DHT sensors
    dht1.begin();
    dht2.begin();

    // Initialize relay pins
    for (int i = 0; i < 15; i++) {
        pinMode(RELAY_PINS[i], OUTPUT);
        digitalWrite(RELAY_PINS[i], LOW); // Start with all relays off
    }
}

unsigned long previousMillis = 0;
const long interval = 3000;

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();

    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
        previousMillis = currentMillis;

        // Read data from both DHT sensors
        float humidity1 = dht1.readHumidity();
        float temperature1 = dht1.readTemperature();
        float humidity2 = dht2.readHumidity();
        float temperature2 = dht2.readTemperature();

        // Check if reading failed and exit if so
        if (isnan(humidity1) || isnan(temperature1) || isnan(humidity2) || isnan(temperature2)) {
            Serial.println("Error reading from DHT sensors!");
            return;
        }

        // Create a JSON payload with sensor data and switch states
        String payload = "{";
        payload += "\"temperature1\":" + String(temperature1) + ",";
        payload += "\"humidity1\":" + String(humidity1) + ",";
        payload += "\"temperature2\":" + String(temperature2) + ",";
        payload += "\"humidity2\":" + String(humidity2) + ",";

        // Add each switch state to the payload, only including switches that are ON
        payload += "\"switchStates\":{";
        bool first = true; // Flag to handle commas
        for (int i = 0; i < 15; i++) {
            if (switchStates[i]) { // Only send ON switches
                if (!first) payload += ","; // Add comma between switch states
                payload += "\"switch" + String(i) + "\":\"ON\"";
                first = false;
            }
        }
        payload += "}}"; // Close JSON objects

        // Publish the JSON payload
        if (client.publish("home/status", payload.c_str())) {
            Serial.println("Published payload successfully");
        } else {
            Serial.println("Failed to publish payload");
        }

        Serial.print("Published payload: ");
        Serial.println(payload);
    }
}