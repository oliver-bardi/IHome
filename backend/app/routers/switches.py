from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import SwitchState

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/switches/")
def get_switch_states(db: Session = Depends(get_db)):
    return db.query(SwitchState).all()
