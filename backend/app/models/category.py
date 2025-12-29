"""
Category Model
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(String(255), nullable=True)
    icon = Column(String(50), nullable=True)  # Emoji o nombre de icono
    color = Column(String(20), nullable=True)  # Color hex
    is_active = Column(Boolean, default=True)
    
    # Límites de gasto (opcional)
    max_amount = Column(Integer, nullable=True)  # En centavos
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    expenses = relationship("Expense", back_populates="category")
