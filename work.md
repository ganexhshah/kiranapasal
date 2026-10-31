# KRM Kirana App — Run on Physical Android Phone via USB

Follow these simple steps to run the mobile app on your Android phone with the local backend working seamlessly.

---

## 🚀 Quick Start (In 3 Simple Steps)

### Step 1: Ensure Backend is Running
Open a terminal in `n:\krm\backend` and make sure your Docker containers are running:
```powershell
cd n:\krm\backend
docker compose up -d
```
*(To verify, open `http://localhost` in your PC browser — you should see `{"status":"online"}`).*

---

### Step 2: Plug in Phone & Forward Port (USB)

1. Connect your Android phone to your PC with a **USB cable**.
2. Make sure **USB Debugging** is turned **ON** in your phone's Developer Options.
3. Open a terminal and run these two commands:

```powershell
# 1. Check your phone is connected
adb devices

# 2. Forward phone port 8000 to PC port 80 (Backend)
adb reverse tcp:8000 tcp:80
```

> **Why this works**: Android apps cannot access your PC's `localhost` directly. Running `adb reverse tcp:8000 tcp:80` creates a high-speed direct tunnel through the USB cable. The app automatically connects to `http://localhost:8000/api/v1`, which instantly reaches your PC's Docker backend!

---

### Step 3: Run the Flutter App on Your Phone

Open a terminal in `n:\krm\app` and run:
```powershell
cd n:\krm\app
flutter run
```
*If multiple devices are detected, Flutter will ask you to pick your phone (e.g. `1` or your device ID).*

---

## 🔑 Login Options Available in App

Once the app opens on your phone, you can test any of these methods:

1. **Continue with Google** *(One-tap Google Sign-In)*:
   - Tap **"Continue with Google"**
   - Pick your Google account from the popup
   - **First-time sign-in**: Automatically takes you to **Shop Onboarding** where you can customize your store name, shop address, and details.
   - **Returning user**: Directly takes you to your store dashboard!

2. **Email / Phone Login**:
   - **Email**: `ganesh@krmstore.com`
   - **Password**: `password123`
   - Tap **Login**

3. **Create Account (New Registration)**:
   - Tap **"Create Account"**
   - Enter your name, your actual email, shop name, and password
   - Check your email inbox for the **6-digit verification code** sent via Resend
   - Enter the code to activate your account!

---

## 🛠️ Helpful Troubleshooting

| Issue | Quick Solution |
| :--- | :--- |
| **`adb: device unauthorized`** | Unlock your phone screen and tap **"Allow USB Debugging"** on the popup. |
| **`adb: command not found`** | Add Android SDK platform-tools to PATH, or use: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:80` |
| **Network Error in App** | Re-run: `adb reverse tcp:8000 tcp:80` (this must be re-run whenever you unplug and replug the USB cable). |
| **Wi-Fi Alternative (Without USB Cable)** | If you want to use Wi-Fi instead of USB, connect both PC and phone to the same Wi-Fi (`192.168.18.13`), then inside the app or in `api_config.dart`, the URL is `http://192.168.18.13/api/v1`. |

