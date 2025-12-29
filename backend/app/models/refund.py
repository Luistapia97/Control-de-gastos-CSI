"""
Refund Model - Devoluciones por excedentes de presupuesto
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.core.database import Base

class RefundStatus(str, enum.Enum):
    pending = "pending"           # Pendiente de devolución
    partial = "partial"           # Parcialmente devuelto
    completed = "completed"       # Completamente devuelto
    waived = "waived"            # Exonerado por administrador
    disputed = "disputed"         # En disputa
    overdue = "overdue"          # Vencido

class RefundMethod(str, enum.Enum):
    cash = "cash"                # Efectivo
    transfer = "transfer"        # Transferencia bancaria
    payroll = "payroll"          # Descuento de nómina
    check = "check"              # Cheque
    other = "other"              # Otro

class Refund(Base):
    __tablename__ = "refunds"
    
    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=False)
    report_id = Column(Integer, ForeignKey("reports.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Montos (en centavos)
    budget_amount = Column(Integer, nullable=False, comment="Presupuesto original")
    total_expenses = Column(Integer, nullable=False, comment="Total gastado")
    excess_amount = Column(Integer, nullable=False, comment="Excedente a devolver")
    refunded_amount = Column(Integer, default=0, comment="Monto ya devuelto")
    
    # Estado y método
    status = Column(SQLEnum(RefundStatus), default=RefundStatus.pending, nullable=False)
    refund_method = Column(SQLEnum(RefundMethod), nullable=True)
    
    # Fechas
    due_date = Column(DateTime, nullable=True, comment="Fecha límite para devolver")
    completed_date = Column(DateTime, nullable=True)
    
    # Notas
    notes = Column(Text, comment="Notas del usuario")
    admin_notes = Column(Text, comment="Notas del administrador")
    waive_reason = Column(Text, comment="Razón de exoneración")
    
    # Comprobantes
    receipt_url = Column(String(500), comment="URL del comprobante de devolución")
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    trip = relationship("Trip", back_populates="refund")
    report = relationship("Report", back_populates="refund")
    user = relationship("User", back_populates="refunds")
    
    @property
    def remaining_amount(self):
        """Calcula el monto restante a devolver"""
        return self.excess_amount - self.refunded_amount
    
    @property
    def is_overdue(self):
        """Verifica si la devolución está vencida"""
        if self.due_date and self.status == RefundStatus.pending:
            return datetime.utcnow() > self.due_date
        return False
    
    @property
    def refund_percentage(self):
        """Calcula el porcentaje devuelto"""
        if self.excess_amount > 0:
            return (self.refunded_amount / self.excess_amount) * 100
        return 0
