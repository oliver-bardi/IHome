CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL COMMENT 'admin, subuser, guest',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rooms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL COMMENT 'e.g., Living Room, Garden',
    floor INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL COMMENT 'Device name, e.g., Smart Light',
    device_type VARCHAR(50) NOT NULL COMMENT 'e.g., Light, Thermostat, Gate',
    room_id INT,
    user_id INT,
    status VARCHAR(50) COMMENT 'Device status, e.g., on, off, active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE sensors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL COMMENT 'e.g., Temperature Sensor, Motion Sensor',
    sensor_type VARCHAR(50) NOT NULL COMMENT 'e.g., Temperature, Motion, Soil Moisture',
    room_id INT,
    status VARCHAR(50) COMMENT 'Sensor status, e.g., active, inactive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE readings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sensor_id INT,
    value DECIMAL(10, 2) COMMENT 'Recorded value from sensor, e.g., temperature in °C',
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES sensors(id)
);

CREATE TABLE automations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL COMMENT 'e.g., Night Light Automation',
    trigger_type VARCHAR(50) COMMENT 'e.g., time, sensor trigger',
    action VARCHAR(255) COMMENT 'e.g., turn on light, adjust thermostat',
    status VARCHAR(50) COMMENT 'enabled, disabled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE automation_conditions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    automation_id INT,
    condition_type VARCHAR(50) COMMENT 'e.g., sensor reading threshold',
    condition_value VARCHAR(255) COMMENT 'e.g., >25°C, motion detected',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (automation_id) REFERENCES automations(id)
);

CREATE TABLE logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    device_id INT,
    action VARCHAR(255) COMMENT 'e.g., turned on, motion detected',
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE permissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    device_id INT,
    permission_level VARCHAR(50) COMMENT 'e.g., full, control, view only',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (device_id) REFERENCES devices(id)
);
