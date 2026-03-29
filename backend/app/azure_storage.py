from azure.storage.blob import BlobServiceClient
from app.config import settings
from typing import Optional
import uuid
from io import BytesIO
from PIL import Image

_blob_service_client = None


def get_blob_service_client():
    global _blob_service_client
    if _blob_service_client is None and settings.azure_storage_connection_string:
        _blob_service_client = BlobServiceClient.from_connection_string(
            settings.azure_storage_connection_string
        )
    return _blob_service_client


async def upload_image_to_azure(file_content: bytes, filename: str, folder: str = "products") -> Optional[str]:
    """
    Upload image to Azure Blob Storage
    Returns the URL of the uploaded image
    """
    if not settings.azure_storage_connection_string:
        # Fallback: return placeholder URL if Azure not configured
        return f"https://via.placeholder.com/400?text={filename}"
    
    try:
        blob_service_client = get_blob_service_client()
        if not blob_service_client:
            return None
        
        # Generate unique filename
        file_extension = filename.split('.')[-1] if '.' in filename else 'jpg'
        unique_filename = f"{folder}/{uuid.uuid4()}.{file_extension}"
        
        # Get container client
        container_client = blob_service_client.get_container_client(settings.azure_storage_container_name)
        
        # Create container if it doesn't exist
        if not container_client.exists():
            container_client.create_container()
        
        # Optimize image if it's an image file
        try:
            image = Image.open(BytesIO(file_content))
            # Resize if too large (max 2000px on longest side)
            max_size = 2000
            if max(image.size) > max_size:
                image.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
            # Convert to RGB if necessary
            if image.mode in ('RGBA', 'LA', 'P'):
                rgb_image = Image.new('RGB', image.size, (255, 255, 255))
                if image.mode == 'P':
                    image = image.convert('RGBA')
                rgb_image.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
                image = rgb_image
            
            # Save optimized image
            output = BytesIO()
            image.save(output, format='JPEG', quality=85, optimize=True)
            file_content = output.getvalue()
        except Exception:
            # If not an image or processing fails, use original
            pass
        
        # Upload blob
        blob_client = container_client.get_blob_client(unique_filename)
        blob_client.upload_blob(file_content, overwrite=True, content_type=f"image/{file_extension}")
        
        # Return the URL
        return blob_client.url
        
    except Exception as e:
        print(f"Error uploading to Azure: {e}")
        return None


async def delete_image_from_azure(blob_url: str) -> bool:
    """
    Delete image from Azure Blob Storage
    """
    if not settings.azure_storage_connection_string or not blob_url:
        return False
    
    try:
        blob_service_client = get_blob_service_client()
        if not blob_service_client:
            return False
        
        # Extract blob name from URL
        container_name = settings.azure_storage_container_name
        blob_name = blob_url.split(f"{container_name}/")[-1].split("?")[0]
        
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        blob_client.delete_blob()
        return True
    except Exception as e:
        print(f"Error deleting from Azure: {e}")
        return False
