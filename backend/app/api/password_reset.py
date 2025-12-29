"""
Password Reset API Endpoints
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
import secrets
from app.core.database import get_db
from app.models.user import User
from app.core.security import get_password_hash

router = APIRouter()

# Modelos de request
class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str

@router.post("/request-reset")
async def request_password_reset(
    request: PasswordResetRequest,
    db: Session = Depends(get_db)
):
    """
    Solicitar reset de contraseña - envía email con token
    """
    # Buscar usuario por email
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        # Por seguridad, no revelar si el email existe
        return {
            "message": "Si el email existe, recibirás un enlace de recuperación"
        }
    
    # Generar token seguro
    reset_token = secrets.token_urlsafe(32)
    
    # Guardar token en usuario (expira en 1 hora)
    user.reset_token = reset_token
    user.reset_token_expires = datetime.utcnow() + timedelta(hours=1)
    db.commit()
    
    # TODO: Enviar email con el token
    # Por ahora, lo devolvemos en desarrollo
    # En producción, esto debería enviarse por email
    reset_link = f"expense://reset-password?token={reset_token}"
    
    # Simulación de envío de email (reemplazar con SMTP real)
    print(f"=== EMAIL DE RECUPERACIÓN ===")
    print(f"Para: {user.email}")
    print(f"Token: {reset_token}")
    print(f"Link: {reset_link}")
    print(f"============================")
    
    return {
        "message": "Si el email existe, recibirás un enlace de recuperación",
        "dev_token": reset_token  # Solo para desarrollo, remover en producción
    }

@router.post("/reset-password")
async def reset_password(
    request: PasswordResetConfirm,
    db: Session = Depends(get_db)
):
    """
    Cambiar contraseña con token válido
    """
    # Buscar usuario por token
    user = db.query(User).filter(
        User.reset_token == request.token
    ).first()
    
    if not user:
        raise HTTPException(
            status_code=400,
            detail="Token inválido o expirado"
        )
    
    # Verificar si el token expiró
    if user.reset_token_expires < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail="Token expirado. Solicita uno nuevo"
        )
    
    # Cambiar contraseña
    user.hashed_password = get_password_hash(request.new_password)
    user.reset_token = None
    user.reset_token_expires = None
    db.commit()
    
    return {
        "message": "Contraseña actualizada exitosamente"
    }

@router.post("/validate-token")
async def validate_reset_token(
    token: str,
    db: Session = Depends(get_db)
):
    """
    Validar si un token de reset es válido
    """
    user = db.query(User).filter(
        User.reset_token == token
    ).first()
    
    if not user or user.reset_token_expires < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail="Token inválido o expirado"
        )
    
    return {
        "valid": True,
        "email": user.email
    }
