"""
Services package
"""
from app.services.ocr_service import ocr_service
from app.services.storage_service import storage_service

__all__ = ["ocr_service", "storage_service"]
