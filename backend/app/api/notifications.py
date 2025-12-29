"""
Notifications API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List
from pydantic import BaseModel
from datetime import datetime

from app.core.database import get_db
from app.models.notification import Notification
from app.models.user import User
from app.core.dependencies import get_current_user

router = APIRouter()

# Response Models
class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    type: str
    related_id: int | None
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class UnreadCountResponse(BaseModel):
    unread_count: int

@router.get("/", response_model=List[NotificationResponse])
async def get_notifications(
    skip: int = 0,
    limit: int = 50,
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Obtener notificaciones del usuario actual
    """
    query = db.query(Notification).filter(
        Notification.user_id == current_user.id
    )
    
    if unread_only:
        query = query.filter(Notification.is_read == False)
    
    notifications = query.order_by(desc(Notification.created_at))\
        .offset(skip).limit(limit).all()
    
    return notifications

@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Obtener contador de notificaciones no leídas
    """
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    
    return {"unread_count": count}

@router.put("/{notification_id}/read")
async def mark_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Marcar notificación como leída
    """
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    
    notification.is_read = True
    db.commit()
    
    return {"message": "Notificación marcada como leída"}

@router.put("/mark-all-read")
async def mark_all_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Marcar todas las notificaciones como leídas
    """
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).update({"is_read": True})
    
    db.commit()
    
    return {"message": "Todas las notificaciones marcadas como leídas"}

@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Eliminar notificación
    """
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    
    db.delete(notification)
    db.commit()
    
    return {"message": "Notificación eliminada"}


# Helper function para crear notificaciones (usada por otros módulos)
def create_notification(
    db: Session,
    user_id: int,
    title: str,
    message: str,
    notification_type: str,
    related_id: int | None = None
):
    """
    Crear una nueva notificación para un usuario
    """
    notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        type=notification_type,
        related_id=related_id
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification
