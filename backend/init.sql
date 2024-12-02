CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  role VARCHAR(50) NOT NULL COMMENT 'admin, subuser, guest',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL COMMENT 'e.g., Living Room, Garden',
  floor INT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS devices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL COMMENT 'Device name, e.g., Smart Light',
  device_type VARCHAR(50) NOT NULL COMMENT 'e.g., Light, Thermostat, Gate',
  room_id INT,
  user_id INT,
  status VARCHAR(50) NOT NULL COMMENT 'Device status, e.g., on, off, active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (room_id) REFERENCES rooms(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS sensors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL COMMENT 'e.g., Temperature Sensor, Motion Sensor',
  sensor_type VARCHAR(50) NOT NULL COMMENT 'e.g., Temperature, Motion, Soil Moisture',
  room_id INT,
  status VARCHAR(50) NOT NULL COMMENT 'Sensor status, e.g., active, inactive',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE IF NOT EXISTS readings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sensor_id INT,
  value NUMERIC(10, 2) NOT NULL COMMENT 'Recorded value from sensor, e.g., temperature in °C',
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sensor_id) REFERENCES sensors(id)
);

CREATE TABLE IF NOT EXISTS automations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL COMMENT 'e.g., Night Light Automation',
  trigger_type VARCHAR(50) NOT NULL COMMENT 'e.g., time, sensor trigger',
  action VARCHAR(100) NOT NULL COMMENT 'e.g., turn on light, adjust thermostat',
  status VARCHAR(50) NOT NULL COMMENT 'enabled, disabled',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS automation_conditions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  automation_id INT,
  condition_type VARCHAR(100) NOT NULL COMMENT 'e.g., sensor reading threshold',
  condition_value VARCHAR(100) NOT NULL COMMENT 'e.g., >25°C, motion detected',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (automation_id) REFERENCES automations(id)
);

CREATE TABLE IF NOT EXISTS logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  device_id INT,
  action VARCHAR(100) NOT NULL COMMENT 'e.g., turned on, motion detected',
  user_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (device_id) REFERENCES devices(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS permissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  device_id INT,
  permission_level VARCHAR(50) NOT NULL COMMENT 'e.g., full, control, view only',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);
