import os
import mysql.connector

db = mysql.connector.connect(
    host=os.getenv("DATABASE_HOST", "db"),  # Alapértelmezett érték a 'db' szolgáltatásnév
    user=os.getenv("DATABASE_USER", "root"),
    password=os.getenv("DATABASE_PASSWORD", "rootpassword"),
    database=os.getenv("DATABASE_NAME", "home_automation")
)

# Az állapot frissítése adatbázisban
def update_status_in_db(module, status):
    cursor = db.cursor()
    cursor.execute("UPDATE devices SET status = %s WHERE name = %s", (status, module))
    db.commit()

# Állapot lekérdezése adatbázisból
def get_status_from_db(module):
    cursor = db.cursor()
    cursor.execute("SELECT status FROM devices WHERE name = %s", (module,))
    return cursor.fetchone()[0]
