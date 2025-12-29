"""
Configuración para Render.com deployment
"""
import os
from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Expense Control API"
    VERSION: str = "1.0.0"
    
    # Database - Render proporciona DATABASE_URL
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://expense_user:expense_pass@localhost:5432/expense_control"
    )
    
    # Convertir postgres:// a postgresql:// (Render usa postgres://)
    if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS - Permitir todas las IPs para uso interno
    ALLOWED_ORIGINS: List[str] = os.getenv("ALLOWED_ORIGINS", "*").split(",")
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    # Redis (opcional - Render tiene add-on gratuito)
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # File Storage
    RECEIPTS_DIR: str = os.getenv("RECEIPTS_DIR", "/app/receipts")
    
    # Email (opcional)
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
