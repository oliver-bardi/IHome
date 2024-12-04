import paho.mqtt.client as mqtt

BROKER = "mqtt-broker"
PORT = 1883

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
        client.subscribe("home/status")
        client.subscribe("home/switch/+/set")
    else:
        print(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    print(f"Received message on {msg.topic}: {msg.payload.decode()}")

def init_mqtt():
    client = mqtt.Client("BackendClient")
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(BROKER, PORT, 60)
    return client
