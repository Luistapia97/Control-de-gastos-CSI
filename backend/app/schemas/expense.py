"""
Pydantic Schemas for Expenses
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class ExpenseBase(BaseModel):
    category_id: int
    amount: int = Field(..., description="Amount in cents")
    currency: str = Field(default="USD", max_length=3)
    merchant: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    expense_date: datetime
    trip_id: Optional[int] = None

class ExpenseCreate(ExpenseBase):
    receipt_url: Optional[str] = None
    ocr_data: Optional[str] = None
    ocr_confidence: Optional[int] = None

class ExpenseUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[int] = None
    merchant: Optional[str] = None
    description: Optional[str] = None
    expense_date: Optional[datetime] = None
    status: Optional[str] = None
    trip_id: Optional[int] = None

class ExpenseResponse(ExpenseBase):
    id: int
    user_id: int
    report_id: Optional[int]
    trip_id: Optional[int]
    receipt_url: Optional[str]
    receipt_original_name: Optional[str]
    ocr_data: Optional[str]
    ocr_confidence: Optional[int]
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class OCRScanResponse(BaseModel):
    """Response from OCR scan endpoint"""
    merchant: Optional[str]
    amount: Optional[float]
    date: Optional[str]
    confidence: int
    raw_text: str
    receipt_url: str
    
    suggested_expense: Optional[dict] = None
