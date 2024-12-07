# Válaszd a kívánt alap képet (pl. Python)
FROM python:3.9-slim

# Környezeti változók beállítása (pl. hogy a Python ne tároljon cache fájlokat)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Rendszerszintű frissítések és alapvető csomagok telepítése
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# A szükséges Python csomagok telepítése
RUN pip install Flask==2.1.2 werkzeug==2.0.3

# A szükséges fájlok másolása a konténerbe
WORKDIR /app
COPY requirements.txt /app/

# Követelmények telepítése a requirements.txt fájlból
RUN pip install --no-cache-dir -r requirements.txt

# Az alkalmazás másolása
COPY . /app/

# A megfelelő port megnyitása a Flask alkalmazás számára
EXPOSE 5000

# Alkalmazás futtatása
CMD ["python", "app.py"]
