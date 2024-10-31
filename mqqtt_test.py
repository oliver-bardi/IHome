import paho.mqtt.client as mqtt
import mysql.connector
import json
import matplotlib.pyplot as plt
from datetime import datetime
import matplotlib.dates as mdates

# MySQL adatbázis kapcsolat
try:
    db = mysql.connector.connect(
        host="192.168.137.1",  # Cseréld le az IP-t, ha szükséges
        user="root",
        password="my-secret-pw",
        database="home_automation"
    )
    cursor = db.cursor()
    print("Sikeres MySQL kapcsolódás!")
except mysql.connector.Error as err:
    print(f"MySQL kapcsolódási hiba: {err}")
    exit()

sensor_values = []
timestamps = []
historic_sensor_values = []
historic_timestamps = []

# Korábbi adatok betöltése az adatbázisból
try:
    cursor.execute("SELECT sensor_value, timestamp FROM sensor_data ORDER BY timestamp ASC")
    result = cursor.fetchall()
    for row in result:
        historic_sensor_values.append(row[0])
        historic_timestamps.append(row[1])  # Már datetime objektumként jön vissza
    print("Korábbi adatok betöltése sikeres!")
except mysql.connector.Error as err:
    print(f"Adatok lekérdezése sikertelen: {err}")

# Grafikon beállítása
fig, ax = plt.subplots()
line_real_time, = ax.plot([], [], label='Valós idejű adatok', color='red')
line_historic, = ax.plot(historic_timestamps, historic_sensor_values, label='Korábbi adatok', color='blue')
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
plt.xlabel('Idő')
plt.ylabel('Szenzor értékek')
plt.legend()
plt.ion()  # Interaktív mód bekapcsolása

# Csak a vonal adatait frissítjük, nem az egész ablakot
def update_graph():
    line_real_time.set_data(timestamps, sensor_values)
    ax.relim()  # Újra beállítja az értékhatárokat
    ax.autoscale_view(True, True, True)
    fig.canvas.draw()
    fig.canvas.flush_events()  # Az új adatok gyors frissítése

# MQTT üzenet fogadása és adatbázisba mentés
def on_message(client, userdata, message):
    print("MQTT üzenet fogadva!")  # Ellenőrizni, hogy üzenet érkezik-e
    try:
        data = json.loads(message.payload)
        sensor_value = data['sensor_value']
        switch_1_state = data['switch_1_state']
        switch_2_state = data['switch_2_state']
        switch_3_state = data['switch_3_state']

        # Adatok beszúrása az adatbázisba
        query = "INSERT INTO sensor_data (sensor_value, switch_1_state, switch_2_state, switch_3_state, timestamp) VALUES (%s, %s, %s, %s, %s)"
        values = (sensor_value, switch_1_state, switch_2_state, switch_3_state, datetime.now())
        cursor.execute(query, values)
        db.commit()
        print(f"Adatok mentése sikeres: {sensor_value}, {switch_1_state}, {switch_2_state}, {switch_3_state}")
        
        # Adatok hozzáadása a listához a grafikonhoz
        sensor_values.append(sensor_value)
        timestamps.append(datetime.now())  # Aktuális időbélyeggel

        # Grafikon frissítése
        update_graph()

    except Exception as e:
        print(f"Adatfeldolgozási hiba: {e}")

# MQTT beállítás
client = mqtt.Client()  # Ez a sor felelős a kliens létrehozásáért
try:
    client.connect("192.168.137.1", 1883, 60)  # Cseréld le az IP-címet
    print("Sikeres MQTT kapcsolat!")
except Exception as e:
    print(f"MQTT kapcsolódási hiba: {e}")
    exit()

client.subscribe("home/sensor_data")
client.on_message = on_message

# MQTT üzenetek figyelésének indítása
client.loop_start()

# Grafikon folyamatos megjelenítése
while True:
    plt.pause(1)