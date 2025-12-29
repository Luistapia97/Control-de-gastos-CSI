"""
API Routes - Users
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_admin_user
from app.models import User
from app.schemas import UserResponse

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Obtener información del usuario actual
    """
    return current_user

@router.put("/me")
async def update_current_user(current_user: User = Depends(get_current_user)):
    """
    Actualizar información del usuario actual
    TODO: Implementar actualización de perfil
    """
    return {"message": "Update current user endpoint - To be implemented"}

@router.get("/", dependencies=[Depends(get_current_admin_user)])
async def get_users(db: Session = Depends(get_db)):
    """
    Obtener lista de usuarios (solo admin)
    """
    users = db.query(User).all()
    return users

