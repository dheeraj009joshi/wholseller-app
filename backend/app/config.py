import os
from typing import List
from dotenv import load_dotenv

# Load .env file
load_dotenv()


class Settings:
    """Application settings loaded from environment variables"""
    
    # MongoDB
    mongodb_url: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    database_name: str = os.getenv("DATABASE_NAME", "wholeseller_db")
    
    # JWT
    secret_key: str = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
    algorithm: str = os.getenv("ALGORITHM", "HS256")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))
    
    # Azure Blob Storage
    azure_storage_connection_string: str = os.getenv("AZURE_STORAGE_CONNECTION_STRING", "DefaultEndpointsProtocol=https;AccountName=tikuntechwebimages;AccountKey=JBh4LIsNPWZ47xjknDD/kZrckTi3zLpvcnBig/8tE6x/cGJo099cNIZoqhv8lndro36VbflqEW0q+AStjIPodQ==;EndpointSuffix=core.windows.net")
    azure_storage_container_name: str = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "wholesaleimages")
    
    # SMTP
    smtp_host: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_user: str = os.getenv("SMTP_USER", "")
    smtp_password: str = os.getenv("SMTP_PASSWORD", "")
    smtp_from_email: str = os.getenv("SMTP_FROM_EMAIL", "noreply@wholeseller.com")
    smtp_from_name: str = os.getenv("SMTP_FROM_NAME", "Wholeseller")
    
    # Server
    api_host: str = os.getenv("API_HOST", "0.0.0.0")
    api_port: int = int(os.getenv("API_PORT", "8000"))
    debug: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # CORS
    @property
    def allowed_origins(self) -> List[str]:
        origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080")
        return [origin.strip() for origin in origins.split(",") if origin.strip()]


settings = Settings()
