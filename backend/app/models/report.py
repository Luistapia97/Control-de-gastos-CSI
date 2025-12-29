"""
Report Model - Agrupación de gastos para aprobación
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.core.database import Base

class ReportStatus(str, enum.Enum):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    APPROVED = "approved"
    REJECTED = "rejected"
    PAID = "paid"

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Datos del reporte
    title = Column(String(255), nullable=False)
    description = Column(String(500), nullable=True)
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    total_amount = Column(Integer, default=0)  # Suma de gastos en centavos
    currency = Column(String(3), default="USD")
    
    # Estado y fechas
    status = Column(SQLEnum(ReportStatus), default=ReportStatus.DRAFT, nullable=False)
    submitted_at = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="reports")
    expenses = relationship("Expense", back_populates="report")
    refund = relationship("Refund", back_populates="report", uselist=False, cascade="all, delete-orphan")
    approvals = relationship("Approval", back_populates="report", cascade="all, delete-orphan")
