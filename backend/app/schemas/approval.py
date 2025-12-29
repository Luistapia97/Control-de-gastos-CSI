"""
Pydantic Schemas for Approvals
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ApprovalRequest(BaseModel):
    """Request body for approve/reject actions"""
    comments: Optional[str] = None

class ApprovalResponse(BaseModel):
    """Response from approval/rejection"""
    id: int
    report_id: int
    approver_id: int
    approved: int  # 1=approved, 0=rejected
    comments: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True
