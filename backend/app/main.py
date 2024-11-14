from fastapi import FastAPI
from app.mqtt_client import start_mqtt_client
import threading

app = FastAPI()  # FastAPI alkalmazás létrehozása

# MQTT kliens külön szálon történő indítása
def run_mqtt_client():
    start_mqtt_client()

# Alkalmazás indulásakor indítjuk az MQTT klienst
@app.on_event("startup")
def startup_event():
    threading.Thread(target=run_mqtt_client, daemon=True).start()

@app.get("/")
async def read_root():
    return {"message": "Hello, FastAPI with MQTT!"}
