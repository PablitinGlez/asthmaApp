-- =========================================================================
-- ASTHMA PREDICTOR - ESQUEMA COMPLETO DE BASE DE DATOS PARA POSTGRESQL / SUPABASE
-- Script para recrear la base de datos estructuralmente. 
-- Ejecutar en el SQL Editor de Supabase (o cualquier cliente PostgreSQL).
-- =========================================================================

-- 1. Usuarios Principales
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    supabase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(150),
    role VARCHAR(50) DEFAULT 'patient',
    is_active BOOLEAN DEFAULT TRUE,
    avatar_seed VARCHAR(50),
    avatar_background VARCHAR(50),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Perfil General de Usuario
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    dob DATE,
    gender VARCHAR(20),
    height_cm NUMERIC,
    weight_kg NUMERIC,
    smoking_status VARCHAR(50),
    diagnosis_date DATE,
    asthma_severity VARCHAR(50),
    known_triggers TEXT,
    allergies TEXT,
    primary_physician VARCHAR(150),
    emergency_number VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Doctores (Perfiles Profesionales)
CREATE TABLE IF NOT EXISTS doctors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    doctor_code VARCHAR(20) UNIQUE,
    specialty VARCHAR(100),
    license_number VARCHAR(50) UNIQUE,
    hospital_name VARCHAR(150),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Relación Doctor - Paciente (Vinculaciones)
CREATE TABLE IF NOT EXISTS doctor_patients (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(doctor_id, patient_id)
);

-- 5. Citas Médicas
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    type VARCHAR(50) DEFAULT 'consultation',
    status VARCHAR(20) DEFAULT 'scheduled',
    notes TEXT,
    location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Dispositivos del Usuario (Ej. Espirómetros Bluetooth)
CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_type VARCHAR(100),
    device_brand VARCHAR(100),
    device_model VARCHAR(100),
    device_mac_address VARCHAR(100) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Lecturas de Espirómetro (Vitales para la App)
CREATE TABLE IF NOT EXISTS spirometer_readings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INTEGER REFERENCES devices(id) ON DELETE SET NULL,
    pef NUMERIC,
    fev1 NUMERIC,
    fvc NUMERIC,
    fev1_fvc_ratio NUMERIC,
    pef_zone VARCHAR(20),
    symptoms TEXT,
    context TEXT,
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Entradas Manuales (Diario del Paciente)
CREATE TABLE IF NOT EXISTS manual_entries (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    symptoms TEXT,
    manual_pef INTEGER,
    notes TEXT,
    measured_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Signos Vitales
CREATE TABLE IF NOT EXISTS vital_signs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    heart_rate INTEGER,
    oxygen_saturation NUMERIC,
    respiratory_rate INTEGER,
    body_temperature NUMERIC,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Perfiles Clínicos (Datos médicos crudos)
CREATE TABLE IF NOT EXISTS clinical_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    blood_type VARCHAR(10),
    chronic_conditions TEXT,
    current_medications TEXT,
    past_surgeries TEXT,
    family_history TEXT,
    vaccination_status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Planes de Acción
CREATE TABLE IF NOT EXISTS action_plans (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Pasos de los Planes de Acción
CREATE TABLE IF NOT EXISTS action_steps (
    id SERIAL PRIMARY KEY,
    action_plan_id INTEGER NOT NULL REFERENCES action_plans(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    step_title VARCHAR(255) NOT NULL,
    step_description TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Contactos de Emergencia
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    relationship VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. Ajustes de la Aplicación (Settings)
CREATE TABLE IF NOT EXISTS app_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    reminder_frequency VARCHAR(50) DEFAULT 'daily',
    theme VARCHAR(50) DEFAULT 'system',
    language VARCHAR(10) DEFAULT 'es',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. Notificaciones push/in-app
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. Predicciones (IA de Riesgo de Asma)
CREATE TABLE IF NOT EXISTS predictions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reading_id INTEGER REFERENCES spirometer_readings(id) ON DELETE CASCADE,
    risk_level VARCHAR(50),
    confidence_score NUMERIC,
    prediction_details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================================================================
-- ÍNDICES DE RENDIMIENTO ⚡
-- =========================================================================

CREATE INDEX IF NOT EXISTS idx_users_supabase_uid ON users(supabase_uid);
CREATE INDEX IF NOT EXISTS idx_doctors_code ON doctors(doctor_code);
CREATE INDEX IF NOT EXISTS idx_doctor_patients_doc ON doctor_patients(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_patients_pat ON doctor_patients(patient_id);
CREATE INDEX IF NOT EXISTS idx_spirometer_user ON spirometer_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_spirometer_date ON spirometer_readings(measured_at);
CREATE INDEX IF NOT EXISTS idx_appointments_doc ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_pat ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_predictions_user ON predictions(user_id);
