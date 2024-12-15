# Python alapképfájl
FROM python:3.9-slim

# Munka mappa beállítása
WORKDIR /app

# Függőségek másolása és telepítése
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Alkalmazás másolása
COPY . .

# Gunicorn futtatása
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

