#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

#define DHTPIN 2         // Pin where the DHT11 is connected
#define DHTTYPE DHT11    // DHT 11

// Define pins for relays (switches)
const int RELAY_PINS[19] = {4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34};

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "FRANKIE 9564";   // Your Wi-Fi SSID
const char* password = "y008<D19";    // Your Wi-Fi Password
const char* mqtt_server = "192.168.137.1"; // MQTT Broker IP

WiFiClient espClient;
PubSubClient client(espClient);

// Array to hold the state of each switch (default OFF)
bool switchStates[19] = {false}; // All switches off initially

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
        if (switchIndex >= 0 && switchIndex < 19) {
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
    dht.begin();

    // Initialize relay pins
    for (int i = 0; i < 19; i++) {
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

        // Read sensor data
        float humidity = dht.readHumidity();
        float temperature = dht.readTemperature();

        if (isnan(humidity) || isnan(temperature)) {
            Serial.println("Error reading from DHT sensor!");
            return;
        }

        // Create a JSON payload with sensor data and ON switch states only
        String payload = "{";
        payload += "\"temperature\": " + String(temperature) + ",";
        payload += "\"humidity\": " + String(humidity) + ",";
        payload += "\"switchStates\":{";

        bool first = true; // Flag to handle commas
        for (int i = 0; i < 19; i++) {
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