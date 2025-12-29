from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base


class Trip(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)  # Ej: "Viaje a Madrid"
    destination = Column(String, nullable=True)  # Ciudad/país destino
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    description = Column(String, nullable=True)
    budget = Column(Integer, nullable=True)  # Presupuesto en centavos
    status = Column(String, default="active")  # active, completed, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="trips")
    expenses = relationship("Expense", back_populates="trip", cascade="all, delete-orphan")
    refund = relationship("Refund", back_populates="trip", uselist=False, cascade="all, delete-orphan")
