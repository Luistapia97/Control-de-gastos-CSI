"""
FastAPI Application Entry Point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from app.core.config import settings
from app.api import auth, expenses, reports, categories, users, trips, refunds, statistics, password_reset, export, notifications

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    description="API para Control de Gastos - OCR Intelligence",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos de recibos
# Usar disco persistente en Render (/data/receipts) o carpeta local en desarrollo
RECEIPTS_DIR = os.getenv("RECEIPTS_DIR", "/data/receipts")
os.makedirs(RECEIPTS_DIR, exist_ok=True)
app.mount("/receipts", StaticFiles(directory=RECEIPTS_DIR), name="receipts")

# Health Check
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.1.0",
        "service": "expense-control-api"
    }

# Endpoint temporal para crear categorías por defecto (ELIMINAR después de usar)
@app.post("/init-categories")
async def init_categories():
    """
    TEMPORAL: Crea categorías por defecto
    ⚠️ ELIMINAR este endpoint después de usarlo
    """
    try:
        from app.core.database import SessionLocal
        from app.models.category import Category
        
        db = SessionLocal()
        
        # Eliminar categorías existentes sin icon/color
        db.query(Category).delete()
        db.commit()
        
        # Categorías por defecto con iconos y colores
        default_categories = [
            {"name": "Transporte", "description": "Taxis, buses, gasolina, estacionamiento", "icon": "🚗", "color": "#2196F3"},
            {"name": "Alojamiento", "description": "Hoteles, hospedaje", "icon": "🏨", "color": "#9C27B0"},
            {"name": "Alimentación", "description": "Restaurantes, comidas", "icon": "🍽️", "color": "#FF9800"},
            {"name": "Entretenimiento", "description": "Actividades recreativas", "icon": "🎭", "color": "#E91E63"},
            {"name": "Suministros", "description": "Material de oficina, equipos", "icon": "📦", "color": "#607D8B"},
            {"name": "Comunicaciones", "description": "Teléfono, internet", "icon": "📱", "color": "#00BCD4"},
            {"name": "Otros", "description": "Gastos varios", "icon": "💼", "color": "#795548"}
        ]
        
        categories_created = []
        for cat_data in default_categories:
            category = Category(**cat_data)
            db.add(category)
            categories_created.append(cat_data["name"])
        
        db.commit()
        db.close()
        
        return {
            "status": "success",
            "message": "Categorías creadas correctamente",
            "categories": categories_created
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

# Include Routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(password_reset.router, prefix="/api/password", tags=["Password Reset"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(expenses.router, prefix="/api/expenses", tags=["Expenses"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(export.router, prefix="/api/reports", tags=["Export"])
app.include_router(categories.router, prefix="/api/categories", tags=["Categories"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(trips.router, prefix="/api/trips", tags=["Trips"])
app.include_router(refunds.router, prefix="/api/refunds", tags=["Refunds"])
app.include_router(statistics.router, prefix="/api/statistics", tags=["Statistics"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
