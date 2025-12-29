"""
Script para crear categorías por defecto
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal
from app.models import Category

def seed_categories():
    """Crear categorías iniciales"""
    db = SessionLocal()
    
    # Verificar si ya existen categorías
    existing = db.query(Category).first()
    if existing:
        print("✅ Las categorías ya existen")
        return
    
    categories = [
        {
            "name": "Comida y Bebidas",
            "description": "Restaurantes, cafeterías, comida",
            "icon": "🍔",
            "color": "#EF4444",
            "max_amount": 5000  # $50.00
        },
        {
            "name": "Transporte",
            "description": "Taxi, Uber, gasolina, estacionamiento",
            "icon": "🚗",
            "color": "#3B82F6",
            "max_amount": 10000  # $100.00
        },
        {
            "name": "Alojamiento",
            "description": "Hotel, Airbnb",
            "icon": "🏨",
            "color": "#8B5CF6",
            "max_amount": 20000  # $200.00
        },
        {
            "name": "Oficina",
            "description": "Material de oficina, equipamiento",
            "icon": "💼",
            "color": "#10B981",
            "max_amount": 15000  # $150.00
        },
        {
            "name": "Tecnología",
            "description": "Software, hardware, suscripciones",
            "icon": "💻",
            "color": "#6366F1",
            "max_amount": 50000  # $500.00
        },
        {
            "name": "Entretenimiento",
            "description": "Cliente, eventos, regalos",
            "icon": "🎭",
            "color": "#EC4899",
            "max_amount": 10000  # $100.00
        },
        {
            "name": "Otros",
            "description": "Gastos varios",
            "icon": "📦",
            "color": "#6B7280",
            "max_amount": None
        },
    ]
    
    for cat_data in categories:
        category = Category(**cat_data)
        db.add(category)
    
    db.commit()
    print(f"✅ Se crearon {len(categories)} categorías exitosamente")
    db.close()

if __name__ == "__main__":
    seed_categories()
