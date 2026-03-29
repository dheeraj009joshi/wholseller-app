# Environment Variables Configuration

## Setup Instructions

1. Copy the `.env` file and fill in your values:
   ```bash
   cp .env .env.local  # Optional: create a local override
   ```

2. Edit `.env` with your actual values

## Required Configuration

### MongoDB
```env
MONGODB_URL=mongodb://localhost:27017
# Or for MongoDB Atlas:
# MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/
DATABASE_NAME=wholeseller_db
```

### JWT Authentication
```env
SECRET_KEY=your-very-long-random-secret-key-here-minimum-32-characters
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**Generate a secure secret key:**
```python
import secrets
print(secrets.token_urlsafe(32))
```

### Azure Blob Storage (Optional)
If not configured, placeholder images will be used.

```env
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=your_account;AccountKey=your_key;EndpointSuffix=core.windows.net
AZURE_STORAGE_CONTAINER_NAME=wholeseller-images
```

**How to get Azure connection string:**
1. Go to Azure Portal
2. Navigate to your Storage Account
3. Go to "Access Keys"
4. Copy the "Connection string" from key1 or key2

### SMTP Email Configuration

#### Gmail Setup
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@wholeseller.com
SMTP_FROM_NAME=Wholeseller
```

**Gmail App Password:**
1. Go to Google Account settings
2. Security > 2-Step Verification (enable if not enabled)
3. App passwords > Generate app password
4. Use the generated password (not your regular Gmail password)

#### Other Email Providers

**Outlook/Hotmail:**
```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
```

**SendGrid:**
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

**Custom SMTP:**
```env
SMTP_HOST=your-smtp-server.com
SMTP_PORT=587  # or 465 for SSL
SMTP_USER=your-username
SMTP_PASSWORD=your-password
```

### Server Configuration
```env
API_HOST=0.0.0.0  # Listen on all interfaces
API_PORT=8000
DEBUG=True  # Set to False in production
```

### CORS Configuration
```env
# Comma-separated list of allowed origins
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,https://yourdomain.com
```

## Production Checklist

- [ ] Change `SECRET_KEY` to a strong random value
- [ ] Set `DEBUG=False`
- [ ] Configure proper `ALLOWED_ORIGINS`
- [ ] Use secure MongoDB connection (MongoDB Atlas recommended)
- [ ] Configure Azure Blob Storage for images
- [ ] Set up SMTP for email notifications
- [ ] Use environment-specific `.env` files
- [ ] Never commit `.env` to version control

## Testing Configuration

After setting up `.env`, test the configuration:

```bash
# Test MongoDB connection
python -c "from app.database import database; import asyncio; asyncio.run(database.connect())"

# Test email (if configured)
python -c "from app.email_service import send_email; import asyncio; asyncio.run(send_email('test@example.com', 'Test', 'Test email'))"
```

## Troubleshooting

### MongoDB Connection Issues
- Verify MongoDB is running: `mongosh` or check service status
- Check connection string format
- For Atlas, ensure IP whitelist includes your IP

### Email Not Sending
- Verify SMTP credentials
- Check firewall/network allows SMTP port
- For Gmail, ensure app password is used (not regular password)
- Check spam folder

### Azure Storage Issues
- Verify connection string format
- Check storage account exists and is accessible
- Ensure container name is correct
- Images will use placeholders if Azure not configured (this is OK)
