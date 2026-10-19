# 💧 Jal Jeevan Mission - Citizen Feedback Portal

An offline-first, multilingual mobile application and live dashboard designed to help rural citizens report water supply grievances, even in areas with zero internet connectivity.

## 🚀 The Architecture
Traditional apps fail in rural areas due to intermittent network availability. This system solves that using an **Offline-First Architecture**:
1. **Capture:** Citizens log issues (Text, GPS, Photo) via the Flutter app.
2. **Cache:** If offline, data is securely cached locally using **SQLite**.
3. **Auto-Sync:** A background network listener (`connectivity_plus`) detects when the device reconnects to the internet and automatically pushes the cached payload to the backend without user intervention.
4. **Dashboard:** The Python backend receives the multipart data and instantly populates a live-refreshing web dashboard for government admins.

## 🛠 Tech Stack
* **Frontend Mobile:** Flutter, Dart
* **Local Storage:** SQLite (sqflite)
* **Backend Server:** Python, FastAPI, Uvicorn
* **Hardware Integration:** `geolocator` (GPS mapping), `image_picker` (Camera)
* **Localization:** English, Hindi, and Marathi native support

## ⚙️ Running the Project
**1. Start the Server**
Open the `SIH-2` directory in your terminal and launch the FastAPI server:
`python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload`

**2. Open the Dashboard**
Navigate to `http://localhost:8000` in any web browser to view the live admin panel.

**3. Run the Mobile App**
Ensure the mobile device is on the same local network as the server, then launch the app natively on the device. Toggle Wi-Fi off to test local SQLite caching, and turn it back on to witness the background auto-sync push data to the web dashboard.