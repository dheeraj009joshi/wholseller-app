# Fixing Backend Errors

## Issue: Wrong `jose` Package Installed

The error shows that the wrong `jose` package (Python 2 version) is installed instead of `python-jose` (Python 3 version).

### Quick Fix

Run this command in your virtual environment:

```bash
cd backend
source venv/bin/activate  # or: source vevn/bin/activate (if your venv is named vevn)

# Uninstall the wrong package
pip uninstall -y jose

# Install the correct package
pip install "python-jose[cryptography]==3.3.0"

# Reinstall all requirements
pip install -r requirements.txt
```

### Or use the fix script:

```bash
cd backend
source venv/bin/activate  # or: source vevn/bin/activate
bash fix_dependencies.sh
```

## After Fixing

1. Make sure your `.env` file is configured (see `README_ENV.md`)
2. Start MongoDB (if using local MongoDB)
3. Run the backend:
   ```bash
   python run.py
   ```

## Verification

The backend should start without errors and show:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started server process
Connected to MongoDB: wholeseller_db
```

## Common Issues

### If you still get import errors:
```bash
# Clear pip cache and reinstall
pip cache purge
pip install --force-reinstall -r requirements.txt
```

### If MongoDB connection fails:
- Check MongoDB is running: `mongosh` or check service status
- Verify `MONGODB_URL` in `.env` file
- For MongoDB Atlas, check IP whitelist

### If port 8000 is already in use:
- Change `API_PORT` in `.env` to a different port (e.g., 8001)
- Or stop the process using port 8000
