from fastapi import APIRouter, HTTPException
from app.db import get_status_from_db, update_status_in_db
from app.mqtt_client import mqtt_client

router = APIRouter()

# Egységes API végpont a vezérléshez
@router.post("/api/control/{module}")
async def control_device(module: str, state: str):
    if module not in ["lighting", "heating", "security", "watering"]:
        raise HTTPException(status_code=400, detail="Invalid module name")

    mqtt_client.publish(f"home/{module}/control", state)
    update_status_in_db(module, state)
    return {"message": f"{module.capitalize()} control command sent", "state": state}

# Egységes API végpont az állapot lekérdezéséhez
@router.get("/api/status/{module}")
async def get_device_status(module: str):
    if module not in ["lighting", "heating", "security", "watering"]:
        raise HTTPException(status_code=400, detail="Invalid module name")

    status = get_status_from_db(module)
    return {"status": status}
