"""
Refund API Endpoints - Gestión de devoluciones por excedentes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_manager_or_admin
from app.models.user import User
from app.models.refund import Refund, RefundStatus, RefundMethod
from app.models.trip import Trip
from app.schemas.refund import (
    RefundResponse,
    RefundCreate,
    RefundUpdate,
    RefundRecordPayment,
    RefundConfirm,
    RefundWaive,
    RefundWithDetails
)
from app.api.notifications import create_notification

router = APIRouter()
logger = logging.getLogger("uvicorn")

@router.get("/", response_model=List[RefundResponse])
async def get_refunds(
    status: Optional[str] = None,
    user_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtener lista de devoluciones
    - Usuarios normales solo ven sus propias devoluciones
    - Admins/managers ven todas
    """
    logger.info(f"📋 GET /refunds/ - User: {current_user.email}, Role: {current_user.role.value}")
    
    # Si es admin o manager, puede ver todas las devoluciones
    if current_user.role.value in ["admin", "manager"]:
        query = db.query(Refund)
        logger.info("✅ Admin/Manager query (all refunds)")
    else:
        # Los usuarios normales solo ven sus propias devoluciones
        query = db.query(Refund).filter(Refund.user_id == current_user.id)
        logger.info(f"👤 Employee query (user_id={current_user.id})")
    
    # Filtros
    if status:
        query = query.filter(Refund.status == status)
    
    if user_id and current_user.role.value in ["admin", "manager"]:
        query = query.filter(Refund.user_id == user_id)
    
    refunds = query.order_by(Refund.created_at.desc()).offset(skip).limit(limit).all()
    
    # Agregar información adicional
    for refund in refunds:
        refund.trip_name = refund.trip.name if refund.trip else None
        refund.user_name = refund.user.full_name if refund.user else None
        refund.user_email = refund.user.email if refund.user else None
        
        # Actualizar status si está vencida
        if refund.is_overdue and refund.status == RefundStatus.PENDING:
            refund.status = RefundStatus.OVERDUE
    
    db.commit()
    logger.info(f"📊 Found {len(refunds)} refunds")
    
    return refunds

@router.get("/{refund_id}", response_model=RefundWithDetails)
async def get_refund(
    refund_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtener detalles de una devolución específica
    """
    logger.info(f"🔍 GET /refunds/{refund_id} - User: {current_user.email}")
    
    # Buscar devolución
    if current_user.role.value in ["admin", "manager"]:
        refund = db.query(Refund).filter(Refund.id == refund_id).first()
    else:
        refund = db.query(Refund).filter(
            Refund.id == refund_id,
            Refund.user_id == current_user.id
        ).first()
    
    if not refund:
        logger.error(f"❌ Refund {refund_id} not found")
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    # Agregar información adicional
    refund.trip_name = refund.trip.name if refund.trip else None
    refund.user_name = refund.user.full_name if refund.user else None
    refund.user_email = refund.user.email if refund.user else None
    
    # Actualizar status si está vencida
    if refund.is_overdue and refund.status == RefundStatus.pending:
        refund.status = RefundStatus.overdue
        db.commit()
    
    logger.info(f"✅ Refund found: ID={refund.id}, Status={refund.status}")
    return refund

@router.post("/{refund_id}/record-payment", response_model=RefundResponse)
async def record_payment(
    refund_id: int,
    payment: RefundRecordPayment,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Usuario registra un pago de devolución
    """
    logger.info(f"💰 POST /refunds/{refund_id}/record-payment - User: {current_user.email}, Amount: {payment.amount}")
    
    # Buscar devolución (solo la propia)
    # Permitir que admin/manager puedan registrar pagos en cualquier devolución
    if current_user.role in ["admin", "manager"]:
        refund = db.query(Refund).filter(Refund.id == refund_id).first()
    else:
        refund = db.query(Refund).filter(
            Refund.id == refund_id,
            Refund.user_id == current_user.id
        ).first()
    if not refund:
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    if refund.status not in [RefundStatus.pending, RefundStatus.partial, RefundStatus.overdue]:
        raise HTTPException(
            status_code=400,
            detail=f"No se puede registrar pago para devolución en estado {refund.status}"
        )
    
    # Validar monto
    if payment.amount > refund.remaining_amount:
        raise HTTPException(
            status_code=400,
            detail=f"El monto a devolver (${payment.amount/100:.2f}) excede el monto pendiente (${refund.remaining_amount/100:.2f})"
        )
    
    # Registrar pago
    refund.refunded_amount += payment.amount
    refund.refund_method = payment.refund_method
    if payment.notes:
        refund.notes = payment.notes
    if payment.receipt_url:
        refund.receipt_url = payment.receipt_url
    
    # Actualizar estado
    if refund.refunded_amount >= refund.excess_amount:
        refund.status = RefundStatus.completed
        refund.completed_date = datetime.utcnow()
        logger.info("✅ Refund marked as COMPLETED (awaiting admin confirmation)")
    else:
        refund.status = RefundStatus.partial
        logger.info(f"📊 Partial payment recorded: {refund.refund_percentage:.1f}% completed")
    
    refund.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(refund)
    
    # Agregar info adicional
    refund.trip_name = refund.trip.name if refund.trip else None
    refund.user_name = refund.user.full_name if refund.user else None
    refund.user_email = refund.user.email if refund.user else None
    
    logger.info(f"💵 Payment recorded: ${payment.amount/100:.2f}, New status: {refund.status}")
    # Notificar al usuario de la devolución
    create_notification(
        db=db,
        user_id=refund.user_id,
        title="Pago registrado en devolución",
        message=f"Se ha registrado un pago de ${payment.amount/100:.2f} en tu devolución. Estado actual: {refund.status}.",
        notification_type="refund_payment",
        related_id=refund.id
    )
    return refund

@router.post("/{refund_id}/confirm", response_model=RefundResponse)
async def confirm_refund(
    refund_id: int,
    confirmation: RefundConfirm,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Admin confirma recepción de devolución (ADMIN/MANAGER only)
    """
    logger.info(f"✅ POST /refunds/{refund_id}/confirm - Admin: {current_user.email}")
    
    refund = db.query(Refund).filter(Refund.id == refund_id).first()
    
    if not refund:
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    if refund.status != RefundStatus.completed:
        raise HTTPException(
            status_code=400,
            detail=f"Solo se pueden confirmar devoluciones completadas (estado actual: {refund.status})"
        )
    
    # Confirmar
    if confirmation.admin_notes:
        refund.admin_notes = confirmation.admin_notes
    refund.completed_date = datetime.utcnow()
    refund.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(refund)
    
    # Crear notificación
    create_notification(
        db=db,
        user_id=refund.user_id,
        title="Devolución confirmada",
        message=f"Tu devolución de ${refund.excess_amount:.2f} ha sido confirmada.",
        notification_type="refund_confirmed",
        related_id=refund_id
    )
    
    # Agregar info adicional
    refund.trip_name = refund.trip.name if refund.trip else None
    refund.user_name = refund.user.full_name if refund.user else None
    refund.user_email = refund.user.email if refund.user else None
    
    logger.info(f"✅ Refund confirmed by admin: {current_user.email}")
    return refund

@router.post("/{refund_id}/waive", response_model=RefundResponse)
async def waive_refund(
    refund_id: int,
    waive: RefundWaive,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Admin exonera una devolución (ADMIN/MANAGER only)
    """
    logger.info(f"🎁 POST /refunds/{refund_id}/waive - Admin: {current_user.email}")
    
    refund = db.query(Refund).filter(Refund.id == refund_id).first()
    
    if not refund:
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    if refund.status == RefundStatus.waived:
        raise HTTPException(status_code=400, detail="Esta devolución ya fue exonerada")
    
    # Exonerar
    refund.status = RefundStatus.waived
    refund.waive_reason = waive.waive_reason
    if waive.admin_notes:
        refund.admin_notes = waive.admin_notes
    refund.completed_date = datetime.utcnow()
    refund.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(refund)
    
    # Crear notificación
    create_notification(
        db=db,
        user_id=refund.user_id,
        title="Devolución exonerada",
        message=f"Tu devolución de ${refund.excess_amount:.2f} ha sido exonerada. {waive.waive_reason or ''}",
        notification_type="refund_waived",
        related_id=refund_id
    )
    
    # Agregar info adicional
    refund.trip_name = refund.trip.name if refund.trip else None
    refund.user_name = refund.user.full_name if refund.user else None
    refund.user_email = refund.user.email if refund.user else None
    
    logger.info(f"🎁 Refund waived by admin: {current_user.email}, Reason: {waive.waive_reason[:50]}...")
    return refund

@router.put("/{refund_id}", response_model=RefundResponse)
async def update_refund(
    refund_id: int,
    refund_update: RefundUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Actualizar notas de una devolución
    """
    # Buscar devolución (solo la propia si no es admin)
    if current_user.role.value in ["admin", "manager"]:
        refund = db.query(Refund).filter(Refund.id == refund_id).first()
    else:
        refund = db.query(Refund).filter(
            Refund.id == refund_id,
            Refund.user_id == current_user.id
        ).first()
    
    if not refund:
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    # Actualizar campos
    if refund_update.notes is not None:
        refund.notes = refund_update.notes
    if refund_update.refund_method is not None:
        refund.refund_method = refund_update.refund_method
    if refund_update.receipt_url is not None:
        refund.receipt_url = refund_update.receipt_url
    
    refund.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(refund)
    
    # Agregar info adicional
    refund.trip_name = refund.trip.name if refund.trip else None
    refund.user_name = refund.user.full_name if refund.user else None
    refund.user_email = refund.user.email if refund.user else None
    
    return refund

@router.delete("/{refund_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_refund(
    refund_id: int,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Eliminar una devolución (ADMIN/MANAGER only)
    """
    refund = db.query(Refund).filter(Refund.id == refund_id).first()
    
    if not refund:
        raise HTTPException(status_code=404, detail="Devolución no encontrada")
    
    db.delete(refund)
    db.commit()
    
    logger.info(f"🗑️ Refund {refund_id} deleted by admin: {current_user.email}")
    return None
