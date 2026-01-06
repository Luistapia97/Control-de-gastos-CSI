"""
Storage Service - Upload files to Supabase Storage
"""
import os
from typing import Optional
import uuid
from pathlib import Path
from supabase import create_client, Client
import logging

logger = logging.getLogger("uvicorn")

class StorageService:
    def __init__(self):
        # Verificar si hay configuración de Supabase
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_KEY")
        
        logger.info(f"🔧 Storage Service Init - SUPABASE_URL: {'SET' if supabase_url else 'NOT SET'}")
        logger.info(f"🔧 Storage Service Init - SUPABASE_KEY: {'SET' if supabase_key else 'NOT SET'}")
        
        if supabase_url and supabase_key:
            self.use_supabase = True
            self.supabase: Client = create_client(supabase_url, supabase_key)
            self.bucket_name = os.getenv("SUPABASE_BUCKET", "receipts")
            logger.info(f"✅ Using Supabase Storage - Bucket: {self.bucket_name}")
        else:
            self.use_supabase = False
            # Fallback a almacenamiento local
            self.receipts_dir = os.getenv("RECEIPTS_DIR", "/data/receipts")
            os.makedirs(self.receipts_dir, exist_ok=True)
            logger.warning(f"⚠️  Using LOCAL storage - Dir: {self.receipts_dir}")
    
    def upload_receipt(self, file_bytes: bytes, filename: str, user_id: int) -> Optional[str]:
        """
        Upload receipt image to Supabase Storage or local storage
        
        Returns:
            Public URL of uploaded file or None if failed
        """
        try:
            # Generate unique filename
            extension = Path(filename).suffix
            unique_filename = f"{user_id}/{uuid.uuid4()}{extension}"
            
            if self.use_supabase:
                # Upload to Supabase Storage
                logger.info(f"📤 Uploading to Supabase: {unique_filename}")
                response = self.supabase.storage.from_(self.bucket_name).upload(
                    path=unique_filename,
                    file=file_bytes,
                    file_options={"content-type": self._get_content_type(extension)}
                )
                
                # Get public URL
                public_url = self.supabase.storage.from_(self.bucket_name).get_public_url(unique_filename)
                logger.info(f"✅ Uploaded to Supabase: {public_url}")
                return public_url
            else:
                # Upload to local storage
                logger.warning(f"⚠️  Uploading to LOCAL storage: {unique_filename}")
                user_dir = os.path.join(self.receipts_dir, str(user_id))
                os.makedirs(user_dir, exist_ok=True)
                
                file_path = os.path.join(user_dir, unique_filename.split('/')[-1])
                with open(file_path, 'wb') as f:
                    f.write(file_bytes)
                
                # Return relative URL
                relative_url = f"receipts/{user_id}/{unique_filename.split('/')[-1]}"
                logger.info(f"💾 Saved locally: {relative_url}")
                return relative_url
        
        except Exception as e:
            print(f"❌ Error uploading file: {e}")
            return None
    
    def delete_receipt(self, file_url: str) -> bool:
        """Delete receipt from Supabase Storage or local storage"""
        try:
            if self.use_supabase and "supabase" in file_url:
                # Extract path from Supabase URL
                # URL format: https://xxx.supabase.co/storage/v1/object/public/receipts/path
                parts = file_url.split(f"/{self.bucket_name}/")
                if len(parts) == 2:
                    file_path = parts[1]
                    self.supabase.storage.from_(self.bucket_name).remove([file_path])
                    return True
            elif file_url.startswith('receipts/'):
                # Delete from local storage
                file_path = os.path.join(self.receipts_dir, file_url.replace('receipts/', ''))
                if os.path.exists(file_path):
                    os.remove(file_path)
                    return True
            return False
        except Exception as e:
            print(f"❌ Error deleting file: {e}")
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
