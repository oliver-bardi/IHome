import paho.mqtt.client as mqtt
import mysql.connector
import json
from flask import Flask, jsonify, request
from datetime import datetime
import pytz
import time
import threading

# Flask alkalmazás
app = Flask(__name__)

# Helyi időzóna
local_tz = pytz.timezone("Europe/Budapest")

def get_local_time():
    """Helyi idő generálása a megfelelő időzónával."""
    return datetime.now(local_tz)

# MySQL adatbázis kapcsolat
def reconnect_db():
    global db, cursor
    try:
        print("Reconnecting to MySQL...")
        db = mysql.connector.connect(
            host="192.168.137.1",  # IP-cím
            user="root",  # MySQL felhasználónév
            password="rootpassword",  # MySQL jelszó
            database="home_automation"
        )
        cursor = db.cursor()
        print("MySQL connection re-established.")
    except mysql.connector.Error as err:
        print(f"Error reconnecting to MySQL: {err}")
        exit()

def wait_for_db(timeout=30):
    """Várakozás az adatbázis elérhetőségére."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            db = mysql.connector.connect(
                host="192.168.137.1",  # IP-cím
                user="root",  # MySQL felhasználónév
                password="rootpassword",  # MySQL jelszó
                database="home_automation"
            )
            db.close()
            print("Adatbázis elérhető.")
            return
        except mysql.connector.Error:
            print("Várakozás az adatbázis elérhetőségére...")
            time.sleep(2)
    print("Adatbázis nem érhető el a megadott idő alatt.")
    exit()

# Induláskor vár az adatbázis elérhetőségére
wait_for_db()

try:
    db = mysql.connector.connect(
        host="192.168.137.1",
        user="root",
        password="rootpassword",
        database="home_automation"
    )
    cursor = db.cursor()
    print("Sikeres MySQL kapcsolódás!")
except mysql.connector.Error as err:
    print(f"MySQL kapcsolódási hiba: {err}")
    exit()

# Switch states
switch_states = {f"{i}": False for i in range(15)}

# Funkció a kapcsolók állapotának mentésére az adatbázisba
def save_switch_state_to_db(switch_name, state):
    try:
        query = "INSERT INTO switches (name, state, timestamp) VALUES (%s, %s, %s)"
        cursor.execute(query, (switch_name, state == "ON", get_local_time()))
        db.commit()
        print(f"Switch '{switch_name}' állapota mentve: {state}")
    except mysql.connector.errors.OperationalError as e:
        print(f"MySQL connection lost: {e}")
        reconnect_db()
        cursor.execute(query, (switch_name, state == "ON", get_local_time()))
        db.commit()

# Funkció a kapcsolók állapotainak mentésére
def save_all_switch_states():
    print("Minden kapcsoló állapotának mentése...")
    for switch_name, state in switch_states.items():
        save_switch_state_to_db(switch_name, "ON" if state else "OFF")

# Funkció a szenzoradatok mentésére az adatbázisba
def save_sensor_data_to_db(sensor_name, temperature, humidity):
    try:
        query = "INSERT INTO sensors (name, temperature, humidity, timestamp) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (sensor_name, temperature, humidity, get_local_time()))
        db.commit()
        print(f"Szenzor '{sensor_name}' adatai mentve: Temp={temperature}, Hum={humidity}")
    except mysql.connector.errors.OperationalError as e:
        print(f"MySQL connection lost: {e}")
        reconnect_db()
        cursor.execute(query, (sensor_name, temperature, humidity, get_local_time()))
        db.commit()

# MQTT callback az üzenetek kezelésére
def on_message(client, userdata, message):
    try:
        data = json.loads(message.payload)

        # Switch states mentése és naplózása
        switchStates = data.get('switchStates', {})
        for switch, state in switchStates.items():
            switch_states[switch] = (state == "ON")
            print(f"Switch {switch} állapota: {state}")
            save_switch_state_to_db(switch, state)

        # Szenzoradatok mentése és naplózása
        temperature1 = data.get('temperature1', None)
        humidity1 = data.get('humidity1', None)
        temperature2 = data.get('temperature2', None)
        humidity2 = data.get('humidity2', None)

        save_sensor_data_to_db("Sensor 1", temperature1, humidity1)
        save_sensor_data_to_db("Sensor 2", temperature2, humidity2)

        print(f"Szenzoradatok: Temp1={temperature1} Hum1={humidity1}, Temp2={temperature2} Hum2={humidity2}")

    except Exception as e:
        print(f"Error processing message: {e}")

# Funkció az alapértelmezett admin felhasználó hozzáadására
def add_default_admin():
    try:
        query = "SELECT id FROM users WHERE email = %s"
        cursor.execute(query, ("admin@gmail.com",))
        result = cursor.fetchone()

        if not result:
            query = "INSERT INTO users (id, name, email, password, role) VALUES (%s, %s, %s, %s, %s)"
            cursor.execute(query, (1, "admin", "admin@gmail.com", "admin", "ADMIN"))
            db.commit()
            print("Alapértelmezett admin felhasználó hozzáadva.")
        else:
            print("Admin felhasználó már létezik.")
    except Exception as e:
        print(f"Hiba történt az admin hozzáadásakor: {e}")

# Flask útvonalak
@app.route("/register", methods=["POST"])
def register_user():
    try:
        data = request.json
        missing_fields = [field for field in ["name", "email", "password", "confirm_password"] if not data.get(field)]
        if missing_fields:
            return jsonify({"status": "error", "message": f"Hiányzó mezők: {', '.join(missing_fields)}"}), 400
        if data["password"] != data["confirm_password"]:
            return jsonify({"status": "error", "message": "A jelszavak nem egyeznek"}), 400
        query = "INSERT INTO users (name, email, password, role) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (data["name"], data["email"], data["password"], "GUEST"))
        db.commit()
        return jsonify({"status": "success", "message": "Felhasználó sikeresen regisztrálva"}), 201
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/sensors", methods=["GET"])
def get_sensors():
    try:
        query = "SELECT name, temperature, humidity, timestamp FROM sensors ORDER BY timestamp DESC LIMIT 10"
        cursor.execute(query)
        rows = cursor.fetchall()
        sensors = [{"name": row[0], "temperature": row[1], "humidity": row[2], "timestamp": row[3].strftime("%Y-%m-%d %H:%M:%S")} for row in rows]
        return jsonify(sensors), 200
    except Exception as e:
        return jsonify({"error": f"Failed to retrieve sensor data: {str(e)}"}), 500

@app.route("/room_sensors", methods=["GET"])
def get_room_sensors():
    try:
        # Az adatbázisból lekérjük a legfrissebb adatokat minden szenzorhoz
        query = """
        SELECT name, temperature, humidity, MAX(timestamp) as latest
        FROM sensors
        WHERE name IN ('Sensor 1', 'Sensor 2')
        GROUP BY name;
        """
        cursor.execute(query)
        rows = cursor.fetchall()

        # Az adatokat szobák szerint rendezzük
        room_sensors = {}
        for row in rows:
            sensor_name = row[0]
            temperature = row[1]
            humidity = row[2]

            # A megfelelő szobához társítjuk az adatokat
            if sensor_name == "Sensor 1":
                room_sensors["Living Room"] = {
                    "temperature": temperature,
                    "humidity": humidity
                }
            elif sensor_name == "Sensor 2":
                room_sensors["Bedroom"] = {
                    "temperature": temperature,
                    "humidity": humidity
                }

        print(f"room_sensors API called. Returning: {room_sensors}")
        return jsonify(room_sensors), 200
    except Exception as e:
        print(f"Error in /room_sensors: {e}")
        return jsonify({"error": str(e)}), 500



@app.route("/add_user", methods=["POST"])
def add_user():
    """
    Felhasználó hozzáadása az adatbázishoz.
    """
    try:
        data = request.json
        print("Received data for new user:", data)

        # Ellenőrzés: minden szükséges mező megvan-e
        required_fields = ["name", "email", "password", "role"]
        missing_fields = [field for field in required_fields if not data.get(field)]
        if missing_fields:
            return jsonify({"status": "error", "message": f"Hiányzó mezők: {', '.join(missing_fields)}"}), 400

        # Ellenőrzés: email egyedi-e
        query = "SELECT id FROM users WHERE email = %s"
        cursor.execute(query, (data["email"],))
        if cursor.fetchone():
            return jsonify({"status": "error", "message": "Ez az email cím már regisztrálva van"}), 400

        # Felhasználó hozzáadása
        query = "INSERT INTO users (name, email, password, role) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (data["name"], data["email"], data["password"], data["role"]))
        db.commit()

        return jsonify({"status": "success", "message": f"Felhasználó '{data['name']}' sikeresen hozzáadva"}), 201
    except Exception as e:
        print("Error adding user:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 500


# Új végpont felhasználók lekérdezéséhez
@app.route("/users", methods=["GET"])
def get_users():
    """
    Az összes felhasználó lekérése az adatbázisból.
    """
    try:
        query = "SELECT id, name, email, role, created_at FROM users"
        cursor.execute(query)
        rows = cursor.fetchall()

        users = [
            {
                "id": row[0],
                "name": row[1],
                "email": row[2],
                "role": row[3],
                "created_at": row[4].strftime("%Y-%m-%d %H:%M:%S")
            }
            for row in rows
        ]
        return jsonify({"status": "success", "users": users}), 200
    except Exception as e:
        print("Error fetching users:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    query = "SELECT * FROM users WHERE email = %s AND password = %s"
    cursor.execute(query, (email, password))
    user = cursor.fetchone()

    if user:
        return jsonify({"message": "Login successful"}), 200
    else:
        return jsonify({"message": "Invalid email or password"}), 401


# Egy felhasználó törlése
@app.route("/delete_user/<int:user_id>", methods=["DELETE"])
def delete_user(user_id):
    """
    Felhasználó törlése az adatbázisból.
    """
    try:
        query = "DELETE FROM users WHERE id = %s"
        cursor.execute(query, (user_id,))
        db.commit()

        if cursor.rowcount == 0:
            return jsonify({"status": "error", "message": "Nincs ilyen felhasználó"}), 404

        return jsonify({"status": "success", "message": f"Felhasználó ID '{user_id}' sikeresen törölve"}), 200
    except Exception as e:
        print("Error deleting user:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/switches/<switch_id>", methods=["POST"])
def set_switch(switch_id):
    try:
        state = request.json.get("state")
        if switch_id not in switch_states:
            return jsonify({"status": "error", "message": "Invalid switch ID"}), 400
        switch_states[switch_id] = (state == "ON")
        client.publish(f"home/switch/{switch_id}/set", state)
        save_switch_state_to_db(switch_id, state)
        return jsonify({"status": "success", "switch": switch_id, "state": state}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/switch_states", methods=["GET"])
def get_switch_states():
    """
    Visszaadja az összes kapcsoló aktuális állapotát.
    """
    try:
        # A `switch_states` globális változóból olvassuk ki az állapotokat
        switch_states_response = {
            switch_id: "ON" if state else "OFF"
            for switch_id, state in switch_states.items()
        }
        return jsonify(switch_states_response), 200
    except Exception as e:
        print(f"Error fetching switch states: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# MQTT kapcsolat beállítása
client = mqtt.Client()
client.on_message = on_message

try:
    client.connect("192.168.137.1", 1883, 60)
    print("Sikeres MQTT kapcsolat!")
except Exception as e:
    print(f"MQTT kapcsolódási hiba: {e}")
    exit()

client.subscribe("home/status")
client.loop_start()

# Flask indítása külön szálban
def start_flask():
    print("Elérhető végpontok:", app.url_map)
    app.run(host="0.0.0.0", port=5000, debug=False)

flask_thread = threading.Thread(target=start_flask)
flask_thread.daemon = True
flask_thread.start()

# Main funkció futtatása
if __name__ == "__main__":
    print("Backend fut...")
    try:
        add_default_admin()
        save_all_switch_states()
        while True:
            time.sleep(15)
            save_all_switch_states()
    except KeyboardInterrupt:
        print("Program leállítva.")
