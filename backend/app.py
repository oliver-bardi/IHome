import paho.mqtt.client as mqtt
import mysql.connector
import json
import tkinter as tk
from tkinter import messagebox
from datetime import datetime
import time

# MySQL adatbázis kapcsolat
def reconnect_db():
    global db, cursor
    try:
        print("Reconnecting to MySQL...")
        db = mysql.connector.connect(
            host="192.168.137.1",  # Frissítsd a megfelelő IP-címre
            user="root",  # MySQL felhasználónév
            password="rootpassword",  # MySQL jelszó
            database="home_automation"
        )
        cursor = db.cursor()
        print("MySQL connection re-established.")
    except mysql.connector.Error as err:
        print(f"Error reconnecting to MySQL: {err}")
        exit()

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
        cursor.execute(query, (switch_name, state == "ON", datetime.now()))
        db.commit()
    except mysql.connector.errors.OperationalError as e:
        print(f"MySQL connection lost: {e}")
        reconnect_db()  # Reconnect to the database if the connection is lost
        cursor.execute(query, (switch_name, state == "ON", datetime.now()))
        db.commit()

# Funkció a szenzoradatok mentésére az adatbázisba
def save_sensor_data_to_db(sensor_name, temperature, humidity):
    try:
        query = "INSERT INTO sensors (name, temperature, humidity, timestamp) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (sensor_name, temperature, humidity, datetime.now()))
        db.commit()
    except mysql.connector.errors.OperationalError as e:
        print(f"MySQL connection lost: {e}")
        reconnect_db()  # Reconnect to the database if the connection is lost
        cursor.execute(query, (sensor_name, temperature, humidity, datetime.now()))
        db.commit()

# MQTT callback az üzenetek kezelésére
def on_message(client, userdata, message):
    try:
        data = json.loads(message.payload)

        switchStates = data['switchStates']
        for switch, state in switchStates.items():
            switch_states[switch] = (state == "ON")
            print(f"switch {switch} state: {state}")
            save_switch_state_to_db(switch, state)

        # Szenzoradatok mentése
        temperature1 = data['temperature1']
        humidity1 = data['humidity1']
        temperature2 = data['temperature2']
        humidity2 = data['humidity2']

        save_sensor_data_to_db("Sensor 1", temperature1, humidity1)
        save_sensor_data_to_db("Sensor 2", temperature2, humidity2)

    except Exception as e:
        print(f"Error processing message: {e}")

# Funkció a kapcsoló állapotának váltására
def toggle_switch(switch_name, button):
    current_state = switch_states[switch_name]
    new_state = not current_state
    switch_states[switch_name] = new_state
    state_text = "ON" if new_state else "OFF"

    # Az új állapotot elküldjük MQTT-n
    client.publish(f"home/switch/{switch_name}/set", state_text)
    print(f"{switch_name} állapota: {state_text}")

    # Gomb színének frissítése az új állapot alapján
    button.config(bg="green" if new_state else "red")

    # Mentjük az állapotot az adatbázisba
    save_switch_state_to_db(switch_name, state_text)

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

# Tkinter GUI beállítása
def create_gui():
    root = tk.Tk()
    root.title("Kapcsolók kezelése")

    # Gombok létrehozása minden kapcsolóhoz
    buttons = {}
    for i, switch_name in enumerate(switch_states.keys()):
        btn = tk.Button(root, text=switch_name, width=20, height=2)

        # Módosított lambda, hogy minden kapcsolóhoz a megfelelő 'switch_name' és 'btn' legyen társítva
        btn.config(command=lambda s=switch_name, b=btn: toggle_switch(s, b))
        btn.grid(row=i // 3, column=i % 3, padx=10, pady=10)
        buttons[switch_name] = btn

    # Kapcsolók állapotainak periodikus mentése az adatbázisba minden 5 másodpercben
    def save_switches_periodically():
        for switch_name, state in switch_states.items():
            save_switch_state_to_db(switch_name, "ON" if state else "OFF")
        root.after(5000, save_switches_periodically)  # 5 másodpercenként mentés

    root.after(5000, save_switches_periodically)  # Kezdjük el a periodikus mentést 5 másodperces intervallumban
    root.mainloop()


# GUI futtatása
create_gui()
