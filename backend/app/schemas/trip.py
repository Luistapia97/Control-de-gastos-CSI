from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional


class TripBase(BaseModel):
    name: str
    destination: Optional[str] = None
    start_date: date
    end_date: date
    description: Optional[str] = None
    budget: Optional[int] = None  # En centavos


class TripCreate(TripBase):
    pass


class TripUpdate(BaseModel):
    name: Optional[str] = None
    destination: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    description: Optional[str] = None
    budget: Optional[int] = None
    status: Optional[str] = None


class Trip(TripBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    user_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    
    @property
    def total_expenses(self) -> int:
        """Calcula el total de gastos del viaje"""
        return sum(expense.amount for expense in self.expenses) if hasattr(self, 'expenses') else 0
    
    @property
    def budget_used_percentage(self) -> float:
        """Calcula el porcentaje del presupuesto utilizado"""
        if not self.budget or self.budget == 0:
            return 0.0
        return (self.total_expenses / self.budget) * 100


class TripWithExpenses(Trip):
    expenses: list = []
