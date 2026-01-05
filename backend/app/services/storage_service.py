"""
Storage Service - Upload files locally (S3/R2 disabled for now)
"""
import os
from typing import Optional
import uuid
from pathlib import Path

class StorageService:
    def __init__(self):
        # Usar almacenamiento local en lugar de S3
        self.receipts_dir = os.getenv("RECEIPTS_DIR", "/app/receipts")
        os.makedirs(self.receipts_dir, exist_ok=True)
    
    def upload_receipt(self, file_bytes: bytes, filename: str, user_id: int) -> Optional[str]:
        """
        Upload receipt image to local storage
        
        Returns:
            Relative URL of uploaded file or None if failed
        """
        try:
            # Generate unique filename
            extension = Path(filename).suffix
            unique_filename = f"{user_id}_{uuid.uuid4()}{extension}"
            
            # Create user directory
            user_dir = os.path.join(self.receipts_dir, str(user_id))
            os.makedirs(user_dir, exist_ok=True)
            
            # Save file
            file_path = os.path.join(user_dir, unique_filename)
            with open(file_path, 'wb') as f:
                f.write(file_bytes)
            
            # Return relative URL
            return f"receipts/{user_id}/{unique_filename}"
        
        except Exception as e:
            print(f"Error uploading file: {e}")
            return None
    
    def delete_receipt(self, file_url: str) -> bool:
        """Delete receipt from local storage"""
        try:
            # Extract filename from URL
            if file_url.startswith('receipts/'):
                file_path = os.path.join(self.receipts_dir, file_url.replace('receipts/', ''))
                if os.path.exists(file_path):
                    os.remove(file_path)
                return True
            return False
        except Exception as e:
            print(f"Error deleting file: {e}")
            return False
    
    def _get_content_type(self, extension: str) -> str:
        """Get MIME type from file extension"""
        content_types = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.pdf': 'application/pdf',
            '.gif': 'image/gif'
        }
        return content_types.get(extension.lower(), 'application/octet-stream')

storage_service = StorageService()
