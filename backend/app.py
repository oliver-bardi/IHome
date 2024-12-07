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
        host="192.168.137.1",  # Frissítsd a megfelelő IP-címre
        user="root",
        password="rootpassword",  # Helyes jelszó
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

# Flask útvonal a kapcsolók állapotának lekérésére
@app.route("/switches", methods=["GET"])
def get_switches():
    return jsonify(switch_states), 200

# Flask útvonal a kapcsolók állapotának beállítására
@app.route("/switches/<switch_id>", methods=["POST"])
def set_switch(switch_id):
    state = request.json.get("state")
    if switch_id in switch_states:
        switch_states[switch_id] = (state == "ON")
        client.publish(f"home/switch/{switch_id}/set", state)
        save_switch_state_to_db(switch_id, state)
        return jsonify({"status": "success", "switch": switch_id, "state": state}), 200
    return jsonify({"status": "error", "message": "Invalid switch ID"}), 400

# Flask útvonal a szenzoradatok lekérésére
@app.route("/sensors", methods=["GET"])
def get_sensors():
    try:
        query = "SELECT name, temperature, humidity, timestamp FROM sensors ORDER BY timestamp DESC LIMIT 10"
        cursor.execute(query)
        rows = cursor.fetchall()

        sensors = [
            {
                "name": row[0],
                "temperature": row[1],
                "humidity": row[2],
                "timestamp": row[3].strftime("%Y-%m-%d %H:%M:%S")
            }
            for row in rows
        ]
        return jsonify(sensors), 200
    except Exception as e:
        return jsonify({"error": f"Failed to retrieve sensor data: {str(e)}"}), 500

# MQTT kapcsolat beállítása
client = mqtt.Client()
client.on_message = on_message

try:
    client.connect("192.168.137.1", 1883, 60)  # Cseréld le az IP-címet
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
        # Indításkor minden kapcsoló állapotának mentése
        save_all_switch_states()
        # 15 másodpercenként mentés
        while True:
            time.sleep(15)
            save_all_switch_states()
    except KeyboardInterrupt:
        print("Program leállítva.")
