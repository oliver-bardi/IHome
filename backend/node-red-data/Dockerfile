# Alap Node-RED image
FROM nodered/node-red:latest

# Munkakönyvtár beállítása
WORKDIR /data

# Root jogok ideiglenes engedélyezése
USER root

# Szükséges Node-RED pluginok telepítése
RUN npm install --unsafe-perm --no-cache \
    node-red-dashboard \
    node-red-node-openweathermap \
    && npm cache clean --force

# Node-RED alapértelmezett felhasználóra visszaállás
USER node-red

# Alapértelmezett parancs
CMD ["npm", "start", "--", "--userDir", "/data"]
