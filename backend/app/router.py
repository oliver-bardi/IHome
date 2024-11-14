# backend/app/router.py

from fastapi import APIRouter, HTTPException
from .mqtt_client import publish_message, get_last_status

router = APIRouter()

@router.post("/control")
async def control_device(switch_id: int, action: str):
    """
    Switch vezérlése.
    - switch_id: Az ESP32 kapcsolójának azonosítója.
    - action: "ON" vagy "OFF", a kapcsoló állapota.
    """
    topic = f"home/switch/{switch_id}/set"
    if action not in ["ON", "OFF"]:
        raise HTTPException(status_code=400, detail="Invalid action")

    # MQTT üzenet küldése
    publish_message(topic, action)
    return {"status": "success", "message": f"Switch {switch_id} set to {action}"}

@router.get("/status")
async def get_status():
    """
    Az ESP32 legutóbbi állapotának lekérdezése.
    """
    status = get_last_status()
    return {"status": "success", "data": status}
