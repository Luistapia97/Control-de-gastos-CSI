"""
Statistics API Endpoints
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from typing import Optional
from datetime import datetime, date, timedelta
import logging

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.expense import Expense
from app.models.trip import Trip
from app.models.category import Category
from app.models.refund import Refund

router = APIRouter()
logger = logging.getLogger("uvicorn")

@router.get("/overview")
async def get_overview_statistics(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Estadísticas generales del usuario o de toda la empresa (admin)
    """
    logger.info(f"📊 GET /statistics/overview - User: {current_user.email}, Role: {current_user.role.value}")
    
    # Fechas por defecto: último mes
    if not start_date:
        start_date = date.today() - timedelta(days=30)
    if not end_date:
        end_date = date.today()
    
    # Query base según rol
    if current_user.role.value in ["admin", "manager"]:
        expenses_query = db.query(Expense)
        trips_query = db.query(Trip)
        refunds_query = db.query(Refund)
    else:
        expenses_query = db.query(Expense).filter(Expense.user_id == current_user.id)
        trips_query = db.query(Trip).filter(Trip.user_id == current_user.id)
        refunds_query = db.query(Refund).filter(Refund.user_id == current_user.id)
    
    # Filtrar por fechas
    expenses_query = expenses_query.filter(
        Expense.expense_date >= start_date,
        Expense.expense_date <= end_date
    )
    
    # Total gastado
    total_spent = expenses_query.with_entities(func.sum(Expense.amount)).scalar() or 0
    
    # Cantidad de gastos
    expenses_count = expenses_query.count()
    
    # Cantidad de viajes
    trips_count = trips_query.count()
    active_trips = trips_query.filter(Trip.status == "active").count()
    completed_trips = trips_query.filter(Trip.status == "completed").count()
    
    # Reembolsos pendientes (calcular remaining_amount = excess_amount - refunded_amount)
    pending_refunds_sum = refunds_query.filter(Refund.status == "pending")\
        .with_entities(func.sum(Refund.excess_amount - Refund.refunded_amount)).scalar()
    pending_refunds = pending_refunds_sum or 0
    
    logger.info(f"💰 Total spent: ${total_spent/100:.2f}, Expenses: {expenses_count}, Trips: {trips_count}")
    
    return {
        "total_spent": total_spent,
        "expenses_count": expenses_count,
        "trips_count": trips_count,
        "active_trips": active_trips,
        "completed_trips": completed_trips,
        "pending_refunds": pending_refunds,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat()
    }

@router.get("/by-category")
async def get_expenses_by_category(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Gastos agrupados por categoría
    """
    logger.info(f"📊 GET /statistics/by-category - User: {current_user.email}")
    
    if not start_date:
        start_date = date.today() - timedelta(days=30)
    if not end_date:
        end_date = date.today()
    
    # Query base
    query = db.query(
        Category.name,
        Category.id,
        func.sum(Expense.amount).label('total'),
        func.count(Expense.id).label('count')
    ).join(Expense, Expense.category_id == Category.id)
    
    # Filtrar por usuario si no es admin
    if current_user.role.value not in ["admin", "manager"]:
        query = query.filter(Expense.user_id == current_user.id)
    
    # Filtrar por fechas
    query = query.filter(
        Expense.expense_date >= start_date,
        Expense.expense_date <= end_date
    )
    
    # Agrupar y ordenar
    results = query.group_by(Category.id, Category.name).order_by(func.sum(Expense.amount).desc()).all()
    
    # Calcular total para porcentajes
    total = sum(r.total for r in results)
    
    categories = []
    for r in results:
        percentage = (r.total / total * 100) if total > 0 else 0
        categories.append({
            "category_id": r.id,
            "category_name": r.name,
            "total_amount": r.total,
            "expenses_count": r.count,
            "percentage": round(percentage, 2)
        })
    
    logger.info(f"📂 Found {len(categories)} categories with expenses")
    return categories

@router.get("/monthly-trend")
async def get_monthly_trend(
    months: int = Query(default=6, ge=1, le=24),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Tendencia de gastos mensuales
    """
    logger.info(f"📊 GET /statistics/monthly-trend - User: {current_user.email}, Months: {months}")
    
    # Calcular fecha de inicio
    start_date = date.today() - timedelta(days=months * 30)
    
    # Query base
    query = db.query(
        extract('year', Expense.expense_date).label('year'),
        extract('month', Expense.expense_date).label('month'),
        func.sum(Expense.amount).label('total'),
        func.count(Expense.id).label('count')
    )
    
    # Filtrar por usuario si no es admin
    if current_user.role.value not in ["admin", "manager"]:
        query = query.filter(Expense.user_id == current_user.id)
    
    # Filtrar por fecha
    query = query.filter(Expense.expense_date >= start_date)
    
    # Agrupar y ordenar
    results = query.group_by('year', 'month').order_by('year', 'month').all()
    
    monthly_data = []
    for r in results:
        monthly_data.append({
            "year": int(r.year),
            "month": int(r.month),
            "total_amount": r.total,
            "expenses_count": r.count,
            "month_name": datetime(int(r.year), int(r.month), 1).strftime("%B %Y")
        })
    
    logger.info(f"📈 Found data for {len(monthly_data)} months")
    return monthly_data

@router.get("/top-users")
async def get_top_users(
    limit: int = Query(default=10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Top usuarios con más gastos (solo admin/manager)
    """
    if current_user.role.value not in ["admin", "manager"]:
        return {"error": "No autorizado"}
    
    logger.info(f"📊 GET /statistics/top-users - Limit: {limit}")
    
    results = db.query(
        User.id,
        User.full_name,
        User.email,
        func.sum(Expense.amount).label('total'),
        func.count(Expense.id).label('count')
    ).join(Expense, Expense.user_id == User.id)\
     .group_by(User.id, User.full_name, User.email)\
     .order_by(func.sum(Expense.amount).desc())\
     .limit(limit).all()
    
    top_users = []
    for r in results:
        top_users.append({
            "user_id": r.id,
            "user_name": r.full_name,
            "user_email": r.email,
            "total_amount": r.total,
            "expenses_count": r.count
        })
    
    logger.info(f"👥 Found top {len(top_users)} users")
    return top_users

@router.get("/budget-compliance")
async def get_budget_compliance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Tasa de cumplimiento de presupuesto
    """
    logger.info(f"📊 GET /statistics/budget-compliance - User: {current_user.email}")
    
    # Query base
    query = db.query(Trip).filter(Trip.budget.isnot(None))
    
    # Filtrar por usuario si no es admin
    if current_user.role.value not in ["admin", "manager"]:
        query = query.filter(Trip.user_id == current_user.id)
    
    trips_with_budget = query.all()
    
    total_trips = len(trips_with_budget)
    if total_trips == 0:
        return {
            "total_trips": 0,
            "within_budget": 0,
            "over_budget": 0,
            "compliance_rate": 0
        }
    
    within_budget = 0
    over_budget = 0
    
    for trip in trips_with_budget:
        # Sumar gastos del viaje
        total_expenses = db.query(func.sum(Expense.amount))\
            .filter(Expense.trip_id == trip.id)\
            .scalar() or 0
        
        if total_expenses <= trip.budget:
            within_budget += 1
        else:
            over_budget += 1
    
    compliance_rate = (within_budget / total_trips * 100) if total_trips > 0 else 0
    
    logger.info(f"✅ Compliance: {compliance_rate:.1f}% ({within_budget}/{total_trips})")
    
    return {
        "total_trips": total_trips,
        "within_budget": within_budget,
        "over_budget": over_budget,
        "compliance_rate": round(compliance_rate, 2)
    }
