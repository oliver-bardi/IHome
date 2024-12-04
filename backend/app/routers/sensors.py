from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import SensorReading

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/sensors/")
def get_sensor_data(db: Session = Depends(get_db)):
    return db.query(SensorReading).all()
