#!/bin/bash

# Fix dependencies script
# This script removes the wrong 'jose' package and installs the correct 'python-jose'

echo "Fixing Python dependencies..."

# Uninstall the wrong jose package
pip uninstall -y jose

# Install the correct python-jose package
pip install "python-jose[cryptography]==3.3.0"

# Reinstall all requirements to ensure everything is correct
pip install -r requirements.txt

echo "Dependencies fixed! You can now run: python run.py"
