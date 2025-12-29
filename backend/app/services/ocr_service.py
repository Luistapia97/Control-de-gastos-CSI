"""
Google Cloud Vision OCR Service
"""
from typing import Dict, Optional
import io
from PIL import Image
import re
from datetime import datetime
import os

class OCRService:
    def __init__(self):
        """
        Inicializar servicio OCR.
        Si no hay credenciales de Google Cloud, usar modo simulado
        """
        self.client = None
        self.mock_mode = True
        
        try:
            # Intentar inicializar Google Cloud Vision
            if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
                from google.cloud import vision
                self.client = vision.ImageAnnotatorClient()
                self.mock_mode = False
                print("✅ Google Cloud Vision API inicializado")
        except Exception as e:
            print(f"⚠️ Google Cloud Vision no disponible, usando modo simulado: {e}")
            self.mock_mode = True
    
    def extract_receipt_data(self, image_bytes: bytes) -> Dict:
        """
        Extrae información de un recibo usando Google Cloud Vision o modo simulado
        
        Returns:
            Dict con: merchant, amount, date, confidence, raw_text
        """
        if self.mock_mode:
            return self._mock_extract_receipt_data(image_bytes)
        
        try:
            from google.cloud import vision
            image = vision.Image(content=image_bytes)
            
            # Detección de texto
            response = self.client.text_detection(image=image)
            texts = response.text_annotations
            
            if not texts:
                return {
                    "merchant": None,
                    "amount": None,
                    "date": None,
                    "confidence": 0,
                    "raw_text": "",
                    "error": "No text detected"
                }
            
            # El primer elemento contiene todo el texto
            full_text = texts[0].description
            
            # Extraer información
            merchant = self._extract_merchant(full_text)
            amount = self._extract_amount(full_text)
            date = self._extract_date(full_text)
            
            # Calcular confianza promedio
            confidence = int(sum([t.confidence for t in texts[1:] if hasattr(t, 'confidence')]) / len(texts[1:]) * 100) if len(texts) > 1 else 0
            
            return {
                "merchant": merchant,
                "amount": amount,
                "date": date,
                "confidence": confidence,
                "raw_text": full_text
            }
        except Exception as e:
            print(f"Error en OCR: {e}")
            return self._mock_extract_receipt_data(image_bytes)
    
    def _mock_extract_receipt_data(self, image_bytes: bytes) -> Dict:
        """
        Modo simulado de OCR para desarrollo sin credenciales de Google Cloud
        """
        return {
            "merchant": "",
            "amount": None,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "confidence": 85,
            "raw_text": "RECIBO DE PRUEBA\nFecha: 2025-12-12\nTotal: $45.99\nGracias por su visita",
            "mock": True
        }
    
    def _extract_merchant(self, text: str) -> Optional[str]:
        """Extrae el nombre del comercio (primeras 1-2 líneas)"""
        lines = text.split('\n')
        return lines[0] if lines else None
    
    def _extract_amount(self, text: str) -> Optional[float]:
        """Extrae el monto total del recibo"""
        # Patrones comunes: $123.45, 123.45, TOTAL: 123.45
        patterns = [
            r'TOTAL[:\s]*\$?(\d+[.,]\d{2})',
            r'SUBTOTAL[:\s]*\$?(\d+[.,]\d{2})',
            r'\$(\d+[.,]\d{2})',
            r'(\d+[.,]\d{2})'
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            if matches:
                # Tomar el valor más alto (probablemente el total)
                amounts = [float(m.replace(',', '.')) for m in matches]
                return max(amounts)
        
        return None
    
    def _extract_date(self, text: str) -> Optional[str]:
        """Extrae la fecha del recibo"""
        # Patrones de fecha comunes
        patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
            r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})',
            r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(0)
        
        return None
    
    def extract_receipt_data_from_file(self, file_path: str) -> Dict:
        """
        Extrae información de un recibo desde un archivo en disco
        
        Args:
            file_path: Ruta al archivo de imagen
            
        Returns:
            Dict con: merchant, amount, date, confidence, raw_text
        """
        with open(file_path, 'rb') as f:
            image_bytes = f.read()
        return self.extract_receipt_data(image_bytes)

# Singleton instance
ocr_service = OCRService()
