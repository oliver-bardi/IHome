# Válaszd a kívánt alap képet (pl. Python, Node.js, stb.)
FROM python:3.9-slim
# Install Flask and Werkzeug with compatible versions
FROM python:3.9-slim

# Telepítjük a szükséges csomagokat
RUN pip install Flask==2.1.2 werkzeug==2.0.3

# További Docker beállítások


# A szükséges fájlok másolása a konténerbe
COPY requirements.txt .

# Követelmények telepítése
RUN pip install -r requirements.txt

# Az alkalmazás másolása
COPY . .

# Alkalmazás futtatása
CMD ["python", "app.py"]


