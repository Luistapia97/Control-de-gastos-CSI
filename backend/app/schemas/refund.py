"""
Refund Schemas - Pydantic schemas para devoluciones
"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class RefundBase(BaseModel):
    notes: Optional[str] = None

class RefundCreate(RefundBase):
    trip_id: int
    report_id: Optional[int] = None
    budget_amount: int
    total_expenses: int
    excess_amount: int
    due_date: Optional[datetime] = None

class RefundUpdate(BaseModel):
    notes: Optional[str] = None
    refund_method: Optional[str] = None
    receipt_url: Optional[str] = None

class RefundRecordPayment(BaseModel):
    amount: int = Field(..., gt=0, description="Monto devuelto en centavos")
    refund_method: str = Field(..., description="Método de devolución")
    notes: Optional[str] = None
    receipt_url: Optional[str] = None

class RefundConfirm(BaseModel):
    admin_notes: Optional[str] = None

class RefundWaive(BaseModel):
    waive_reason: str = Field(..., min_length=10, description="Razón de exoneración")
    admin_notes: Optional[str] = None

class RefundResponse(RefundBase):
    id: int
    trip_id: int
    report_id: Optional[int]
    user_id: int
    
    budget_amount: int
    total_expenses: int
    excess_amount: int
    refunded_amount: int
    remaining_amount: int
    refund_percentage: float
    
    status: str
    refund_method: Optional[str]
    
    due_date: Optional[datetime]
    completed_date: Optional[datetime]
    is_overdue: bool
    
    notes: Optional[str]
    admin_notes: Optional[str]
    waive_reason: Optional[str]
    receipt_url: Optional[str]
    
    created_at: datetime
    updated_at: datetime
    
    # Datos relacionados
    trip_name: Optional[str] = None
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    
    class Config:
        from_attributes = True

class RefundWithDetails(RefundResponse):
    """Refund con información completa del viaje y usuario"""
    pass
