# backend/app/mqtt_client.py

import paho.mqtt.client as mqtt
import json

MQTT_BROKER = "mqtt"  # MQTT Broker Docker név
MQTT_PORT = 1883
MQTT_TOPIC_STATUS = "home/status"

status_data = {}  # Az ESP32 legutóbbi állapotának tárolására

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
        client.subscribe(MQTT_TOPIC_STATUS)
    else:
        print(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    global status_data
    print(f"Message received on topic {msg.topic}")
    try:
        payload = json.loads(msg.payload.decode())
        print("Payload:", json.dumps(payload, indent=4))
        status_data = payload  # Legutóbbi státusz elmentése
    except json.JSONDecodeError:
        print("Failed to decode JSON payload")

def get_last_status():
    return status_data

def publish_message(topic, message):
    client.publish(topic, message)

# MQTT kliens beállítása és futtatása
client = mqtt.Client("BackendClient")
client.on_connect = on_connect
client.on_message = on_message

def start_mqtt_client():
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_forever()
