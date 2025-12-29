"""
Approval Model - Historial de aprobaciones/rechazos
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class Approval(Base):
    __tablename__ = "approvals"
    
    id = Column(Integer, primary_key=True, index=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=False)
    approver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Decisión
    approved = Column(Integer, nullable=False)  # 1=aprobado, 0=rechazado
    comments = Column(Text, nullable=True)
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    report = relationship("Report", back_populates="approvals")
    approver = relationship("User", foreign_keys=[approver_id], back_populates="approvals")
