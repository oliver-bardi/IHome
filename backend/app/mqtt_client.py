import paho.mqtt.client as mqtt
from app.db import update_status_in_db
import os
import paho.mqtt.client as mqtt

mqtt_client = mqtt.Client()
mqtt_client.connect(
    host=os.getenv("MQTT_HOST", "localhost"),
    port=int(os.getenv("MQTT_PORT", 1883))
)


# Üzenetkezelő függvény az összes modulhoz
def on_message(client, userdata, msg):
    module = msg.topic.split('/')[1]  # Például 'lighting', 'heating'
    status = msg.payload.decode()
    update_status_in_db(module, status)

mqtt_client.on_message = on_message
mqtt_client.subscribe("home/+/status")
