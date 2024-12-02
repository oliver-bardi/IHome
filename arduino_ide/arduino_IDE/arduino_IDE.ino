#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

#define DHTTYPE DHT11 // DHT 11 típus

// Definiáljuk a DHT szenzorokat (például a pin-eket 2-től 6-ig)
const int DHT_PINS[5] = {2, 3, 4, 5, 6}; // Az 5 DHT11 szenzor pinjei
DHT dhtSensors[5] = {
    DHT(DHT_PINS[0], DHTTYPE),
    DHT(DHT_PINS[1], DHTTYPE),
    DHT(DHT_PINS[2], DHTTYPE),
    DHT(DHT_PINS[3], DHTTYPE),
    DHT(DHT_PINS[4], DHTTYPE)
};

// Definiáljuk a 15 relé (kapcsoló) pineit
const int RELAY_PINS[15] = {12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32};

const char* ssid = "FRANKIE 9564";         // Wi-Fi SSID
const char* password = "y008<D19";          // Wi-Fi jelszó
const char* mqtt_server = "192.168.137.1";  // MQTT Broker IP

WiFiClient espClient;
PubSubClient client(espClient);

// Kapcsoló állapotok (alapértelmezésben OFF)
bool switchStates[15] = {false}; // Mind OFF állapotban kezdetben

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

    // Kapcsoló állapotainak kezelése
    if (String(topic).startsWith("home/switch/")) {
        int switchIndex = String(topic).substring(12).toInt(); // Kapcsoló sorszámának kiszedése a témából

        // Kapcsoló index ellenőrzése
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

            // Kapcsoló parancsok feliratkozása wildcard-dal
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

    // Minden szenzor inicializálása
    for (int i = 0; i < 5; i++) {
        dhtSensors[i].begin();
    }

    // Kapcsoló pin-ek inicializálása
    for (int i = 0; i < 15; i++) {
        pinMode(RELAY_PINS[i], OUTPUT);
        digitalWrite(RELAY_PINS[i], LOW); // Minden relé alaphelyzetben OFF
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

        // JSON üzenet készítése a szenzor adatokkal és kapcsoló állapotokkal
        String payload = "{";

        // Mind az 5 szenzor adatainak hozzáadása
        payload += "\"sensors\":{";
        for (int i = 0; i < 5; i++) {
            float humidity = dhtSensors[i].readHumidity();
            float temperature = dhtSensors[i].readTemperature();

            if (!isnan(humidity) && !isnan(temperature)) {
                payload += "\"sensor" + String(i) + "\":{\"temperature\":" + String(temperature) + ",\"humidity\":" + String(humidity) + "}";
                if (i < 4) payload += ","; // Vessző, ha nem az utolsó elem
            } else {
                Serial.println("Error reading from DHT sensor " + String(i) + "!");
            }
        }
        payload += "},";

        // Kapcsolók állapotainak hozzáadása
        payload += "\"switchStates\":{";
        bool first = true; // Vessző kezelése
        for (int i = 0; i < 15; i++) {
            if (switchStates[i]) { // Csak az ON állapotú kapcsolókat küldjük
                if (!first) payload += ","; // Vessző a kapcsolók között
                payload += "\"switch" + String(i) + "\":\"ON\"";
                first = false;
            }
        }
        payload += "}}"; // Záró JSON objektumok

        // JSON üzenet publikálása
        if (client.publish("home/status", payload.c_str())) {
            Serial.println("Published payload successfully");
        } else {
            Serial.println("Failed to publish payload");
        }

        Serial.print("Published payload: ");
        Serial.println(payload);
    }
}