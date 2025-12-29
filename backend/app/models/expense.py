"""
Expense Model
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.core.database import Base

class ExpenseStatus(str, enum.Enum):
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class Expense(Base):
    __tablename__ = "expenses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=True)
    
    # Datos del gasto
    amount = Column(Integer, nullable=False)  # En centavos para precisión
    currency = Column(String(3), default="USD", nullable=False)
    merchant = Column(String(255), nullable=True)  # Comercio/Proveedor
    description = Column(Text, nullable=True)
    expense_date = Column(DateTime, nullable=False)
    
    # OCR y recibo
    receipt_url = Column(String(500), nullable=True)
    receipt_original_name = Column(String(255), nullable=True)
    ocr_data = Column(Text, nullable=True)  # JSON con datos extraídos
    ocr_confidence = Column(Integer, nullable=True)  # 0-100
    
    # Estado
    status = Column(SQLEnum(ExpenseStatus), default=ExpenseStatus.DRAFT, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="expenses")
    category = relationship("Category", back_populates="expenses")
    report = relationship("Report", back_populates="expenses")
    trip = relationship("Trip", back_populates="expenses")
