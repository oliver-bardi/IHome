# backend/app/main.py

from fastapi import FastAPI
from .router import router
from .mqtt_client import start_mqtt_client
import threading

app = FastAPI()

# API végpontok hozzáadása
app.include_router(router)

def run_mqtt_client():
    start_mqtt_client()

# MQTT kliens futtatása háttérszálban
mqtt_thread = threading.Thread(target=run_mqtt_client)
mqtt_thread.start()
