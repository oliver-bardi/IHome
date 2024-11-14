import paho.mqtt.client as mqtt
import json
import os

# MQTT Broker beállításai
MQTT_BROKER = "mqtt"
MQTT_PORT = 1883
MQTT_TOPIC = "home/status"

# Kapcsolódáskor meghívott függvény
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
        client.subscribe(MQTT_TOPIC)
    else:
        print(f"Failed to connect, return code {rc}")

# Üzenet érkezésekor meghívott függvény
def on_message(client, userdata, msg):
    print("Message received on topic:", msg.topic)
    try:
        # JSON payload dekódolása
        payload = json.loads(msg.payload.decode())
        print("Payload received:")

        # Kiírás a hőmérséklet- és páratartalom-értékekre
        print(f"  Temperature Sensor 1: {payload.get('temperature1', 'N/A')} °C")
        print(f"  Humidity Sensor 1: {payload.get('humidity1', 'N/A')} %")
        print(f"  Temperature Sensor 2: {payload.get('temperature2', 'N/A')} °C")
        print(f"  Humidity Sensor 2: {payload.get('humidity2', 'N/A')} %")

        # Kapcsolók állapotainak kiírása
        switch_states = payload.get("switchStates", {})
        if switch_states:
            print("  Switch States:")
            for switch, state in switch_states.items():
                print(f"    {switch}: {state}")
        else:
            print("  No switches are ON.")

    except json.JSONDecodeError:
        print("Failed to decode JSON payload")

# MQTT kliens indítása
def start_mqtt_client():
    client = mqtt.Client("BackendClient")
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_forever()
