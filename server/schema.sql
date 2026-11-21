-- ============================================================================
-- FICHA PET — Esquema de Base de Datos Relacional (PostgreSQL / SQLite)
-- Soporta múltiples usuarios, perfiles, mascotas, historiales y motor Push
-- (recordatorios anticipados + repetición cada 2 días en vacunas vencidas).
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50) DEFAULT '',
    role VARCHAR(20) NOT NULL DEFAULT 'owner', -- 'owner' | 'vet'
    clinic_name VARCHAR(150) DEFAULT '',
    avatar_base64 TEXT DEFAULT '',
    theme_seed_index INTEGER DEFAULT 0,
    theme_mode VARCHAR(20) DEFAULT 'light',
    push_enabled BOOLEAN DEFAULT TRUE,
    advance_days INTEGER DEFAULT 14,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pets (
    id BIGINT PRIMARY KEY,
    owner_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(20) NOT NULL,          -- 'dog' | 'cat'
    birthday VARCHAR(20) DEFAULT '',    -- YYYY-MM-DD
    weight VARCHAR(20) DEFAULT '',
    gender VARCHAR(20) DEFAULT '',      -- 'male' | 'female'
    breed VARCHAR(120) DEFAULT '',
    chip VARCHAR(10) DEFAULT 'no',      -- 'yes' | 'no'
    last_vaccine_date VARCHAR(20) DEFAULT '',
    next_vaccine_date VARCHAR(20) DEFAULT '',
    vaccine_type VARCHAR(150) DEFAULT '',
    last_deworming_date VARCHAR(20) DEFAULT '',
    next_deworming_date VARCHAR(20) DEFAULT '',
    deworming_product VARCHAR(150) DEFAULT '',
    medical_history_json TEXT DEFAULT '[]',
    weight_history_json TEXT DEFAULT '[]',
    files_json TEXT DEFAULT '{}',
    emergency_contact_json TEXT DEFAULT '{}',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_next_vaccine ON pets(next_vaccine_date);
CREATE INDEX IF NOT EXISTS idx_pets_next_deworming ON pets(next_deworming_date);

-- Vínculo bidireccional Veterinario <-> Mascota (mediante escaneo de QR clínico)
CREATE TABLE IF NOT EXISTS vet_patients (
    vet_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id BIGINT NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (vet_id, pet_id)
);

CREATE TABLE IF NOT EXISTS push_devices (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,      -- 'android' | 'ios' | 'web'
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_token)
);

-- Registro de envíos Push para controlar:
-- 1) Recordatorios con anticipación (30, 14, 7, 3, 1, 0 días antes)
-- 2) Repetición cada 2 días (48 h) cuando la vacuna o desparasitación está vencida
CREATE TABLE IF NOT EXISTS push_dispatch_log (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id BIGINT NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    event_type VARCHAR(40) NOT NULL,    -- 'Vacuna' | 'Desparasitación'
    due_date VARCHAR(20) NOT NULL,      -- YYYY-MM-DD
    is_overdue BOOLEAN NOT NULL DEFAULT FALSE,
    last_sent_date VARCHAR(20) NOT NULL, -- YYYY-MM-DD
    UNIQUE(user_id, pet_id, event_type, due_date)
);
