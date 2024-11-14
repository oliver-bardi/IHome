from fastapi import FastAPI
from app.mqtt_client import mqtt_client
from app.router import router

app = FastAPI()

# Egyesített API router hozzáadása
app.include_router(router)

# MQTT kliens indítása háttérben
@app.on_event("startup")
async def startup_event():
    mqtt_client.loop_start()

@app.on_event("shutdown")
async def shutdown_event():
    mqtt_client.loop_stop()
