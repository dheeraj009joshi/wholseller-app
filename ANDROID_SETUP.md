# Running Flutter App on Android

## Prerequisites

1. ✅ Backend is running on `http://localhost:8000`
2. ✅ Android Studio installed
3. ✅ Flutter SDK installed and configured
4. ✅ Android device or emulator ready

## Step 1: Check Flutter Setup

```bash
flutter doctor
```

Make sure Android toolchain is properly configured.

## Step 2: Start Android Emulator or Connect Physical Device

### Option A: Android Emulator

1. Open Android Studio
2. Go to Tools > Device Manager
3. Start an emulator (or create one if needed)
4. Verify it's running: `flutter devices`

### Option B: Physical Android Device

1. Enable Developer Options on your phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings > Developer Options > USB Debugging (ON)
3. Connect phone via USB
4. Verify connection: `flutter devices`

## Step 3: Configure API URL

The app is already configured to use:
- **Android Emulator**: `http://10.0.2.2:8000/api` (automatically maps to host's localhost)
- **iOS Simulator**: `http://localhost:8000/api`
- **Physical Device**: You need to use your computer's IP address

### For Physical Android Device:

1. Find your computer's local IP address:

   **macOS/Linux:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # Look for something like: 192.168.1.XXX or 192.168.0.XXX
   ```

   **Windows:**
   ```bash
   ipconfig
   # Look for IPv4 Address under your network adapter
   ```

2. Update `lib/config/api_config.dart`:
   ```dart
   static String get baseUrl {
     if (Platform.isAndroid) {
       // For physical device, use your computer's IP
       return 'http://192.168.1.XXX:8000/api';  // Replace XXX with your IP
       // For emulator, use:
       // return 'http://10.0.2.2:8000/api';
     }
     // ... rest of code
   }
   ```

3. **Important**: Make sure your phone and computer are on the same WiFi network!

## Step 4: Ensure Backend is Accessible

### For Android Emulator:
- Backend should be running on `localhost:8000`
- The emulator automatically maps `10.0.2.2` to `localhost`

### For Physical Device:
- Backend must be accessible from your network
- Check firewall settings (allow port 8000)
- Backend should be running on `0.0.0.0:8000` (already configured in `.env`)

## Step 5: Install Dependencies

```bash
cd /Users/dheeraj/Development/Work_Dheeraj/Kabir/wholeseller
flutter pub get
```

## Step 6: Run the App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run (will use default device)
flutter run
```

## Step 7: Verify Connection

1. App should start and show the landing screen
2. Try to register/login
3. Check backend logs to see if requests are coming through
4. If you see connection errors, check:
   - Backend is running
   - Correct API URL in `api_config.dart`
   - Firewall settings
   - Network connectivity

## Troubleshooting

### "Connection refused" or "Failed to connect"

**For Emulator:**
- Make sure backend is running on `localhost:8000`
- Try: `curl http://localhost:8000/api/health` (should work from terminal)

**For Physical Device:**
- Verify computer's IP address is correct
- Ensure phone and computer are on same WiFi
- Check firewall allows port 8000
- Try accessing `http://YOUR_IP:8000/api/health` from phone's browser

### "No devices found"

```bash
# Check devices
flutter devices

# If no devices, try:
adb devices  # Should show your device

# Restart adb if needed
adb kill-server
adb start-server
```

### Backend not accessible from network

1. Check `.env` file has:
   ```
   API_HOST=0.0.0.0
   API_PORT=8000
   ```

2. Restart backend after changing `.env`

3. Check firewall:
   ```bash
   # macOS: Allow incoming connections on port 8000
   # System Preferences > Security & Privacy > Firewall > Firewall Options
   ```

### Hot Reload not working

- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Quick Test

After running the app:

1. Open the app on your device
2. Try to register a new account
3. Check backend terminal - you should see the request
4. If successful, you're connected! 🎉

## Network Configuration Summary

| Platform | API URL | Notes |
|----------|---------|-------|
| Android Emulator | `http://10.0.2.2:8000/api` | Auto-configured |
| iOS Simulator | `http://localhost:8000/api` | Auto-configured |
| Physical Android | `http://YOUR_IP:8000/api` | Need to set manually |
| Physical iOS | `http://YOUR_IP:8000/api` | Need to set manually |

## Next Steps

Once connected:
- Test user registration
- Test login
- Browse products
- Add to cart
- Place orders

Enjoy your fully connected B2B wholesale marketplace! 🚀
