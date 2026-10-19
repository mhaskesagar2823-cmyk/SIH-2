import sqlite3
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

app = FastAPI()

# Create directory for images
os.makedirs("uploaded_grievances", exist_ok=True)

# 1. Allow the web browser to access the image folder
app.mount("/uploaded_grievances", StaticFiles(directory="uploaded_grievances"), name="uploaded_grievances")

# Initialize SQLite Database
def init_db():
    conn = sqlite3.connect("grievances.db")
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS grievances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            image_path TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()

# 2. Serve the HTML Web Dashboard
@app.get("/")
async def serve_dashboard():
    return FileResponse("dashboard.html")

# 3. API endpoint to fetch all database records for the dashboard
@app.get("/api/all_grievances")
async def get_all_grievances():
    conn = sqlite3.connect("grievances.db")
    conn.row_factory = sqlite3.Row  # Returns data as dictionaries
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM grievances ORDER BY id DESC")
    records = cursor.fetchall()
    conn.close()
    return [dict(row) for row in records]

# Existing POST endpoint from mobile
@app.post("/api/grievances")
async def receive_grievance(
    user_id: str = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    timestamp: str = Form(...),
    image: UploadFile = File(None)
):
    image_location = ""
    if image:
        image_location = f"uploaded_grievances/{image.filename}"
        with open(image_location, "wb") as f:
            f.write(await image.read())

    conn = sqlite3.connect("grievances.db")
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO grievances (user_id, description, latitude, longitude, timestamp, image_path)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (user_id, description, latitude, longitude, timestamp, image_location))
    conn.commit()
    conn.close()

    print(f"Saved to Database: {description} at {latitude},{longitude}")
    return {"message": "Grievance successfully saved"}