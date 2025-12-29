from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime
import logging

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.trip import Trip as TripModel
from app.models.expense import Expense
from app.models.report import Report
from app.schemas.trip import Trip, TripCreate, TripUpdate, TripWithExpenses
from app.schemas.report import ReportResponse
from app.api.notifications import create_notification

router = APIRouter()
logger = logging.getLogger("uvicorn")


@router.get("/", response_model=List[Trip])
def get_trips(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Obtener todos los viajes (compartidos entre todos los usuarios)
    """
    query = db.query(TripModel)
    
    if status:
        query = query.filter(TripModel.status == status)
    
    trips = query.order_by(TripModel.start_date.desc()).offset(skip).limit(limit).all()
    return trips


@router.post("/", response_model=Trip)
def create_trip(
    trip: TripCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Crear un nuevo viaje
    """
    # Validar fechas
    if trip.end_date < trip.start_date:
        raise HTTPException(status_code=400, detail="La fecha de fin debe ser posterior a la fecha de inicio")
    
    db_trip = TripModel(
        **trip.model_dump(),
        user_id=current_user.id
    )
    db.add(db_trip)
    db.commit()
    db.refresh(db_trip)
    return db_trip


@router.get("/{trip_id}", response_model=TripWithExpenses)
def get_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Obtener un viaje por ID con sus gastos
    Los admins y managers pueden ver cualquier viaje
    """
    # Si es admin o manager, puede ver cualquier viaje
    if current_user.role.value in ["admin", "manager"]:
        trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
    else:
        # Los usuarios normales solo pueden ver sus propios viajes
        trip = db.query(TripModel).filter(
            TripModel.id == trip_id,
            TripModel.user_id == current_user.id
        ).first()
    
    if not trip:
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    return trip


@router.put("/{trip_id}", response_model=Trip)
def update_trip(
    trip_id: int,
    trip_update: TripUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Actualizar un viaje
    """
    db_trip = db.query(TripModel).filter(
        TripModel.id == trip_id,
        TripModel.user_id == current_user.id
    ).first()
    
    if not db_trip:
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    # Actualizar campos
    update_data = trip_update.model_dump(exclude_unset=True)
    
    # Validar fechas si se actualizan
    if "start_date" in update_data or "end_date" in update_data:
        start = update_data.get("start_date", db_trip.start_date)
        end = update_data.get("end_date", db_trip.end_date)
        if end < start:
            raise HTTPException(status_code=400, detail="La fecha de fin debe ser posterior a la fecha de inicio")
    
    for key, value in update_data.items():
        setattr(db_trip, key, value)
    
    db.commit()
    db.refresh(db_trip)
    return db_trip


@router.delete("/{trip_id}")
def delete_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Eliminar un viaje y todos sus gastos y reportes asociados
    """
    db_trip = db.query(TripModel).filter(
        TripModel.id == trip_id,
        TripModel.user_id == current_user.id
    ).first()
    
    if not db_trip:
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    # Eliminar reportes asociados al viaje (buscar por título que contenga el nombre del viaje)
    reports = db.query(Report).filter(
        Report.user_id == current_user.id,
        Report.title.like(f"%{db_trip.name}%")
    ).all()
    
    for report in reports:
        db.delete(report)
    
    # Eliminar gastos asociados al viaje
    db.query(Expense).filter(Expense.trip_id == trip_id).delete()
    
    # Eliminar el viaje
    db.delete(db_trip)
    db.commit()
    return {"message": "Viaje eliminado correctamente"}


@router.post("/{trip_id}/complete")
async def complete_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Marcar un viaje como completado y generar/actualizar reporte automáticamente
    Admin/Manager pueden completar cualquier viaje, usuarios solo los suyos
    """
    # Admin/Manager pueden completar cualquier viaje
    if current_user.role.value in ["admin", "manager"]:
        db_trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
        logger.info(f"✅ Admin/Manager completing trip {trip_id}")
    else:
        # Usuarios normales solo sus propios viajes
        db_trip = db.query(TripModel).filter(
            TripModel.id == trip_id,
            TripModel.user_id == current_user.id
        ).first()
        logger.info(f"👤 Employee completing own trip {trip_id}")
    
    if not db_trip:
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    # Obtener gastos del viaje
    expenses = db.query(Expense).filter(
        Expense.trip_id == trip_id,
        Expense.user_id == current_user.id
    ).all()
    
    # Buscar reporte existente para este viaje
    existing_report = db.query(Report).filter(
        Report.user_id == current_user.id,
        Report.title.like(f"%{db_trip.name}%")
    ).first()
    
    if expenses:
        # Calcular el total
        total_amount = sum(e.amount for e in expenses)
        
        if existing_report:
            # Actualizar reporte existente
            existing_report.total_amount = total_amount
            existing_report.updated_at = datetime.utcnow()
            
            # Asegurar que todos los gastos estén asociados al reporte
            for expense in expenses:
                expense.report_id = existing_report.id
        else:
            # Crear nuevo reporte
            report_title = f"Reporte - {db_trip.name}"
            report_description = f"Reporte generado automáticamente al completar el viaje '{db_trip.name}'"
            
            db_report = Report(
                user_id=current_user.id,
                title=report_title,
                description=report_description,
                status="draft",
                start_date=db_trip.start_date,
                end_date=db_trip.end_date,
                total_amount=total_amount,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            
            db.add(db_report)
            db.commit()
            db.refresh(db_report)
            
            # Asociar todos los gastos al reporte
            for expense in expenses:
                expense.report_id = db_report.id
    
    # Marcar viaje como completado
    db_trip.status = "completed"
    
    # Verificar si hay excedente de presupuesto y crear devolución
    if db_trip.budget and total_amount > db_trip.budget:
        from app.models.refund import Refund, RefundStatus
        from datetime import timedelta
        
        excess_amount = total_amount - db_trip.budget
        logger.info(f"💰 Budget exceeded: Budget=${db_trip.budget/100:.2f}, Spent=${total_amount/100:.2f}, Excess=${excess_amount/100:.2f}")
        
        # Verificar si ya existe una devolución para este viaje
        existing_refund = db.query(Refund).filter(Refund.trip_id == trip_id).first()
        
        if not existing_refund:
            # Crear devolución automáticamente
            refund = Refund(
                trip_id=trip_id,
                report_id=db_report.id if 'db_report' in locals() else (existing_report.id if existing_report else None),
                user_id=current_user.id,
                budget_amount=db_trip.budget,
                total_expenses=total_amount,
                excess_amount=excess_amount,
                due_date=datetime.utcnow() + timedelta(days=15),  # 15 días para devolver
                notes=f"Excedente de presupuesto generado al completar el viaje '{db_trip.name}'",
                status=RefundStatus.pending
            )
            db.add(refund)
            logger.info(f"📋 Refund created: Excess=${excess_amount/100:.2f}, Due in 15 days")
        else:
            logger.info(f"ℹ️ Refund already exists for trip {trip_id}")
    
    db.commit()
    db.refresh(db_trip)
    
    # Crear notificación para el usuario
    create_notification(
        db=db,
        user_id=current_user.id,
        title="Viaje completado",
        message=f"Tu viaje '{db_trip.name}' ha sido completado exitosamente.",
        notification_type="trip_completed",
        related_id=trip_id
    )
    
    # Retornar como diccionario para evitar problemas de serialización
    return {
        "id": db_trip.id,
        "user_id": db_trip.user_id,
        "name": db_trip.name,
        "destination": db_trip.destination,
        "start_date": db_trip.start_date.isoformat() if db_trip.start_date else None,
        "end_date": db_trip.end_date.isoformat() if db_trip.end_date else None,
        "description": db_trip.description,
        "budget": db_trip.budget,
        "status": db_trip.status,
        "created_at": db_trip.created_at.isoformat(),
        "updated_at": db_trip.updated_at.isoformat()
    }


@router.post("/{trip_id}/generate-report", response_model=ReportResponse)
def generate_report_from_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generar un reporte automáticamente con todos los gastos del viaje
    """
    # Verificar que el viaje existe y pertenece al usuario
    db_trip = db.query(TripModel).filter(
        TripModel.id == trip_id,
        TripModel.user_id == current_user.id
    ).first()
    
    if not db_trip:
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    # Obtener gastos del viaje
    expenses = db.query(Expense).filter(
        Expense.trip_id == trip_id,
        Expense.user_id == current_user.id
    ).all()
    
    if not expenses:
        raise HTTPException(status_code=400, detail="El viaje no tiene gastos para generar un reporte")
    
    # Verificar si ya existe un reporte para este viaje
    existing_report = db.query(Report).filter(
        Report.user_id == current_user.id,
        Report.title.like(f"%{db_trip.name}%")
    ).first()
    
    if existing_report:
        raise HTTPException(
            status_code=400, 
            detail=f"Ya existe un reporte para este viaje: '{existing_report.title}'"
        )
    
    # Crear el reporte
    report_title = f"Reporte - {db_trip.name}"
    report_description = f"Reporte generado automáticamente del viaje '{db_trip.name}' ({db_trip.start_date} a {db_trip.end_date})"
    
    # Calcular el total antes de crear el reporte
    total_amount = sum(e.amount for e in expenses)
    
    db_report = Report(
        user_id=current_user.id,
        title=report_title,
        description=report_description,
        status="draft",
        start_date=db_trip.start_date,
        end_date=db_trip.end_date,
        total_amount=total_amount,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    
    # Asociar todos los gastos al reporte
    for expense in expenses:
        expense.report_id = db_report.id
    
    db.commit()
    
    return db_report


@router.get("/{trip_id}/report", response_model=ReportResponse)
def get_trip_report(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Obtener el reporte asociado a un viaje
    Los admins y managers pueden ver reportes de cualquier viaje
    """
    import logging
    logger = logging.getLogger("uvicorn")
    
    logger.info(f"📄 GET /trips/{trip_id}/report - User: {current_user.email}, Role: {current_user.role.value}")
    
    # Si es admin o manager, puede ver cualquier viaje
    if current_user.role.value in ["admin", "manager"]:
        db_trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
        logger.info(f"✅ Admin/Manager access to trip {trip_id}")
    else:
        # Los usuarios normales solo pueden ver sus propios viajes
        db_trip = db.query(TripModel).filter(
            TripModel.id == trip_id,
            TripModel.user_id == current_user.id
        ).first()
        logger.info(f"👤 Employee access, checking ownership")
    
    if not db_trip:
        logger.error(f"❌ Trip {trip_id} not found")
        raise HTTPException(status_code=404, detail="Viaje no encontrado")
    
    logger.info(f"🔍 Found trip: '{db_trip.name}', searching for report...")
    
    # Buscar reportes que tengan gastos de este viaje
    expenses_with_report = db.query(Expense).filter(
        Expense.trip_id == trip_id,
        Expense.report_id != None
    ).first()
    
    if expenses_with_report and expenses_with_report.report_id:
        logger.info(f"💡 Found expense with report_id={expenses_with_report.report_id}")
        report = db.query(Report).filter(Report.id == expenses_with_report.report_id).first()
        if report:
            logger.info(f"✅ Report found! ID={report.id}, Title='{report.title}'")
            # Calcular totales
            expenses = db.query(Expense).filter(Expense.report_id == report.id).all()
            report.expense_count = len(expenses)
            report.total_amount = sum(e.amount for e in expenses)
            return report
        else:
            logger.warning(f"⚠️ Report ID {expenses_with_report.report_id} referenced but not found in DB")
    else:
        logger.info(f"ℹ️ No expenses with report_id found for trip {trip_id}")
    
    # Si no se encontró por gastos, buscar por título como fallback
    logger.info(f"🔎 Searching by title containing '{db_trip.name}'")
    report = db.query(Report).filter(
        Report.title.ilike(f"%{db_trip.name}%")
    ).first()
    
    if report:
        logger.info(f"✅ Report found by title! ID={report.id}, Title='{report.title}'")
        # Calcular totales
        expenses = db.query(Expense).filter(Expense.report_id == report.id).all()
        report.expense_count = len(expenses)
        report.total_amount = sum(e.amount for e in expenses)
        return report
    
    logger.error(f"❌ No report found for trip {trip_id} ('{db_trip.name}')")
    raise HTTPException(status_code=404, detail="Este viaje no tiene un reporte asociado")
