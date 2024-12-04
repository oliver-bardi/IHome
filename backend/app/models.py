from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class SensorReading(Base):
    __tablename__ = 'readings'
    id = Column(Integer, primary_key=True, index=True)
    sensor_id = Column(String(50), nullable=False)
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    recorded_at = Column(DateTime, default=datetime.utcnow)

class SwitchState(Base):
    __tablename__ = 'switch_states'
    id = Column(Integer, primary_key=True, index=True)
    switch_id = Column(Integer, nullable=False)
    state = Column(String(10), nullable=False)
