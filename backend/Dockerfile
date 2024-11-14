# Alap image Python 3.9
FROM python:3.9

# Mappa létrehozása az alkalmazáshoz
WORKDIR /app

# Követelmények másolása és telepítése
COPY requirements.txt .
RUN pip install -r requirements.txt

# Alkalmazás fájlok másolása
COPY . .

# Indítási parancs a FastAPI szerverhez
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

