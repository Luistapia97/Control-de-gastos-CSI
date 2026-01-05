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
RECEIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "receipts"))
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
