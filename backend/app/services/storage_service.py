"""
Storage Service - Upload files to S3/R2
"""
import boto3
from botocore.exceptions import ClientError
from app.core.config import settings
from typing import Optional
import uuid
from pathlib import Path

class StorageService:
    def __init__(self):
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.S3_ACCESS_KEY,
            aws_secret_access_key=settings.S3_SECRET_KEY,
            endpoint_url=settings.S3_ENDPOINT if settings.S3_ENDPOINT else None,
            region_name=settings.S3_REGION
        )
        self.bucket = settings.S3_BUCKET
    
    def upload_receipt(self, file_bytes: bytes, filename: str, user_id: int) -> Optional[str]:
        """
        Upload receipt image to S3/R2
        
        Returns:
            URL of uploaded file or None if failed
        """
        try:
            # Generate unique filename
            extension = Path(filename).suffix
            unique_filename = f"receipts/{user_id}/{uuid.uuid4()}{extension}"
            
            # Upload
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=unique_filename,
                Body=file_bytes,
                ContentType=self._get_content_type(extension)
            )
            
            # Generate URL
            url = f"https://{self.bucket}.s3.{settings.S3_REGION}.amazonaws.com/{unique_filename}"
            if settings.S3_ENDPOINT:
                url = f"{settings.S3_ENDPOINT}/{self.bucket}/{unique_filename}"
            
            return url
        
        except ClientError as e:
            print(f"Error uploading to S3: {e}")
            return None
    
    def delete_receipt(self, url: str) -> bool:
        """Delete receipt from S3/R2"""
        try:
            # Extract key from URL
            key = url.split(f"{self.bucket}/")[-1]
            self.s3_client.delete_object(Bucket=self.bucket, Key=key)
            return True
        except ClientError as e:
            print(f"Error deleting from S3: {e}")
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
