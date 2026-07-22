CREATE TABLE users (
  -- Identificación
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE NOT NULL,  
  
  -- Datos básicos
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  
  -- Avatar (Estilo Micah)
  avatar_seed VARCHAR(100) DEFAULT 'default',
  avatar_background VARCHAR(6) DEFAULT 'b6e3f4', 
  avatar_background_type VARCHAR(20) DEFAULT 'solid', 
	
  -- Control de cuenta
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE,
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP
);





-- Índice para búsquedas rápidas por email
CREATE INDEX idx_users_email ON users(email);

-- Índice para búsquedas por Firebase UID
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);



CREATE TABLE user_profiles (
  -- Relación con usuario
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Datos físicos (Sección 1 del ProfileSetup)
  height_cm DECIMAL(5,2),  -- Estatura en cm (ej: 175.50)
  weight_kg DECIMAL(5,2),  -- Peso en kg (ej: 70.25)
  date_of_birth DATE,      -- Fecha de nacimiento
  gender VARCHAR(20),      -- 'male', 'female', 'other', 'prefer_not_to_say'
  
  -- Datos de asma (Sección 1 del ProfileSetup)
  asthma_type VARCHAR(50) NOT NULL,  -- 'allergic', 'non_allergic', 'mixed', 'exercise_induced'
  diagnosis_date DATE,               -- Cuándo le diagnosticaron asma
  personal_best_pef INTEGER,         -- Mejor PEF personal (ej: 500 L/min)
  
  -- Datos médicos externos (Sección 2 del ProfileSetup)
  known_allergies TEXT,              -- Lista de alergias (ej: "Polen, ácaros, gatos")
  current_medications TEXT,          -- Medicamentos actuales (ej: "Salbutamol, Montelukast")
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);






CREATE TABLE emergency_contacts (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Datos del contacto
  contact_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  relationship VARCHAR(50),  -- 'family', 'friend', 'doctor', 'other'
  is_primary BOOLEAN DEFAULT FALSE,  -- ¿Es el contacto principal?
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);





CREATE TABLE devices (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Datos del dispositivo
  device_type VARCHAR(50) NOT NULL,  -- 'smartwatch', 'spirometer'
  device_brand VARCHAR(100),         -- 'Samsung', 'MIR', 'Garmin'
  device_model VARCHAR(100),         -- 'Galaxy Watch 4', 'Smart One'
  device_mac_address VARCHAR(17) UNIQUE,  -- Dirección MAC Bluetooth (ej: "AA:BB:CC:DD:EE:FF")
  
  -- Estado
  is_active BOOLEAN DEFAULT TRUE,
  last_sync_at TIMESTAMP,  -- Última vez que sincronizó datos
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);



CREATE TABLE vital_signs (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id INTEGER REFERENCES devices(id) ON DELETE SET NULL,
  
  -- Mediciones
  spo2 INTEGER CHECK (spo2 >= 0 AND spo2 <= 100),  -- Oxigenación (%)
  heart_rate INTEGER CHECK (heart_rate > 0),        -- Ritmo cardíaco (bpm)
  sleep_hours DECIMAL(4,2) CHECK (sleep_hours >= 0 AND sleep_hours <= 24),  -- Horas de sueño
  
  -- Metadata
  measured_at TIMESTAMP NOT NULL,  -- Cuándo se tomó la medición
  created_at TIMESTAMP DEFAULT NOW()  -- Cuándo se guardó en la BD
);





CREATE TABLE spirometer_readings (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id INTEGER REFERENCES devices(id) ON DELETE SET NULL,
  
  -- Mediciones
  pef INTEGER NOT NULL CHECK (pef > 0),  -- Peak Expiratory Flow (L/min)
  fev1 DECIMAL(4,2) CHECK (fev1 > 0),    -- Forced Expiratory Volume in 1 sec (litros)
  
  -- Metadata
  measured_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);


CREATE TABLE manual_entries (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Datos manuales
  symptoms TEXT,  -- Lista de síntomas (ej: "tos, sibilancias, opresión en pecho")
  manual_pef INTEGER CHECK (manual_pef > 0),  -- PEF ingresado manualmente (si no tiene espirómetro)
  notes TEXT,  -- Notas adicionales del usuario
  
  -- Metadata
  measured_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);



CREATE TABLE predictions (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Resultado de la predicción
  risk_level VARCHAR(20) NOT NULL,  -- 'low', 'moderate', 'high'
  probability DECIMAL(5,4) CHECK (probability >= 0 AND probability <= 1),  -- 0.0000 a 1.0000
  
  -- Datos que usó el modelo para predecir
  input_data JSONB,  -- Guarda los valores que se le pasaron al modelo
  
  -- Metadata
  predicted_at TIMESTAMP DEFAULT NOW(),
  model_version VARCHAR(50)  
);



CREATE TABLE notifications (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  prediction_id INTEGER REFERENCES predictions(id) ON DELETE SET NULL,
  
  -- Contenido de la notificación
  notification_type VARCHAR(50) NOT NULL,  -- 'risk_alert', 'reminder', 'info'
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  
  -- Estado
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP DEFAULT NOW(),
  read_at TIMESTAMP
);



CREATE TABLE action_plans (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Metadata
  plan_name VARCHAR(255) DEFAULT 'Plan de Emergencia',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);


CREATE TABLE action_steps (
  -- Identificación
  id SERIAL PRIMARY KEY,
  action_plan_id INTEGER NOT NULL REFERENCES action_plans(id) ON DELETE CASCADE,
  
  -- Contenido del paso
  step_order INTEGER NOT NULL,  -- Orden: 1, 2, 3...
  step_title VARCHAR(255) NOT NULL,  -- "Usar inhalador"
  step_description TEXT,  -- "Toma 2 disparos de tu inhalador de rescate"
  is_critical BOOLEAN DEFAULT FALSE,  -- Si es paso crítico (color rojo)
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW()
);


CREATE TABLE app_settings (
  -- Identificación
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Configuraciones
  notifications_enabled BOOLEAN DEFAULT TRUE,
  reminder_frequency VARCHAR(20) DEFAULT 'daily',  -- 'daily', 'twice_daily', 'weekly'
  theme VARCHAR(20) DEFAULT 'light',  -- 'light', 'dark', 'auto'
  language VARCHAR(5) DEFAULT 'es',  -- 'es', 'en'
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

select * from users


-- Agregar campo role a la tabla users
ALTER TABLE users 
ADD COLUMN role VARCHAR(20) DEFAULT 'patient' NOT NULL;

-- Crear índice para búsquedas rápidas por rol
CREATE INDEX idx_users_role ON users(role);

-- Agregar campo para código de doctor (solo para doctores)
ALTER TABLE users 
ADD COLUMN doctor_code VARCHAR(50) UNIQUE;





CREATE TABLE doctor_patients (
  -- Identificación
  id SERIAL PRIMARY KEY,
  doctor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  patient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Metadata
  assigned_at TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Evitar duplicados (un paciente no puede estar asignado 2 veces al mismo doctor)
  UNIQUE(doctor_id, patient_id)
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_doctor_patients_doctor ON doctor_patients(doctor_id);
CREATE INDEX idx_doctor_patients_patient ON doctor_patients(patient_id);




-- Función para generar código único de doctor
CREATE OR REPLACE FUNCTION generate_doctor_code(doctor_name VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
  code VARCHAR;
  counter INTEGER := 0;
BEGIN
  -- Formato: DOC-NOMBRE-AÑO
  code := 'DOC-' || UPPER(REPLACE(doctor_name, ' ', '')) || '-' || EXTRACT(YEAR FROM NOW());
  
  -- Si ya existe, agregar número
  WHILE EXISTS (SELECT 1 FROM users WHERE doctor_code = code) LOOP
    counter := counter + 1;
    code := 'DOC-' || UPPER(REPLACE(doctor_name, ' ', '')) || '-' || EXTRACT(YEAR FROM NOW()) || '-' || counter;
  END LOOP;
  
  RETURN code;
END;
$$ LANGUAGE plpgsql;

delete user form users 