"""
API Routes - Reports
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_manager_or_admin
from app.models import Report, Expense, User, Approval
from app.schemas import (
    ReportCreate, 
    ReportUpdate, 
    ReportResponse, 
    ReportWithExpenses, 
    ExpenseResponse,
    ApprovalRequest,
    ApprovalResponse
)
from app.api.notifications import create_notification

router = APIRouter()

@router.get("/", response_model=List[ReportResponse])
async def get_reports(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Listar reportes
    Los admins y managers pueden ver todos los reportes, los usuarios solo los suyos
    """
    # Si es admin o manager, puede ver todos los reportes
    if current_user.role.value in ["admin", "manager"]:
        query = db.query(Report)
    else:
        # Los usuarios normales solo pueden ver sus propios reportes
        query = db.query(Report).filter(Report.user_id == current_user.id)
    
    if status:
        query = query.filter(Report.status == status)
    
    reports = query.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()
    
    # Calcular totales para cada reporte
    for report in reports:
        expenses = db.query(Expense).filter(Expense.report_id == report.id).all()
        report.expense_count = len(expenses)
        report.total_amount = sum(e.amount for e in expenses)
    
    return reports

@router.get("/pending", response_model=List[ReportResponse])
async def get_pending_reports(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Listar reportes pendientes de aprobación (solo managers y admins)
    """
    reports = db.query(Report).filter(
        Report.status == "submitted"
    ).order_by(Report.submitted_at.desc()).offset(skip).limit(limit).all()
    
    # Calcular totales para cada reporte
    for report in reports:
        expenses = db.query(Expense).filter(Expense.report_id == report.id).all()
        report.expense_count = len(expenses)
        report.total_amount = sum(e.amount for e in expenses)
    
    return reports

@router.post("/", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Crear un nuevo reporte de gastos
    """
    new_report = Report(
        user_id=current_user.id,
        **report_data.model_dump(),
        status="draft"
    )
    
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    
    # Inicializar contadores
    new_report.expense_count = 0
    new_report.total_amount = 0
    
    return new_report

@router.get("/{report_id}", response_model=ReportWithExpenses)
async def get_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtener un reporte específico con sus gastos
    Los admins y managers pueden ver cualquier reporte, los usuarios solo los suyos
    """
    # Si es admin o manager, puede ver cualquier reporte
    if current_user.role.value in ["admin", "manager"]:
        report = db.query(Report).filter(Report.id == report_id).first()
    else:
        # Los usuarios normales solo pueden ver sus propios reportes
        report = db.query(Report).filter(
            Report.id == report_id,
            Report.user_id == current_user.id
        ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    # Obtener gastos del reporte
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    
    # Calcular totales
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    # Crear respuesta con gastos
    report_dict = ReportWithExpenses.model_validate(report).model_dump()
    report_dict['expenses'] = [ExpenseResponse.model_validate(e) for e in expenses]
    
    return report_dict

@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(
    report_id: int,
    report_data: ReportUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Actualizar un reporte (solo si está en draft)
    """
    report = db.query(Report).filter(
        Report.id == report_id,
        Report.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "draft":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden editar reportes en borrador"
        )
    
    # Actualizar campos
    for field, value in report_data.model_dump(exclude_unset=True).items():
        setattr(report, field, value)
    
    db.commit()
    db.refresh(report)
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.post("/{report_id}/add-expense/{expense_id}", response_model=ReportResponse)
async def add_expense_to_report(
    report_id: int,
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Agregar un gasto a un reporte
    """
    # Verificar que el reporte existe y pertenece al usuario
    report = db.query(Report).filter(
        Report.id == report_id,
        Report.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "draft":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden agregar gastos a reportes en borrador"
        )
    
    # Verificar que el gasto existe y pertenece al usuario
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )
    
    if expense.report_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El gasto ya está asignado a un reporte"
        )
    
    # Asignar el gasto al reporte
    expense.report_id = report_id
    db.commit()
    db.refresh(report)
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.delete("/{report_id}/remove-expense/{expense_id}", response_model=ReportResponse)
async def remove_expense_from_report(
    report_id: int,
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Quitar un gasto de un reporte
    """
    # Verificar que el reporte existe y pertenece al usuario
    report = db.query(Report).filter(
        Report.id == report_id,
        Report.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "draft":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden quitar gastos de reportes en borrador"
        )
    
    # Verificar que el gasto existe y está en este reporte
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id,
        Expense.report_id == report_id
    ).first()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado en este reporte"
        )
    
    # Quitar el gasto del reporte
    expense.report_id = None
    db.commit()
    db.refresh(report)
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.post("/{report_id}/submit", response_model=ReportResponse)
async def submit_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Enviar reporte para aprobación
    """
    report = db.query(Report).filter(
        Report.id == report_id,
        Report.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "draft":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden enviar reportes en borrador"
        )
    
    # Verificar que tiene al menos un gasto
    expense_count = db.query(func.count(Expense.id)).filter(Expense.report_id == report_id).scalar()
    if expense_count == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El reporte debe tener al menos un gasto"
        )
    
    # Cambiar estado
    report.status = "submitted"
    report.submitted_at = datetime.now()
    
    # Cambiar estado de todos los gastos a pending
    db.query(Expense).filter(Expense.report_id == report_id).update({"status": "pending"})
    
    db.commit()
    db.refresh(report)
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.post("/{report_id}/approve", response_model=ReportResponse)
async def approve_report(
    report_id: int,
    approval_data: ApprovalRequest,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Aprobar un reporte (solo managers y admins)
    """
    # Obtener el reporte
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "submitted":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden aprobar reportes enviados"
        )
    
    # Cambiar estado del reporte
    report.status = "approved"
    
    # Cambiar estado de todos los gastos a approved
    db.query(Expense).filter(Expense.report_id == report_id).update({"status": "approved"})
    
    # Crear registro de aprobación
    approval = Approval(
        report_id=report_id,
        approver_id=current_user.id,
        approved=1,
        comments=approval_data.comments
    )
    db.add(approval)
    
    db.commit()
    db.refresh(report)
    
    # Crear notificación para el usuario
    create_notification(
        db=db,
        user_id=report.user_id,
        title="Reporte aprobado",
        message=f"Tu reporte '{report.title}' ha sido aprobado.",
        notification_type="report_approved",
        related_id=report_id
    )
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.post("/{report_id}/reject", response_model=ReportResponse)
async def reject_report(
    report_id: int,
    approval_data: ApprovalRequest,
    current_user: User = Depends(get_current_manager_or_admin),
    db: Session = Depends(get_db)
):
    """
    Rechazar un reporte (solo managers y admins)
    """
    # Obtener el reporte
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte no encontrado"
        )
    
    if report.status != "submitted":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden rechazar reportes enviados"
        )
    
    # Cambiar estado del reporte
    report.status = "rejected"
    
    # Cambiar estado de todos los gastos a rejected
    db.query(Expense).filter(Expense.report_id == report_id).update({"status": "rejected"})
    
    # Crear registro de rechazo
    approval = Approval(
        report_id=report_id,
        approver_id=current_user.id,
        approved=0,
        comments=approval_data.comments
    )
    db.add(approval)
    
    db.commit()
    db.refresh(report)
    
    # Crear notificación para el usuario
    create_notification(
        db=db,
        user_id=report.user_id,
        title="Reporte rechazado",
        message=f"Tu reporte '{report.name}' ha sido rechazado. {approval_data.comments or ''}",
        notification_type="report_rejected",
        related_id=report_id
    )
    
    # Calcular totales
    expenses = db.query(Expense).filter(Expense.report_id == report_id).all()
    report.expense_count = len(expenses)
    report.total_amount = sum(e.amount for e in expenses)
    
    return report

@router.get("/{report_id}/export")
async def export_report(report_id: int, format: str = "pdf"):
    return {"message": f"Export report {report_id} as {format} - To be implemented"}



