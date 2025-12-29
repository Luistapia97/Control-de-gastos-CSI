"""
API Routes - Expenses
"""
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, status, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import json
from datetime import datetime
import shutil
import os
from pathlib import Path

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import Expense, User, Category
from app.models.trip import Trip
from app.schemas import ExpenseCreate, ExpenseUpdate, ExpenseResponse, OCRScanResponse
from app.services import ocr_service, storage_service

router = APIRouter()

# Directorio para almacenar recibos (debe coincidir con main.py)
RECEIPTS_DIR = Path("receipts")
RECEIPTS_DIR.mkdir(parents=True, exist_ok=True)

import logging
logger = logging.getLogger("uvicorn")

@router.get("/", response_model=List[ExpenseResponse])
async def get_expenses(
    skip: int = 0,
    limit: int = 100,
    category_id: Optional[int] = None,
    status: Optional[str] = None,
    trip_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtener gastos con filtros opcionales
    Los admins y managers pueden ver todos los gastos, los usuarios solo los suyos
    """
    logger.info(f"🔍 GET /expenses/ - User: {current_user.email}, Role: {current_user.role.value}, trip_id: {trip_id}")
    
    # Si es admin o manager, puede ver todos los gastos
    if current_user.role.value in ["admin", "manager"]:
        query = db.query(Expense)
        logger.info(f"✅ Admin/Manager query (all expenses)")
    else:
        # Los usuarios normales solo pueden ver sus propios gastos
        query = db.query(Expense).filter(Expense.user_id == current_user.id)
        logger.info(f"👤 Employee query (user_id={current_user.id})")
    
    if category_id:
        query = query.filter(Expense.category_id == category_id)
    
    if status:
        query = query.filter(Expense.status == status)
    
    if trip_id:
        query = query.filter(Expense.trip_id == trip_id)
    
    expenses = query.order_by(Expense.expense_date.desc()).offset(skip).limit(limit).all()
    logger.info(f"📊 Found {len(expenses)} expenses")
    for exp in expenses:
        logger.info(f"  💰 Expense ID {exp.id}: user_id={exp.user_id}, trip_id={exp.trip_id}, amount={exp.amount}")
    
    return expenses

@router.post("/", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    category_id: int = Form(...),
    amount: int = Form(...),
    currency: str = Form("USD"),
    merchant: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    expense_date: str = Form(...),
    trip_id: Optional[int] = Form(None),
    receipt: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Crear un nuevo gasto con imagen opcional del recibo
    """
    try:
        # Verificar que la categoría existe
        category = db.query(Category).filter(Category.id == category_id).first()
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Categoría no encontrada"
            )
        
        # Si se especifica un viaje, verificar que no esté completado
        if trip_id:
            trip = db.query(Trip).filter(Trip.id == trip_id).first()
            if trip and trip.status == "completed":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No se pueden agregar gastos a un viaje completado"
                )
        
        # Convertir fecha
        expense_date_obj = datetime.fromisoformat(expense_date.replace('Z', '+00:00'))
        
        # Procesar imagen del recibo si existe
        receipt_url = None
        receipt_original_name = None
        ocr_data = None
        ocr_confidence = None
        
        if receipt:
            # Validar extensión de archivo (más flexible que content_type)
            file_extension = receipt.filename.split('.')[-1].lower()
            allowed_extensions = ["jpg", "jpeg", "png", "gif", "webp"]
            if file_extension not in allowed_extensions:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Extensión de archivo no permitida. Use: {', '.join(allowed_extensions)}"
                )
            
            # Guardar archivo
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{current_user.id}_{timestamp}.{file_extension}"
            file_path = RECEIPTS_DIR / filename
            
            with file_path.open("wb") as buffer:
                shutil.copyfileobj(receipt.file, buffer)
            
            receipt_url = f"receipts/{filename}"
            receipt_original_name = receipt.filename
            
            # Procesar OCR (opcional)
            try:
                file_path_str = str(file_path)
                ocr_result = ocr_service.extract_receipt_data_from_file(file_path_str)
                if ocr_result:
                    ocr_data = json.dumps(ocr_result)
                    ocr_confidence = ocr_result.get('confidence', 0)
            except Exception as e:
                print(f"⚠️  OCR processing failed: {str(e)}")
                # Continuar sin OCR
        
        # Crear el gasto
        new_expense = Expense(
            user_id=current_user.id,
            category_id=category_id,
            amount=amount,
            currency=currency,
            merchant=merchant,
            description=description,
            expense_date=expense_date_obj,
            trip_id=trip_id,
            receipt_url=receipt_url,
            receipt_original_name=receipt_original_name,
            ocr_data=ocr_data,
            ocr_confidence=ocr_confidence
        )
        
        db.add(new_expense)
        db.commit()
        db.refresh(new_expense)
        
        return new_expense
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error creating expense: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear gasto: {str(e)}"
        )

@router.post("/scan", response_model=OCRScanResponse)
async def scan_receipt(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Escanear un recibo usando OCR y extraer información
    """
    # Validar extensión de archivo (más flexible que content_type)
    file_extension = file.filename.split('.')[-1].lower()
    allowed_extensions = ["jpg", "jpeg", "png", "gif", "webp"]
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Extensión de archivo no permitida. Use: {', '.join(allowed_extensions)}"
        )
    
    # Leer el archivo
    file_bytes = await file.read()
    
    # Upload a storage (simulado por ahora si no hay credenciales S3)
    receipt_url = f"local://receipts/{current_user.id}/{file.filename}"
    try:
        uploaded_url = storage_service.upload_receipt(file_bytes, file.filename, current_user.id)
        if uploaded_url:
            receipt_url = uploaded_url
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        # Continuar con URL local
    
    # Procesar con OCR
    try:
        ocr_result = ocr_service.extract_receipt_data(file_bytes)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al procesar OCR: {str(e)}"
        )
    
    # Sugerir categoría basada en el comercio
    suggested_category = None
    if ocr_result.get("merchant"):
        merchant_lower = ocr_result["merchant"].lower()
        if any(word in merchant_lower for word in ["restaurant", "cafe", "food", "pizza", "burger"]):
            suggested_category = db.query(Category).filter(Category.name.like("%Comida%")).first()
        elif any(word in merchant_lower for word in ["uber", "taxi", "gas", "shell", "mobil"]):
            suggested_category = db.query(Category).filter(Category.name.like("%Transporte%")).first()
        elif any(word in merchant_lower for word in ["hotel", "airbnb", "booking"]):
            suggested_category = db.query(Category).filter(Category.name.like("%Alojamiento%")).first()
    
    # Preparar sugerencia de gasto
    suggested_expense = None
    if ocr_result.get("amount"):
        suggested_expense = {
            "category_id": suggested_category.id if suggested_category else None,
            "amount": int(ocr_result["amount"] * 100),  # Convertir a centavos
            "merchant": ocr_result.get("merchant"),
            "expense_date": datetime.now().isoformat() if not ocr_result.get("date") else ocr_result.get("date"),
            "currency": "USD"
        }
    
    return OCRScanResponse(
        merchant=ocr_result.get("merchant"),
        amount=ocr_result.get("amount"),
        date=ocr_result.get("date"),
        confidence=ocr_result.get("confidence", 0),
        raw_text=ocr_result.get("raw_text", ""),
        receipt_url=receipt_url,
        suggested_expense=suggested_expense
    )

@router.get("/{expense_id}", response_model=ExpenseResponse)
async def get_expense(
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtener un gasto específico
    """
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )
    
    return expense

@router.put("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: int,
    expense_data: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Actualizar un gasto
    """
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )
    
    # Actualizar solo los campos proporcionados
    update_data = expense_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(expense, field, value)
    
    db.commit()
    db.refresh(expense)
    
    return expense

@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Eliminar un gasto
    """
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )
    
    # Eliminar imagen del storage si existe
    if expense.receipt_url and expense.receipt_url.startswith("http"):
        try:
            storage_service.delete_receipt(expense.receipt_url)
        except Exception as e:
            print(f"Error deleting receipt: {e}")
    
    db.delete(expense)
    db.commit()
    
    return None
