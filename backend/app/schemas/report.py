"""
Pydantic Schemas for Reports
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ReportBase(BaseModel):
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

class ReportCreate(ReportBase):
    pass

class ReportUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

class ReportResponse(ReportBase):
    id: int
    user_id: int
    status: str
    total_amount: int = Field(default=0, description="Total amount in cents")
    expense_count: int = Field(default=0, description="Number of expenses")
    submitted_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class ReportWithExpenses(ReportResponse):
    """Report with list of expenses included"""
    expenses: List = []  # Will be populated with ExpenseResponse objects
