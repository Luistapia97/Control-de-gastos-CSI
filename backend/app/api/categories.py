"""
API Routes - Categories
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.models import Category

router = APIRouter()

@router.get("/")
async def get_categories(db: Session = Depends(get_db)):
    """
    Obtener todas las categorías activas
    """
    categories = db.query(Category).filter(Category.is_active == True).all()
    return categories

@router.post("/")
async def create_category():
    """
    Crear nueva categoría (solo admin)
    TODO: Implementar creación de categoría
    """
    return {"message": "Create category endpoint - To be implemented"}

@router.put("/{category_id}")
async def update_category(category_id: int):
    """
    Actualizar categoría (solo admin)
    TODO: Implementar actualización de categoría
    """
    return {"message": f"Update category {category_id} - To be implemented"}
