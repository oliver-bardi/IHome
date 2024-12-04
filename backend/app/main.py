from fastapi import FastAPI
from app.database import Base, engine
from app.mqtt_client import init_mqtt
from app.routers import sensors, switches  # Import frissítése routers mappára

Base.metadata.create_all(bind=engine)

app = FastAPI()

mqtt_client = init_mqtt()

@app.on_event("startup")
def startup_event():
    import threading
    threading.Thread(target=mqtt_client.loop_forever).start()

@app.on_event("shutdown")
def shutdown_event():
    mqtt_client.disconnect()

app.include_router(sensors.router, prefix="/api")
app.include_router(switches.router, prefix="/api")
